// lib/features/auth/login_page.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../router.dart'; // RouteNames + TakeoverArgs

class TakeoverArgs {
  final String phoneNum;
  final int userId;
  const TakeoverArgs({required this.phoneNum, required this.userId});
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController(); // 6-digit PIN
  final _formKey = GlobalKey<FormState>();

  String errorMessage = '';
  bool _isLoading = false;

  // Secure storage for sensitive session data
  static const _secure = secureStorage;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || pin.length != 6) {
      setState(() => errorMessage = 'Please enter a valid phone number and 6-digit PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });
    
    bool navigated = false;

    Future<String> _ensureDeviceId() async {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('device_id');
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString('device_id', id);
        debugPrint('[login] Generated new device_id: $id');
      } else {
        debugPrint('[login] Existing device_id: $id');
      }
      return id;
    }

    Future<Map<String, String>> _getDeviceInfo() async {
      final plugin = DeviceInfoPlugin();
      String deviceName = 'Unknown';
      String platform = Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Other');

      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        deviceName = info.name ?? info.modelName ?? info.model ?? 'iPhone';
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final brand = info.brand ?? '';
        final model = info.model ?? info.device ?? '';
        deviceName = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
        if (deviceName.isEmpty) deviceName = 'Android Device';
      }

      debugPrint('[login] Device info: $deviceName ($platform)');
      return {
        'deviceName': deviceName,
        'platform': platform,
      };
    }

    Future<bool> _registerDevice({
      required int userId,
      required String deviceId,
      required String deviceName,
      required String platform,
      required String token,
    }) async {
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/users/registerDevice');
        debugPrint('[login] -> POST $url');
        debugPrint('[login] body registerDevice: {userId:$userId, deviceId:$deviceId, name:$deviceName, platform:$platform}');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'deviceId': deviceId,
            'deviceName': deviceName,
            'platform': platform,
            'registeredAt': DateTime.now().toIso8601String(),
          }),
        );

        debugPrint('[login] registerDevice status: ${response.statusCode} body: ${response.body}');
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('[login] registerDevice exception: $e');
        return false;
      }
    }

    // --- Email MFA helper ---
    Future<bool> _performEmailMfa(String email) async {
      if (email.isEmpty) {
        // If no email is available, skip MFA gracefully
        return true;
      }

      // 1) Ask backend to send OTP to the given email
      try {
        final sendUrl = Uri.parse('${ApiConfig.baseUrl}/otp/send');
        final sendRes = await http.post(
          sendUrl,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        );

        debugPrint('[login][mfa] send OTP status: ${sendRes.statusCode} body: ${sendRes.body}');

        if (sendRes.statusCode != 200) {
          try {
            final data = jsonDecode(sendRes.body) as Map<String, dynamic>;
            final msg = (data['message'] ?? 'Failed to send verification email.').toString();
            if (mounted) {
              setState(() {
                errorMessage = msg;
              });
            }
          } catch (_) {
            if (mounted) {
              setState(() {
                errorMessage = 'Failed to send verification email.';
              });
            }
          }
          return false;
        }
      } catch (e) {
        debugPrint('[login][mfa] send OTP exception: $e');
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to send verification email. Please try again.';
          });
        }
        return false;
      }

      // 2) Show a dialog for user to input the OTP and verify via backend
      String otp = '';
      String? localError;
      bool verifying = false;

      final bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                title: const Text('Verify your email'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('We\'ve sent a verification code to:\n$email'),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'OTP code',
                        counterText: '',
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          otp = val.trim();
                          localError = null;
                        });
                      },
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        localError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: verifying
                        ? null
                        : () {
                            Navigator.of(ctx).pop(false);
                          },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: (!verifying && otp.isNotEmpty)
                        ? () async {
                            setStateDialog(() {
                              verifying = true;
                              localError = null;
                            });

                            try {
                              final verifyUrl = Uri.parse('${ApiConfig.baseUrl}/otp/verify');
                              final verifyRes = await http.post(
                                verifyUrl,
                                headers: {
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'email': email,
                                  'otp': otp,
                                }),
                              );

                              debugPrint('[login][mfa] verify OTP status: ${verifyRes.statusCode} body: ${verifyRes.body}');

                              // Treat any 200 as success, regardless of body format
                              if (verifyRes.statusCode == 200) {
                                Navigator.of(ctx).pop(true);
                                return;
                              }

                              // Non-200: try to extract a meaningful error message
                              String backendMsg = 'Invalid code. Please try again.';
                              try {
                                final decoded = jsonDecode(verifyRes.body);
                                if (decoded is Map<String, dynamic>) {
                                  backendMsg = (decoded['message'] ?? backendMsg).toString();
                                } else if (decoded is String) {
                                  backendMsg = decoded;
                                }
                              } catch (_) {
                                if (verifyRes.body.isNotEmpty) {
                                  backendMsg = verifyRes.body;
                                }
                              }

                              setStateDialog(() {
                                verifying = false;
                                localError = backendMsg;
                              });
                            } catch (e) {
                              debugPrint('[login][mfa] verify OTP exception: $e');
                              setStateDialog(() {
                                verifying = false;
                                localError = 'Network error. Please try again.';
                              });
                            }
                          }
                        : null,
                    child: verifying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == true) {
        return true;
      }

      if (mounted) {
        setState(() {
          if (errorMessage.isEmpty) {
            errorMessage = 'Email verification was cancelled or failed.';
          }
        });
      }
      return false;
    }

    try {
      // 1) login
      final loginUrl = Uri.parse('${ApiConfig.baseUrl}/users/login');
      debugPrint('[login] -> POST $loginUrl');
      final loginRes = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNum': phone,
          'account_pin_num': pin,
        }),
      );
      debugPrint('[login] login status: ${loginRes.statusCode} body: ${loginRes.body}');

      // Decode JSON once so we can reuse it for both success and error cases
      Map<String, dynamic> loginData = {};
      try {
        loginData = jsonDecode(loginRes.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[login] JSON decode error: $e');
      }

      // If backend returned non-200, show backend message instead of generic error
      if (loginRes.statusCode != 200) {
        final backendMsg =
            (loginData['message'] ?? 'Login failed. Please try again.').toString();

        if (!mounted) return;
        setState(() {
          errorMessage = backendMsg;
        });
        return;
      }

      final bool loggedInOK = loginData['success'] == true;
      final token = (loginData['token'] ?? '').toString();
      final userObj = (loginData['user'] ?? {}) as Map<String, dynamic>;

      final int backendUserId = (userObj['user_id'] is int)
          ? userObj['user_id']
          : int.tryParse('${userObj['user_id']}') ?? 0;

      final backendPhone = (userObj['phoneNum'] ?? phone).toString();
      final backendEmail = (userObj['email'] ?? '').toString();
      final backendName = (userObj['username'] ?? '').toString();
      final backendStatus = (userObj['user_status'] ?? '').toString();

      debugPrint('[login] loggedInOK: $loggedInOK');
      debugPrint('[login] backendUserId: $backendUserId');
      debugPrint('[login] token: $token');
      debugPrint('[login] user_status: $backendStatus');

      if (!loggedInOK || token.isEmpty || backendUserId == 0) {
        if (!mounted) return;
        setState(() {
          errorMessage = loginData['message'] ?? 'Login failed. Please try again.';
        });
        return;
      }

      // 2) persist sensitive session to secure storage
      await _secure.write(key: 'token', value: token);
      await _secure.write(key: 'user_id', value: '$backendUserId');
      await _secure.write(key: 'user_phone', value: backendPhone);
      await _secure.write(key: 'user_email', value: backendEmail);
      await _secure.write(key: 'username', value: backendName);
      await _secure.write(key: 'user_status', value: backendStatus);

      // 🔐 Also persist creds for AppLockGate silent login (biometric unlock):
      await _secure.write(key: 'phone_number', value: phone);
      await _secure.write(key: 'password', value: pin); // your PIN-as-password

      // 3) Decide biometric opt-in routing BEFORE device checks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', '$backendUserId');
      
      final bool? localBiometric = prefs.getBool('biometric_enabled');
      final bool? serverBiometric =
          (userObj['biometric_enabled'] is bool) ? userObj['biometric_enabled'] as bool : null;

      // If server provided, mirror to local for consistency
      if (serverBiometric != null) {
        await prefs.setBool('biometric_enabled', serverBiometric);
      }

      final hasChosenBiometric = (serverBiometric != null) || (localBiometric != null);
      if (!hasChosenBiometric) {
        // Keep the session saved, then go to opt-in
        if (!mounted) return;
        context.goNamed(RouteNames.enableBiometric);
        navigated = true;
        return;
      }

      // 4) Device trust checks (same as before)
      final localDeviceId = await _ensureDeviceId();

      // If user chose NOT to enable biometric, we still go through device trust & home
      final checkDeviceUrl = Uri.parse('${ApiConfig.baseUrl}/users/checkDevice');
      debugPrint('[login] -> POST $checkDeviceUrl with phoneNum=$phone deviceId=$localDeviceId');

      final checkDeviceRes = await http.post(
        checkDeviceUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phoneNum': phone,
          'deviceId': localDeviceId,
        }),
      );

      debugPrint('[login] checkDevice status: ${checkDeviceRes.statusCode} body: ${checkDeviceRes.body}');

      // A) trusted
      if (checkDeviceRes.statusCode == 200) {
        // Perform email MFA before finalizing login
        final mfaOk = await _performEmailMfa(backendEmail);
        if (!mfaOk) {
          // _performEmailMfa already set a user-facing error message
          return;
        }

        await prefs.setBool('is_logged_in', true);
        await prefs.setString('device_id', localDeviceId);

        if (!mounted) return;
        context.goNamed(RouteNames.home);
        navigated = true;
        return;
      }

      // B) need register (404)
      if (checkDeviceRes.statusCode == 404) {
        final info = await _getDeviceInfo();
        final registeredOK = await _registerDevice(
          userId: backendUserId,
          deviceId: localDeviceId,
          deviceName: info['deviceName']!,
          platform: info['platform']!,
          token: token,
        );

        if (!registeredOK) {
          if (!mounted) return;
          setState(() {
            errorMessage = 'Device registration failed. Please try again.';
          });
          return;
        }

        // After registering this new device, perform email MFA
        final mfaOk = await _performEmailMfa(backendEmail);
        if (!mfaOk) {
          // _performEmailMfa already set a user-facing error message
          return;
        }

        await prefs.setBool('is_logged_in', true);
        await prefs.setString('device_id', localDeviceId);

        if (!mounted) return;
        context.goNamed(RouteNames.home);
        navigated = true;
        return;
      }

      // C) takeover (401)
      if (checkDeviceRes.statusCode == 401) {
        await prefs.setBool('is_logged_in', false);
        await prefs.setString('device_id', localDeviceId);

        if (!mounted) return;
        context.pushNamed(
          RouteNames.takeover,
          extra: TakeoverArgs(phoneNum: phone, userId: backendUserId),
        );
        navigated = true;
        return;
      }

      // D) user not found (400) — show backend message
      if (checkDeviceRes.statusCode == 400) {
        final data = jsonDecode(checkDeviceRes.body);
        final backendMsg = (data['message'] ?? 'Something went wrong.').toString();

        if (!mounted) return;
        setState(() {
          errorMessage = backendMsg;
        });
        return;
      }

      // E) anything else — show backend message if available
      try {
        final data = jsonDecode(checkDeviceRes.body);
        final backendMsg = (data['message'] ?? 'Unexpected error.').toString();

        if (!mounted) return;
        setState(() {
          errorMessage = backendMsg;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Unexpected response (${checkDeviceRes.statusCode}).';
        });
      }
      return;
    } catch (e) {
      debugPrint('[login] CATCH exception: $e');
      if (!navigated && mounted) {
        setState(() {
          errorMessage = 'Connection error. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forgot PIN'),
        content: const Text(

          
          'Please contact support or reset your PIN from the main app (to be implemented).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _goRegister() {
    context.pushNamed(RouteNames.contactInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // gradient bg
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor,
                    accentColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            top: true,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewInsets = MediaQuery.of(context).viewInsets;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: _buildLoginContent(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'NexPay',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
            const Spacer(),
            _HeaderIcon(icon: Icons.help_outline_rounded, onTap: () {}),
          ],
        ),
        const SizedBox(height: 14),

        _GlassHero(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Welcome back! Log in to continue.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Login',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Text(
                  'Use your phone and 6-digit PIN.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 18),

                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: primaryColor,
                      selectionColor: primaryColor.withOpacity(.20),
                      selectionHandleColor: primaryColor,
                    ),
                    colorScheme: Theme.of(context).colorScheme.copyWith(primary: primaryColor),
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    cursorColor: primaryColor,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 0123456789',
                      prefixIcon: const Icon(Icons.phone_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF3F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E9F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E9F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1.6),
                      ),
                    ),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PIN',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),

                _PinBoxField(
                  controller: _pinController,
                  length: 6,
                  enabled: !_isLoading,
                ),

                if (_pinController.text.isNotEmpty == false) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tap the boxes and enter your 6-digit PIN',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPinDialog,
                    child: Text('Forgot PIN?', style: TextStyle(color: accentColor)),
                  ),
                ),

                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),
                ],

                const SizedBox(height: 10),

                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        Center(
          child: TextButton(
            onPressed: _goRegister,
            child: Text(
              'New here? Click to register',
              style: TextStyle(
                color: Colors.white.withOpacity(.95),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(.85),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------- tiny UI helpers ---------- */

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(.28)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _GlassHero extends StatelessWidget {
  final Widget child;
  const _GlassHero({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PinBoxField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const _PinBoxField({
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<_PinBoxField> createState() => _PinBoxFieldState();
}

class _PinBoxFieldState extends State<_PinBoxField> {
  late FocusNode _focus;
  late List<String> _digits;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _digits = List<String>.filled(widget.length, '');
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    final raw = widget.controller.text;
    final txt = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (txt != raw) {
      widget.controller.value = TextEditingValue(
        text: txt,
        selection: TextSelection.collapsed(offset: txt.length),
      );
      return;
    }

    final chars = txt.characters.toList();
    for (var i = 0; i < widget.length; i++) {
      _digits[i] = i < chars.length ? chars[i] : '';
    }
    setState(() {});

    widget.onChanged?.call(txt);
    if (txt.isNotEmpty) HapticFeedback.selectionClick();
    if (txt.length == widget.length) widget.onCompleted?.call(txt);
  }

  void _focusInput() {
    if (!widget.enabled) return;
    FocusScope.of(context).requestFocus(_focus);
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final currentLen = widget.controller.text.length;
    final focusIndex = currentLen.clamp(0, widget.length - 1);

    final boxes = List.generate(widget.length, (i) {
      final hasDigit = _digits[i].isNotEmpty;
      final isFocused = _focus.hasFocus && (i == focusIndex) && !hasDigit;

      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused
                  ? primaryColor
                  : (hasDigit ? primaryColor.withOpacity(.65) : const Color(0xFFE6EAF0)),
              width: isFocused ? 1.8 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: hasDigit
              ? const Text(
                  '•',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                )
              : const SizedBox.shrink(),
        ),
      );
    });

    return GestureDetector(
      onTap: _focusInput,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AbsorbPointer(child: Row(children: boxes)),
          Opacity(
            opacity: 0.01,
            child: TextField(
              focusNode: _focus,
              controller: widget.controller,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: widget.length,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ],
      ),
    );
  }
}