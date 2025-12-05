// lib/features/account/device_takeover_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/features/auth/security_fallback_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../router.dart'; // for RouteNames.home

class DeviceTakeoverPage extends StatefulWidget {
  final String phoneNum;
  final int userId;

  const DeviceTakeoverPage({
    super.key,
    required this.phoneNum,
    required this.userId,
  });

  @override
  State<DeviceTakeoverPage> createState() => _DeviceTakeoverPageState();
}

class _DeviceTakeoverPageState extends State<DeviceTakeoverPage>
    with SingleTickerProviderStateMixin {
  bool _starting = false;
  bool _checking = false;
  bool _started = false;

  bool _hasCompletedTakeover = false;
  bool _didNavigate = false;

  final bool _autoPoll = true;
  Timer? _pollTimer;

  String? _deviceId;
  String? _deviceName;
  String? _platform;

  int? _takeoverId;
  String? _message;

  // ── Session info (now read from secure storage) ─────────
  String _authToken = '';
  int _sessionUserId = 0;
  String? _sessionPhone;
  String? _sessionEmail;
  String? _sessionName;
  String? _sessionStatus;

  static const FlutterSecureStorage _secure = secureStorage;

  late final AnimationController _entrance;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeIn;

  void _goSecurityFallback() {
  final uid = _sessionUserId != 0 ? _sessionUserId : widget.userId;
  if (_deviceId == null || _deviceName == null || _platform == null) {
    _showSnack('Device details not ready yet. Please try again.');
    return;
  }
  context.pushNamed(
    RouteNames.securityFallback,
    extra: SecurityFallbackArgs(
      userId: uid,
      deviceId: _deviceId!,
      deviceName: _deviceName!,
      platform: _platform!,
    ),
  );
}

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _scaleIn = Tween(begin: .98, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
    );

    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOut),
    );

    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Read from secure storage first; fall back to prefs for older logins
    final token = await _secure.read(key: 'token') 
    ?? prefs.getString('auth_token') 
    ?? '';

    final userIdStrSecure = await _secure.read(key: 'user_id');
    final userIdStrPrefs  = prefs.getString('user_id');

    final parsedUserId = int.tryParse(userIdStrSecure ?? userIdStrPrefs ?? '') 
        ?? widget.userId;

    _sessionPhone  = await _secure.read(key: 'phoneNum') ?? prefs.getString('user_phone');
    _sessionEmail  = await _secure.read(key: 'email') ?? prefs.getString('user_email');
    _sessionName   = await _secure.read(key: 'username') ?? prefs.getString('username');
    _sessionStatus = await _secure.read(key: 'user_status') ?? prefs.getString('user_status');

    // 2) Ensure / reuse deviceId (we keep this in SharedPreferences by design)
    String? dId = prefs.getString('device_id');
    if (dId == null || dId.isEmpty) {
      dId = const Uuid().v4();
      await prefs.setString('device_id', dId);
    }

    // 3) Device info
    final info = DeviceInfoPlugin();
    String platform =
        Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Unknown');
    String name = 'This device';
    try {
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        name = ios.modelName ?? ios.name ?? 'iPhone';
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        name = android.model ?? android.device ?? 'Android';
      }
    } catch (_) {
      // fallback fine
    }

    if (!mounted) return;
    setState(() {
      _authToken = token;
      _sessionUserId = parsedUserId;
      _deviceId = dId;
      _deviceName = name;
      _platform = platform;
    });
  }

  Future<void> _initiateTakeover() async {
    if (_starting || _deviceId == null) return;

    setState(() {
      _starting = true;
      _message = null;
    });

    final uid = _sessionUserId != 0 ? _sessionUserId : widget.userId;

    final url = Uri.parse('${ApiConfig.baseUrl}/users/initiateTakeover');
    final body = jsonEncode({
      'userId': uid,
      'toDeviceId': _deviceId,
      'toDeviceName': _deviceName,
      'toPlatform': _platform,
    });

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final takeoverRaw = data['takeoverId'];
        final takeoverParsed =
            takeoverRaw is int ? takeoverRaw : int.tryParse('$takeoverRaw');

        setState(() {
          _started = true;
          _takeoverId = takeoverParsed;
          _message = 'Waiting for approval on your old device.';
        });

        // auto start polling
        if (_autoPoll) {
          _pollTimer?.cancel();
          _pollTimer = Timer.periodic(
            const Duration(seconds: 5),
            (_) => _checkStatus(),
          );
        }
      } else {
        _showSnack('Failed to start takeover (${res.statusCode}).');
        setState(() {
          _message = 'Failed to start takeover (${res.statusCode}).';
        });
      }
    } catch (_) {
      _showSnack('Network error. Please try again.');
      setState(() {
        _message = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
        });
      }
    }
  }

  Future<void> _checkStatus() async {
  // stop if already handled
  if (_hasCompletedTakeover || _didNavigate) return;
  if (_checking || _takeoverId == null) return;
  if (_deviceId == null || _deviceId!.isEmpty) {
    setState(() => _message = 'Missing device ID. Please try again.');
    return;
  }

  setState(() {
    _checking = true;
  });

  final uid = _sessionUserId != 0 ? _sessionUserId : widget.userId;

  // 👇 pass currentDeviceId as a query param
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/users/checkApprovedTakeover/$uid',
  ).replace(queryParameters: {
    'currentDeviceId': _deviceId!,
  });

  try {
    final res = await http.get(
      url,
      headers: {
        if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final success = data['success'] == true;
      final status = (data['status'] ?? '').toString();      // PENDING/APPROVED/...
      final msg     = (data['message'] ?? '').toString();

      switch (status) {
        case 'APPROVED':
          if (success) {
            // 🎉 approved for THIS device
            _pollTimer?.cancel();
            _pollTimer = null;
            _hasCompletedTakeover = true;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', true);
            await prefs.setInt('user_id', uid);
            await prefs.setString('device_id', _deviceId!);

            if (!mounted) return;
            setState(() {
              _checking = false;
              _message = msg.isNotEmpty ? msg : 'Approved! Redirecting…';
            });
            _showSnack('Approved! Redirecting…');

            _didNavigate = true;
            Future.microtask(() {
              if (!mounted) return;
              GoRouter.of(context).goNamed(RouteNames.home);
            });
            return;
          } else {
            // approved but not valid? treat as expired/unexpected
            if (mounted) {
              setState(() {
                _message = msg.isNotEmpty ? msg : 'Approval invalid. Please try again.';
              });
            }
          }
          break;

        case 'PENDING':
          if (mounted && !_hasCompletedTakeover && !_didNavigate) {
            setState(() {
              _message = msg.isNotEmpty ? msg : 'Approval is still pending.';
              _started = true; // ensure UI shows step 1 complete
            });
          }
          break;

        case 'EXPIRED':
          // reset flow so user can start again
          if (mounted) {
            setState(() {
              _message = msg.isNotEmpty ? msg : 'Approval expired. Please initiate again.';
              _started = false;
              _takeoverId = null;
            });
          }
          _pollTimer?.cancel();
          _pollTimer = null;
          break;

        case 'INVALID_DEVICE':
          if (mounted) {
            setState(() {
              _message = msg.isNotEmpty ? msg : 'This device is not the approved target.';
            });
          }
          _pollTimer?.cancel();
          _pollTimer = null;
          break;

        case 'NONE':
        default:
          if (mounted) {
            setState(() {
              _message = msg.isNotEmpty ? msg : 'No takeover request found.';
              if (status == 'NONE') {
                _started = false;
                _takeoverId = null;
              }
            });
          }
          _pollTimer?.cancel();
          _pollTimer = null;
          break;
      }
    } else if (res.statusCode == 403) {
      // server already returns INVALID_DEVICE here; show body message
      final data = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _message = (data['message'] ?? 'This device is not the target.').toString();
        });
      }
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      if (mounted && !_hasCompletedTakeover && !_didNavigate) {
        setState(() {
          _message = 'Server error (${res.statusCode}).';
        });
      }
    }
  } catch (e) {
    if (mounted && !_hasCompletedTakeover && !_didNavigate) {
      setState(() {
        _message = 'Network error. Please try again.';
      });
    }
  } finally {
    if (mounted && !_hasCompletedTakeover && !_didNavigate) {
      setState(() {
        _checking = false;
      });
    }
  }
}

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = !_starting && _deviceId != null && !_started;
    final canCheck = !_checking && _started && _takeoverId != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(.10),
              const Color(0xFFF5F7FB),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        children: [
                          _AppBar(
                            onClose: () {
                              _pollTimer?.cancel();
                              _pollTimer = null;
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 14),

                          _HeaderCard(
                            title: 'Move to a new device',
                            subtitle:
                                'We’ll ask your old device to approve the switch.\nThis helps keep your account secure.',
                          ),
                          const SizedBox(height: 16),

                          ScaleTransition(
                            scale: _scaleIn,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                border: Border.all(
                                  color: accentColor.withOpacity(.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DeviceRow(
                                    name: _deviceName ?? 'This device',
                                    platform: _platform ?? '',
                                  ),
                                  const SizedBox(height: 16),

                                  _ProgressTrack(active: _started ? 1 : 0),

                                  const SizedBox(height: 16),
                                  _Step(
                                    index: 1,
                                    title: 'Start takeover on this device',
                                    subtitle:
                                        'We’ll notify your old device and email you an OTP.',
                                    trailing: _FullWidthButton(
                                      label: _starting
                                          ? 'Starting…'
                                          : 'Start takeover',
                                      onPressed:
                                          canStart ? _initiateTakeover : null,
                                      busy: _starting,
                                    ),
                                  ),

                                  const _Divider(),
                                  const _Step(
                                    index: 2,
                                    title: 'Approve on your old device',
                                    subtitle:
                                        'Open NexPay on your old device → Settings → Device Takeover → enter OTP → Approve.',
                                  ),

                                  const _Divider(),
                                  _Step(
                                    index: 3,
                                    title: 'I’ve approved on my old device',
                                    subtitle:
                                        'Tap below and we’ll confirm the approval.',
                                    trailing: _FullWidthButton(
                                      label: _checking
                                          ? 'Checking…'
                                          : 'Check status',
                                      onPressed:
                                          canCheck ? _checkStatus : null,
                                      busy: _checking,
                                      outlined: true,
                                    ),
                                  ),

                                  if (_message != null) ...[
                                    const SizedBox(height: 14),
                                    _InfoBadge(text: _message!),
                                  ],

                                  if (_takeoverId != null) ...[
                                    const SizedBox(height: 8),
                                    _Pill(text: 'Request ID: $_takeoverId'),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () {
                              _pollTimer?.cancel();
                              _pollTimer = null;
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel and go back',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                            
                          ),
                          const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _goSecurityFallback,
                              icon: const Icon(Icons.help_outline_rounded),
                              label: const Text(
                                'Unable to access your old phone? Answer security questions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ───────────── UI bits ───────────── */

class _AppBar extends StatelessWidget {
  final VoidCallback onClose;
  const _AppBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          'Device takeover',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: accentColor,
          tooltip: 'Close',
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.sync_lock_rounded, color: primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: primaryColor.withOpacity(.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String name;
  final String platform;
  const _DeviceRow({required this.name, required this.platform});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(.35)),
          ),
          child: Icon(Icons.smartphone_rounded, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$name • $platform',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const _StatusChip(started: true),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final int active; // 0..2
  const _ProgressTrack({required this.active});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool filled) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: filled ? accentColor : accentColor.withOpacity(.25),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withOpacity(.55)),
          ),
        );

    Widget bar(bool filled) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: filled ? accentColor : accentColor.withOpacity(.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );

    return Row(
      children: [
        dot(active >= 0),
        bar(active >= 1),
        dot(active >= 1),
        bar(active >= 2),
        dot(active >= 2),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool started;
  const _StatusChip({required this.started});

  @override
  Widget build(BuildContext context) {
    final text = started ? 'Pending' : 'Not started';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withOpacity(.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _Step({
    required this.index,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepNumber(index: index),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black54)),
                if (trailing != null) ...[
                  const SizedBox(height: 10),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNumber extends StatelessWidget {
  final int index;
  const _StepNumber({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(.45)),
      ),
      child: Text(
        '$index',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: primaryColor,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        color: accentColor.withOpacity(.25),
        height: 1,
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String text;
  const _InfoBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(.55)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withOpacity(.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FullWidthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool outlined;

  const _FullWidthButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    if (outlined) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: accentColor,
          shape: shape,
          elevation: 0,
          side: BorderSide(color: primaryColor, width: 1.4),
        ),
        child: SizedBox(
          height: 50,
          child: Center(
            child: busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                : const Text(
                    'Check status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        shape: shape,
        elevation: 0,
      ),
      child: SizedBox(
        height: 50,
        child: Center(
          child: busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}