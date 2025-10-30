// lib/features/account/trusted_devices_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';

class TrustedDevicesPage extends StatefulWidget {
  const TrustedDevicesPage({super.key});

  @override
  State<TrustedDevicesPage> createState() => _TrustedDevicesPageState();
}

class _TrustedDevicesPageState extends State<TrustedDevicesPage> {
  // local device info (for UI only)
  String _deviceName = 'This device';
  String _platform =
      Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Other');
  String _deviceId = '';

  // user / session info
  int _userId = 0;
  String _email = '';
  String _authToken = '';

  // takeover state
  bool _loadingPage = true;
  bool _checkingPending = true;
  bool _hasPendingTakeover = false;
  String _pendingMessage = '';
  String _pendingDeviceName = ''; // e.g. "iPhone 16"
  bool _submittingOtp = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    final storedUserId = prefs.getInt('user_id') ?? 0;
    final storedDeviceId = prefs.getString('device_id') ?? '';
    final storedEmail = prefs.getString('user_email') ?? '';
    final storedToken = prefs.getString('auth_token') ?? '';

    // detect human-ish device label
    final info = DeviceInfoPlugin();
    String humanName = 'This device';
    try {
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        humanName = ios.name ?? ios.modelName ?? ios.model ?? 'iPhone';
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        final brand = android.brand ?? '';
        final model = android.model ?? android.device ?? '';
        final combo = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
        humanName = combo.isEmpty ? 'Android Device' : combo;
      }
    } catch (_) {
      // fallback okay
    }

    if (kDebugMode) {
      print('[trusted] bootstrap userId=$storedUserId '
          'email=$storedEmail deviceId=$storedDeviceId token?=${storedToken.isNotEmpty}');
    }

    if (!mounted) return;
    setState(() {
      _userId = storedUserId;
      _deviceId = storedDeviceId;
      _email = storedEmail;
      _authToken = storedToken;
      _deviceName = humanName;
      _loadingPage = false;
    });

    if (_userId != 0 && _authToken.isNotEmpty) {
      await _checkPendingTakeover(_userId);
    } else {
      if (mounted) {
        setState(() {
          _checkingPending = false;
        });
      }
    }
  }

  Future<void> _checkPendingTakeover(int userId) async {
    setState(() {
      _checkingPending = true;
    });

    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}/users/checkPendingTakeover/$userId');

      if (kDebugMode) {
        print('[trusted] checkPendingTakeover GET $url');
      }

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        print('[trusted] status=${res.statusCode}');
        print('[trusted] body=${res.body}');
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // hasPending could be bool or "true"
        final rawHasPending = data['hasPending'];
        bool pending = rawHasPending == true ||
            (rawHasPending is String &&
                rawHasPending.toLowerCase() == 'true');

        final backendDeviceName =
            (data['toDeviceName'] ?? 'New device').toString();
        final backendEmail = data['email']?.toString();
        final backendUserIdRaw = data['userId'];
        final backendUserId = backendUserIdRaw is int
            ? backendUserIdRaw
            : int.tryParse('$backendUserIdRaw') ?? _userId;

        final backendMessage = data['message']?.toString() ?? '';

        // age check (<=10 min)
        final initiatedAtStr = data['initiatedAt']?.toString();
        bool stillFresh = true;
        if (initiatedAtStr != null && initiatedAtStr.isNotEmpty) {
          try {
            final initiatedAt = DateTime.parse(initiatedAtStr).toLocal();
            final diff = DateTime.now().difference(initiatedAt);
            if (diff.inMinutes > 10) stillFresh = false;
          } catch (err) {
            if (kDebugMode) {
              print('[trusted] initiatedAt parse error: $err');
            }
          }
        }
        if (!stillFresh) {
          pending = false;
        }

        if (!mounted) return;
        setState(() {
          _hasPendingTakeover = pending;
          _pendingDeviceName = pending ? backendDeviceName : '';
          _email = backendEmail ?? _email;
          _userId = backendUserId;
          _pendingMessage = pending
              ? 'New device "$backendDeviceName" is requesting access. '
                  'Approve only if this is really you.'
              : backendMessage;
        });
      } else if (res.statusCode == 404) {
        // nothing pending
        if (!mounted) return;
        setState(() {
          _hasPendingTakeover = false;
          _pendingMessage = '';
          _pendingDeviceName = '';
        });
      } else {
        if (!mounted) return;
        setState(() {
          _hasPendingTakeover = false;
          _pendingMessage =
              'Unable to check takeover status (server ${res.statusCode}).';
          _pendingDeviceName = '';
        });
      }
    } catch (err) {
      if (kDebugMode) {
        print('[trusted] checkPendingTakeover error=$err');
      }
      if (!mounted) return;
      setState(() {
        _hasPendingTakeover = false;
        _pendingMessage =
            'Network error while checking takeover status.';
        _pendingDeviceName = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingPending = false;
        });
      }
    }
  }

  Future<void> _onApproveTap() async {
    final otp = await _showOtpDialog();
    if (otp == null) return;
    await _confirmTakeover(otp);
  }

  Future<String?> _showOtpDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> submit() async {
              final code = controller.text.trim();
              if (code.length != 4) {
                setLocalState(() {
                  errorText = 'Please enter the 4-digit code';
                });
                return;
              }
              Navigator.of(ctx).pop(code);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Approve takeover',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter the 4-digit OTP sent to $_email\nfor $_pendingDeviceName.\n\n'
                    'Important: Approving will sign you out on this phone and '
                    'move your account to the new device.',
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'OTP Code',
                      counterText: '',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: submit,
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmTakeover(String otpCode) async {
    if (_submittingOtp) return;
    setState(() {
      _submittingOtp = true;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/confirmTakeover');

      if (kDebugMode) {
        print('[trusted] confirmTakeover body => { '
            'userId: $_userId, email: $_email, otp: $otpCode }');
      }

      final body = jsonEncode({
        "userId": _userId,
        "email": _email,
        "otp": otpCode,
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: body,
      );

      if (kDebugMode) {
        print('[trusted] confirmTakeover status=${res.statusCode}');
        print('[trusted] confirmTakeover resp=${res.body}');
      }

      if (res.statusCode == 200) {
        // Success: sign out THIS device.
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!mounted) return;

        // Let the user know quickly.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Takeover approved. You have been signed out on this device.',
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Now hard-redirect to onboarding/welcome.
        // Assumes you have a go_router route named 'welcome' pointing at WelcomePage (/)
        context.goNamed('welcome');
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to confirm takeover (${res.statusCode}).'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (err) {
      if (kDebugMode) {
        print('[trusted] confirmTakeover error=$err');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Network error while confirming takeover.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingOtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: Colors.black87,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Trusted device',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed:
                _checkingPending ? null : () => _checkPendingTakeover(_userId),
            icon: _checkingPending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.black87,
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingPage
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  if (_hasPendingTakeover) ...[
                    _PendingTakeoverCard(
                      deviceName: _pendingDeviceName,
                      message: _pendingMessage,
                      busy: _submittingOtp,
                      onApprove: _onApproveTap,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const _SectionTitle('This device'),
                  _DeviceCard(
                    title: _deviceName,
                    subtitle: '$_platform • $_deviceId',
                    badgeText:
                        _hasPendingTakeover ? 'Pending approval' : 'Trusted',
                    badgeColor: _hasPendingTakeover
                        ? Colors.orange.withOpacity(.15)
                        : accentColor,
                    badgeTextColor: _hasPendingTakeover
                        ? (Colors.orange[900] ?? Colors.deepOrange)
                        : primaryColor,
                  ),
                  SizedBox(height: bottomPad + 32),
                ],
              ),
      ),
    );
  }
}

/* -------------------- UI widgets -------------------- */

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _PendingTakeoverCard extends StatelessWidget {
  final String deviceName;
  final String message;
  final bool busy;
  final VoidCallback onApprove;

  const _PendingTakeoverCard({
    required this.deviceName,
    required this.message,
    required this.busy,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_lock_rounded, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Approval required',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.isNotEmpty
                ? message
                : 'A new device ("$deviceName") is asking to log in. '
                    'Only approve if this was you.',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                busy ? 'Approving…' : 'Approve takeover',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;

  const _DeviceCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: accentColor.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon box
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withOpacity(.4),
              ),
            ),
            child: Icon(
              Icons.smartphone_rounded,
              color: primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}