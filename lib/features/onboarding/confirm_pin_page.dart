// lib/features/onboarding/confirm_pin_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../models/registration_data.dart';
import '../../router.dart';
import '../../widgets/custom_pin_keyboard.dart';

class ConfirmPinPage extends StatefulWidget {
  final String originalPin;
  const ConfirmPinPage({required this.originalPin, super.key});

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage>
    with TickerProviderStateMixin {
  final List<String> _confirmPin = [];
  String? _error;
  bool _busy = false;

  late final AnimationController _bump;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _bump, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  void _animateBump() async {
    try {
      await _bump.forward();
    } finally {
      if (mounted) _bump.reverse();
    }
  }

  void _onKeyTap(String value) {
    if (_confirmPin.length < 6) {
      HapticFeedback.selectionClick();
      setState(() => _confirmPin.add(value));
      _animateBump();
    }
  }

  void _onBackspace() {
    if (_confirmPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _confirmPin.removeLast());
      _animateBump();
    }
  }

  void _onClear() {
    if (_confirmPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _confirmPin.clear();
        _error = null;
      });
    }
  }

  Future<String> _uploadImage(File file, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[ConfirmPin] Firebase upload failed ($fileName): ${e.code} ${e.message}');
      throw Exception('Upload failed. Please try again.');
    } catch (e) {
      debugPrint('[ConfirmPin] Upload error ($fileName): $e');
      rethrow;
    }
  }

  Future<void> _onProceed() async {
    final pin = _confirmPin.join();

    if (pin != widget.originalPin) {
      setState(() {
        _error = "PINs don’t match. Re-enter to confirm.";
        _confirmPin.clear();
      });
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _error = null);
      return;
    }

    if (RegistrationData.icFrontImage == null ||
        RegistrationData.icBackImage == null ||
        RegistrationData.selfieImage == null) {
      setState(() {
        _error = "Some documents are missing. Please restart verification.";
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      RegistrationData.pin = pin;

      final icFrontUrl = await _uploadImage(
        RegistrationData.icFrontImage!,
        'ic_front_${RegistrationData.icNum}.jpg',
      );
      final icBackUrl = await _uploadImage(
        RegistrationData.icBackImage!,
        'ic_back_${RegistrationData.icNum}.jpg',
      );
      final selfieUrl = await _uploadImage(
        RegistrationData.selfieImage!,
        'selfie_${RegistrationData.icNum}.jpg',
      );

      final body = jsonEncode({
        "user_name": RegistrationData.fullName,
        "ic_num": RegistrationData.icNum,
        "phoneNum": RegistrationData.phoneNum,
        "ic_image_front": icFrontUrl,
        "ic_image_back": icBackUrl,
        "user_verification_image": selfieUrl,
        "email": RegistrationData.email,
        "street_address": RegistrationData.street,
        "postcode": RegistrationData.postcode,
        "city": RegistrationData.city,
        "state": RegistrationData.state,
        "country": "Malaysia",
        "account_pin_num": RegistrationData.pin,
      });

      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/users/createUser"),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', RegistrationData.email);

        if (!mounted) return;
        context.goNamed(RouteNames.enableBiometric);
      } else {
        String serverMsg = 'Failed to create user. Please try again.';
        try {
          final js = jsonDecode(response.body);
          if (js is Map && js['message'] is String) {
            serverMsg = js['message'];
          }
        } catch (_) {}
        setState(() => _error = serverMsg);
      }
    } on SocketException {
      setState(() => _error = "No internet connection. Please check your network.");
    } on TimeoutException {
      setState(() => _error = "The server took too long to respond. Try again.");
    } catch (_) {
      setState(() => _error = "Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.white70;
    final isReady = _confirmPin.length == 6;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: primaryColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        const _CapsuleProgress(
                          steps: ["Start", "Verify", "Secure"],
                          currentIndex: 3,
                        ),
                        const SizedBox(height: 24),
                        const _LockLogo(size: 82),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(r),
                          child: const Text(
                            'Confirm PIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Re-enter the same 6 digits you set previously.",
                          style: TextStyle(color: subtle),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        _GlassCard(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScaleTransition(
                                scale: _scale,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (i) {
                                    final filled = i < _confirmPin.length;
                                    return _PinBubble(
                                      filled: filled,
                                      error: _error != null,
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_error != null)
                                _ErrorBanner(text: _error!)
                              else
                                _HintBar(
                                  text: isReady
                                      ? "Looks good. Tap Proceed to continue."
                                      : "Enter your PIN again to confirm.",
                                  color: isReady ? Colors.greenAccent : Colors.white70,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                CustomPinKeyboard(
                  onKeyTap: _onKeyTap,
                  onBackspace: _onBackspace,
                  onBackspaceLongPress: _onClear,
                  onClear: _onClear,
                  isEnabled: isReady && !_busy,
                  onProceed: _onProceed,
                ),
              ],
            ),
          ),
        ),

        // Frosted loading overlay
        if (_busy)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                alignment: Alignment.center,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: _FrostedLoading(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Frosted loading card (no underline, no overflow)
class _FrostedLoading extends StatefulWidget {
  const _FrostedLoading();

  @override
  State<_FrostedLoading> createState() => _FrostedLoadingState();
}

class _FrostedLoadingState extends State<_FrostedLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.2).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please wait…",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "We’re finalizing your account setup",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// UI Parts
class _HintBar extends StatelessWidget {
  final String text;
  final Color color;
  const _HintBar({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, height: 1.25),
        softWrap: true,
      ),
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
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinBubble extends StatelessWidget {
  final bool filled;
  final bool error;
  const _PinBubble({required this.filled, required this.error});

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? Colors.redAccent : Colors.white.withOpacity(0.10);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: borderColor),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: (error ? Colors.redAccent : accentColor).withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: filled
              ? const Text(
                  '●',
                  key: ValueKey('dot'),
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : const SizedBox(key: ValueKey('empty')),
        ),
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
        color: Colors.white.withOpacity(0.05),
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

class _CapsuleProgress extends StatelessWidget {
  final List<String> steps;
  final int currentIndex; // 1-indexed in your copy, but we treat as given number
  const _CapsuleProgress({required this.steps, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final track = Colors.white.withOpacity(0.12);
    final fill = accentColor;
    final done = accentColor.withOpacity(0.75);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: List.generate(steps.length, (i) {
              final isDone = i < currentIndex - 1;
              final isCurrent = i == currentIndex - 1;
              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(
                    left: i == 0 ? 0 : 2,
                    right: i == steps.length - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent ? fill : (isDone ? done : track),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: fill.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(steps.length, (i) {
            final active = i <= currentIndex - 1;
            return Expanded(
              child: Align(
                alignment: i == 0
                    ? Alignment.centerLeft
                    : i == steps.length - 1
                        ? Alignment.centerRight
                        : Alignment.center,
                child: Text(
                  steps[i],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white60,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LockLogo extends StatelessWidget {
  final double size;
  const _LockLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.45),
                blurRadius: 38,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Ring
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withOpacity(0.32),
                accentColor.withOpacity(0.14),
                accentColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: accentColor.withOpacity(0.55), width: 3),
          ),
        ),
        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 42),
      ],
    );
  }
}