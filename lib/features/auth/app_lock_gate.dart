import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart'; 

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _la = LocalAuthentication();

  static const _secure = secureStorage;

  bool _biometricEnabled = false;
  bool _checking = true;
  bool _unlocked = false;

  bool _authInProgress = false;
  bool _suppressAutoOnResume = false;
  bool _navigatingToLogin = false;
  String? _lockError;

  DateTime _lastAuthEnd = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cooldown = Duration(milliseconds: 1200);

  bool get _cooldownActive => DateTime.now().difference(_lastAuthEnd) < _cooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _la.stopAuthentication();
    super.dispose();
  }

  Future<void> _boot() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    final shouldUseBiometric = enabled && isLoggedIn;

    setState(() => _biometricEnabled = shouldUseBiometric);

    if (!shouldUseBiometric) {
      setState(() {
        _unlocked = true;
        _checking = false;
      });
      return;
    }

    await _authenticate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_biometricEnabled) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _la.stopAuthentication();
    }

    if (state == AppLifecycleState.resumed &&
        !_unlocked &&
        !_authInProgress &&
        !_checking &&
        !_cooldownActive &&
        !_suppressAutoOnResume) {
      _authenticate();
    }
  }

  Future<void> _forceUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    if (!mounted) return;
    setState(() {
      _unlocked = true;
      _checking = false;
      _lockError = null;
    });
  }

  Future<void> _authenticate() async {
    if (_authInProgress || _cooldownActive) return;

    _authInProgress = true;
    if (!mounted) return;
    setState(() {
      _checking = true;
      _lockError = null;
      _suppressAutoOnResume = false;
    });

    try {
      final canCheck = await _la.canCheckBiometrics || await _la.isDeviceSupported();
      if (!canCheck) throw Exception('Biometrics not available');

      final ok = await _la.authenticate(
        localizedReason: 'Unlock to access NexPay',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!ok) {
        if (!mounted) return;
        setState(() {
          _unlocked = false;
          _checking = false;
          _lockError = 'Authentication cancelled';
        });
        return;
      }

      if (await _tryDeviceCheckWithExistingToken()) {
        if (!mounted) return;
        setState(() {
          _unlocked = true;
          _checking = false;
        });
        return;
      }

      final refreshed = await _refreshSessionLikeLogin();

      if (!mounted) return;

      if (refreshed) {
        setState(() {
          _unlocked = true;
          _checking = false;
        });
      } else {
        await _forceUnlock();
        _suppressAutoOnResume = true;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _unlocked = false;
        _checking = false;
        _lockError = 'Unlock failed';
        _suppressAutoOnResume = true;
      });
    } finally {
      _authInProgress = false;
      _lastAuthEnd = DateTime.now();
    }
  }

  Future<bool> _tryDeviceCheckWithExistingToken() async {
    final token = await _secure.read(key: 'token');
    final phone = await _secure.read(key: 'phone_number') ??
        await _secure.read(key: 'user_phone');

    if ((token ?? '').isEmpty || (phone ?? '').isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _ensureDeviceId(prefs);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/checkDevice'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'phoneNum': phone, 'deviceId': deviceId}),
      );
      if (res.statusCode == 200) {
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('device_id', deviceId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _refreshSessionLikeLogin() async {
    final phone = await _secure.read(key: 'phone_number') ??
        await _secure.read(key: 'user_phone');
    final password = await _secure.read(key: 'password');
    final pin = await _secure.read(key: 'account_pin_num') ??
        await _secure.read(key: 'pin');

    if ((phone ?? '').isEmpty) return false;

    if ((password ?? '').isNotEmpty) {
      final data = await _loginWithPassword(phone!, password!);
      if (data != null) {
        await _persistSecureSession(data, phone);
        return await _postLoginDeviceFlow(phone, data.token, data.userId);
      }
    }

    if ((pin ?? '').isEmpty) return false;
    final data = await _loginWithPin(phone!, pin!);
    if (data == null) return false;

    await _persistSecureSession(data, phone);
    return await _postLoginDeviceFlow(phone, data.token, data.userId);
  }

  Future<_LoginResult?> _loginWithPassword(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNum': phone, 'password': password}),
      );
      if (res.statusCode != 200) return null;
      return _parseLoginResponse(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  Future<_LoginResult?> _loginWithPin(String phone, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNum': phone, 'account_pin_num': pin}),
      );
      if (res.statusCode != 200) return null;
      return _parseLoginResponse(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  _LoginResult? _parseLoginResponse(dynamic js) {
    if (js is! Map) return null;
    final token = (js['token'] ?? '').toString();
    if (token.isEmpty) return null;
    final user = js['user'] ?? {};
    final userId = int.tryParse((user['user_id'] ?? js['user_id'] ?? '0').toString()) ?? 0;
    return _LoginResult(
      token: token,
      userId: userId,
      email: user['email'] ?? '',
      name: user['user_name'] ?? '',
      status: user['user_status'] ?? '',
    );
  }

  Future<void> _persistSecureSession(_LoginResult data, String phone) async {
    await _secure.write(key: 'token', value: data.token);
    await _secure.write(key: 'user_id', value: '${data.userId}');
    await _secure.write(key: 'user_phone', value: phone);
    await _secure.write(key: 'user_email', value: data.email);
    await _secure.write(key: 'user_name', value: data.name);
    await _secure.write(key: 'user_status', value: data.status);
  }

  Future<bool> _postLoginDeviceFlow(String phone, String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _ensureDeviceId(prefs);

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/users/checkDevice'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'phoneNum': phone, 'deviceId': deviceId}),
    );

    if (res.statusCode == 200) {
      await prefs.setBool('is_logged_in', true);
      return true;
    }
    return false;
  }

  Future<String> _ensureDeviceId(SharedPreferences prefs) async {
    var id = prefs.getString('device_id');
    id ??= const Uuid().v4();
    await prefs.setString('device_id', id);
    return id;
  }

  Future<void> _purgeSessionExceptDevice() async {
    // Preserve important prefs
    final prefs = await SharedPreferences.getInstance();
    final preservedDeviceId = prefs.getString('device_id');
    final preservedBiometric = prefs.getBool('biometric_enabled');

    // Clear all in FlutterSecureStorage (tokens, user details, passwords, pins, etc.)
    try {
      await _secure.deleteAll();
    } catch (_) {}

    // Reset SharedPreferences fully, then restore preserved values
    await prefs.clear();
    if (preservedDeviceId != null) {
      await prefs.setString('device_id', preservedDeviceId);
    }
    if (preservedBiometric != null) {
      await prefs.setBool('biometric_enabled', preservedBiometric);
    }

    // Explicitly ensure logged-out flag is set
    await prefs.setBool('is_logged_in', false);
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // If lock is disabled, just render the app
    if (!_biometricEnabled) return widget.child;

    // Always keep the app in the tree so navigation can occur
    return Stack(
      children: [
        // Keep app visible; block touches while checking/locked
        IgnorePointer(
          ignoring: _checking || !_unlocked,
          child: widget.child,
        ),

        // Checking overlay (interactive)
        if (_checking)
          const Positioned.fill(
            child: Scaffold(
              backgroundColor: primaryColor,
              body: _VerifyingCard(),
            ),
          ),

        // Locked overlay (interactive, no AbsorbPointer)
        if (!_checking && !_unlocked)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: primaryColor,
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: _GlassPanel(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.12),
                                border: Border.all(color: accentColor.withOpacity(0.45), width: 1.6),
                              ),
                              child: const Icon(Icons.shield_rounded, size: 44, color: accentColor),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "NexPay Security Lock",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Your session is protected. Continue to login to access your account.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                height: 1.3,
                              ),
                            ),
                            if (_lockError != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.redAccent.withOpacity(0.28)),
                                ),
                                child: Text(
                                  _lockError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _navigatingToLogin
                                    ? null
                                    : () async {
                                        setState(() => _navigatingToLogin = true);
                                        _la.stopAuthentication();
                                        setState(() {
                                          _biometricEnabled = false;
                                          _suppressAutoOnResume = true;
                                          _unlocked = true;
                                          _checking = false;
                                          _lockError = null;
                                        });
                                        await _purgeSessionExceptDevice();
                                        final ctx = rootNavigatorKey.currentContext;
                                        if (ctx != null) {
                                          ctx.goNamed(RouteNames.login);
                                        }
                                      },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
                                  child: _navigatingToLogin
                                      ? Row(
                                          key: const ValueKey('loading'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2.4),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Opening login…',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          key: const ValueKey('idle'),
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.phone_iphone_rounded),
                                            SizedBox(width: 10),
                                            Text(
                                              'Login with phone number',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "We’ll preserve your device ID and security preferences.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoginResult {
  final String token;
  final int userId;
  final String email;
  final String name;
  final String status;
  _LoginResult({
    required this.token,
    required this.userId,
    required this.email,
    required this.name,
    required this.status,
  });
}

// Glass panel widget for frosted glass effect
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassPanel({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _VerifyingCard extends StatelessWidget {
  const _VerifyingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: _GlassPanel(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_rounded, color: Colors.white, size: 36),
              SizedBox(height: 10),
              Text(
                "Verifying security…",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Please wait while we confirm your identity",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
