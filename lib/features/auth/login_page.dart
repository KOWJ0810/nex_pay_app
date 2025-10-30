import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _demoPhone = '0123456789';
  static const String _demoPin = '123456';

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

    bool loginSuccess = false; // we'll flip this once we navigate

    Future<String> _ensureDeviceId() async {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('device_id');
      if (id == null || id.isEmpty) {
        id = const Uuid().v4();
        await prefs.setString('device_id', id);
        print('[login] Generated new device_id: $id');
      } else {
        print('[login] Existing device_id: $id');
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

      print('[login] Device info: $deviceName ($platform)');
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
      required String token, // NEW
    }) async {
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/users/registerDevice');
        print('[login] -> POST $url');
        print('[login] body registerDevice: {userId:$userId, deviceId:$deviceId, name:$deviceName, platform:$platform}');

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // <-- JWT
          },
          body: jsonEncode({
            'userId': userId,
            'deviceId': deviceId,
            'deviceName': deviceName,
            'platform': platform,
            'registeredAt': DateTime.now().toIso8601String(),
          }),
        );

        print('[login] registerDevice status: ${response.statusCode} body: ${response.body}');
        return response.statusCode == 200;
      } catch (e) {
        print('[login] registerDevice exception: $e');
        return false;
      }
    }

    try {
      // 1. login -> now returns token + user object
      final loginUrl = Uri.parse('${ApiConfig.baseUrl}/users/login');
      print('[login] -> POST $loginUrl');
      final loginRes = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNum': phone,
          'account_pin_num': pin,
        }),
      );
      print('[login] login status: ${loginRes.statusCode} body: ${loginRes.body}');

      if (loginRes.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Server error (${loginRes.statusCode}). Please try again later.';
        });
        return;
      }

      final loginData = jsonDecode(loginRes.body);

      // expected:
      // {
      //   "message": "Login successful.",
      //   "user": {
      //     "user_status": "Active",
      //     "email": "kennephooi@gmail.com",
      //     "user_name": "ROWAN SEBASTIAN",
      //     "user_id": 1,
      //     "phoneNum": "0109220239"
      //   },
      //   "success": true,
      //   "token": "eyJh..."
      // }

      final bool loggedInOK = loginData['success'] == true;
      final token = loginData['token']?.toString() ?? '';
      final userObj = loginData['user'] ?? {};

      final int backendUserId = (userObj['user_id'] is int)
          ? userObj['user_id']
          : int.tryParse('${userObj['user_id']}') ?? 0;

      final backendPhone = userObj['phoneNum']?.toString() ?? phone;
      final backendEmail = userObj['email']?.toString() ?? '';
      final backendName = userObj['user_name']?.toString() ?? '';
      final backendStatus = userObj['user_status']?.toString() ?? '';

      print('[login] loggedInOK: $loggedInOK');
      print('[login] backendUserId: $backendUserId');
      print('[login] token: $token');
      print('[login] user_status: $backendStatus');

      if (!loggedInOK || token.isEmpty || backendUserId == 0) {
        if (!mounted) return;
        setState(() {
          errorMessage = loginData['message'] ?? 'Login failed. Please try again.';
        });
        return;
      }

      // save what we can already (token + user profile info)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_phone', backendPhone);
      await prefs.setString('user_email', backendEmail);
      await prefs.setString('user_name', backendName);
      await prefs.setString('user_status', backendStatus);
      await prefs.setInt('user_id', backendUserId);

      // 2. ensure local deviceId
      final localDeviceId = await _ensureDeviceId();

      // 3. checkDevice now should include Authorization header as well
      final checkDeviceUrl = Uri.parse('${ApiConfig.baseUrl}/users/checkDevice');
      print('[login] -> POST $checkDeviceUrl with phoneNum=$phone deviceId=$localDeviceId');

      final checkDeviceRes = await http.post(
        checkDeviceUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // send token here
        },
        body: jsonEncode({
          'phoneNum': phone,
          'deviceId': localDeviceId,
        }),
      );

      print('[login] checkDevice status: ${checkDeviceRes.statusCode} body: ${checkDeviceRes.body}');

      // CASE A: already trusted on THIS device
      if (checkDeviceRes.statusCode == 200) {
        final deviceData = jsonDecode(checkDeviceRes.body);
        print('[login] deviceData: $deviceData');

        if (deviceData['deviceStatus'] == 'trusted') {
          print('[login] Device is trusted -> go Dashboard');

          await prefs.setBool('is_logged_in', true);
          await prefs.setString('device_id', localDeviceId);

          loginSuccess = true;
          if (!mounted) return;
          context.goNamed(RouteNames.home);
          return;
        } else {
          if (!mounted) return;
          setState(() {
            errorMessage = 'Unexpected device status: ${deviceData['deviceStatus']}.';
          });
          return;
        }
      }

      // CASE B: device not registered yet -> we must register (404 from backend)
      if (checkDeviceRes.statusCode == 404) {
        final checkBody = jsonDecode(checkDeviceRes.body);
        print('[login] 404 body: $checkBody');

        final int userIdFromCheck = (checkBody['userId'] is int)
            ? checkBody['userId']
            : int.tryParse('${checkBody['userId']}') ?? backendUserId;

        print('[login] userIdFromCheck (register path): $userIdFromCheck');

        if (userIdFromCheck == 0) {
          if (!mounted) return;
          setState(() {
            errorMessage = 'Unable to determine user for device registration';
          });
          return;
        }

        final info = await _getDeviceInfo();
        final registeredOK = await _registerDevice(
          userId: userIdFromCheck,
          deviceId: localDeviceId,
          deviceName: info['deviceName']!,
          platform: info['platform']!,
          token: token,
        );

        print('[login] registeredOK: $registeredOK');

        if (!registeredOK) {
          if (!mounted) return;
          setState(() {
            errorMessage = 'Device registration failed. Please try again.';
          });
          return;
        }

        // save session
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('device_id', localDeviceId);

        print('[login] registration success -> Dashboard');

        loginSuccess = true;
        if (!mounted) return;
        context.goNamed(RouteNames.home);
        return;
      }

      // CASE C: device is NOT trusted because another device is active -> takeover flow (401)
      if (checkDeviceRes.statusCode == 401) {
        final checkBody = jsonDecode(checkDeviceRes.body);
        print('[login] 401 body (takeover): $checkBody');

        final int takeoverUserId = (checkBody['userId'] is int)
            ? checkBody['userId']
            : int.tryParse('${checkBody['userId']}') ?? backendUserId;

        if (takeoverUserId == 0) {
          if (!mounted) return;
          setState(() {
            errorMessage = 'Unable to determine user for device takeover';
          });
          return;
        }

        // you might ALSO want to persist token here for DeviceTakeoverPage if it needs it
        await prefs.setBool('is_logged_in', false);
        await prefs.setString('device_id', localDeviceId);

        print('[login] navigate -> DeviceTakeoverPage(userId=$takeoverUserId)');

        loginSuccess = true;
        if (!mounted) return;

        context.pushNamed(
          RouteNames.takeover,
          extra: TakeoverArgs(
            phoneNum: phone,
            userId: takeoverUserId,
          ),
        );
        return;
      }

      // CASE D: user not found / bad (400)
      if (checkDeviceRes.statusCode == 400) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'User not found';
        });
        return;
      }

      // CASE E: anything else
      print('[login] unexpected checkDevice status ${checkDeviceRes.statusCode}');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Unexpected response (${checkDeviceRes.statusCode}).';
      });
      return;
    } catch (e) {
      print('[login] CATCH exception: $e');

      if (!loginSuccess && mounted) {
        setState(() {
          errorMessage = 'Connection error. Please try again.';
        });
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

                if (_pinController.text.isEmpty) ...[
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
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ),

                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
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

        const SizedBox(height: 28),
        Center(
          child: Text(
            'Use demo phone $_demoPhone and PIN $_demoPin',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(.85),
            ),
            textAlign: TextAlign.center,
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