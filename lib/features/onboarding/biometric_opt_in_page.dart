// lib/features/onboarding/biometric_opt_in_page.dart
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../router.dart';
import '../../core/constants/api_config.dart'; // <-- ensure you have ApiConfig.baseUrl

class BiometricOptInPage extends StatefulWidget {
  const BiometricOptInPage({super.key});

  @override
  State<BiometricOptInPage> createState() => _BiometricOptInPageState();
}

class _BiometricOptInPageState extends State<BiometricOptInPage>
    with TickerProviderStateMixin {
  final _auth = LocalAuthentication();
  final _secure = const FlutterSecureStorage();

  bool _deviceSupported = false;
  bool _hasEnrolled = false;
  bool _busy = false;
  String? _error;

  late final AnimationController _fadeScale;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();

    _fadeScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _fadeScale, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _fadeScale, curve: Curves.easeOutBack),
    );

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initBio();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeScale.forward();
    });
  }

  @override
  void dispose() {
    _fadeScale.dispose();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _initBio() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    final types = await _auth.getAvailableBiometrics();

    if (!mounted) return;
    setState(() {
      _deviceSupported = supported;
      _hasEnrolled = canCheck && types.isNotEmpty;
    });
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      if (!_deviceSupported) {
        setState(() => _error = "Biometric is not supported on this device.");
        return;
      }
      if (!_hasEnrolled) {
        setState(() =>
            _error = "No biometric enrolled. Please add Face/Touch ID first.");
        return;
      }

      final success = await _auth.authenticate(
        localizedReason:
            'Enable biometric to quickly unlock your NexPay account.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (!success) {
        setState(() => _error = "Biometric authentication was cancelled.");
        return;
      }

      // Update server: biometric_enable = true
      final ok = await _updateBiometricSetting(true);
      if (!ok) return; // _error already set by helper

      // Persist local flag for quick checks in app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', true);

      if (!mounted) return;
      context.goNamed(RouteNames.registerSuccess);
    } catch (_) {
      setState(() => _error = "Couldn’t enable biometric. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    try {
      // Update server: biometric_enable = false
      final ok = await _updateBiometricSetting(false);
      if (!ok) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);

      if (!mounted) return;
      context.goNamed(RouteNames.registerSuccess);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// PUT /api/users/{user_id}/biometric  { "biometric_enable": <bool> }
  Future<bool> _updateBiometricSetting(bool enabled) async {
    try {
      // try secure storage first
      String? userId = await _secure.read(key: 'user_id');
      String? token = await _secure.read(key: 'auth_token');

      // fallback to SharedPreferences if missing
      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');
      }

      if (userId == null || userId.isEmpty) {
        setState(() => _error = "Missing user ID. Please sign in again.");
        return false;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId/biometric');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({"biometric_enable": enabled});

      final resp = await http
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Example response:
        // { "message":"Biometric setting updated successfully.", "biometric_enable": false, "success": true }
        try {
          final json = jsonDecode(resp.body);
          final serverVal = json is Map ? json['biometric_enable'] : null;
          if (serverVal is bool) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('biometric_enabled', serverVal);
          }
        } catch (_) {
          // ignore parse errors; local value already set by caller
        }
        return true;
      } else {
        // Surface server message when possible
        String msg = enabled
            ? "Failed to enable biometric."
            : "Failed to update biometric setting.";
        try {
          final js = jsonDecode(resp.body);
          if (js is Map && js['message'] is String) {
            msg = js['message'];
          }
        } catch (_) {}
        setState(() => _error = msg);
        return false;
      }
    } catch (e) {
      setState(() => _error = "Network error. Please try again.");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.white70;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 1.15,
                    colors: [
                      primaryColor.withOpacity(0.95),
                      Colors.black.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
            ),

            // Center content
            Align(
              alignment: Alignment.center,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroLock(),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(r),
                          child: const Text(
                            'Enable Biometric?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Use Face/Touch ID to quickly unlock your NexPay account.",
                          style: TextStyle(color: subtle),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InfoRow(
                                icon: Icons.check_circle_outline,
                                text: "Faster and more convenient sign-in.",
                              ),
                              const SizedBox(height: 10),
                              const _InfoRow(
                                icon: Icons.lock_outline_rounded,
                                text: "Your biometric data stays on device.",
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.phonelink_lock_outlined,
                                text: _deviceSupported
                                    ? (_hasEnrolled
                                        ? "Biometric available and enrolled."
                                        : "Biometric available but not enrolled.")
                                    : "Biometric not supported on this device.",
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _ErrorBanner(text: _error!),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed bottom buttons
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _skip,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.35)),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Not Now",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _enableBiometric,
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          color: _busy ? Colors.black54 : Colors.black,
                        ),
                        label: Text(
                          "Enable",
                          style: TextStyle(
                            color: _busy ? Colors.black54 : Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _busy ? accentColor.withOpacity(0.5) : accentColor,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Busy overlay
            if (_busy)
              _BlurOverlay(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: math.min(360, width - 48)),
                  child: _FrostedLoading(
                    title: "Please wait…",
                    subtitle: "We’re checking your biometrics",
                    spinner: _ArcSpinner(controller: _spin, size: 42),
                    icon: Icons.lock_rounded,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Animated fingerprint ---
class _HeroLock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: 34,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withOpacity(0.28),
                accentColor.withOpacity(0.12),
                accentColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            border: Border.all(color: accentColor.withOpacity(0.55), width: 3),
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            color: Colors.white,
            size: 46,
          ),
        ),
      ],
    );
  }
}

// --- Frosted blur overlay ---
class _BlurOverlay extends StatelessWidget {
  final Widget child;
  const _BlurOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        alignment: Alignment.center,
        color: Colors.black.withOpacity(0.35),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- Frosted card with custom spinner ---
class _FrostedLoading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget spinner;
  final IconData icon;

  const _FrostedLoading({
    required this.title,
    required this.subtitle,
    required this.spinner,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          spinner,
        ],
      ),
    );
  }
}

// --- Spinner animation ---
class _ArcSpinner extends StatelessWidget {
  final AnimationController controller;
  final double size;
  const _ArcSpinner({required this.controller, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _ArcSpinnerPainter(progress: controller.value),
          );
        },
      ),
    );
  }
}

class _ArcSpinnerPainter extends CustomPainter {
  final double progress;
  _ArcSpinnerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.0;
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [accentColor, Colors.white],
        stops: const [0.1, 0.9],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2),
      0,
      math.pi * 2,
      false,
      base,
    );

    final start = progress * math.pi * 2;
    const sweepAngle = math.pi * 1.22;
    canvas.drawArc(
      Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2),
      start,
      sweepAngle,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcSpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// --- Supporting UI elements ---
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, height: 1.25),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }
}