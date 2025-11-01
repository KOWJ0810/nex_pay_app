// lib/features/auth/email_otp_verification_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../router.dart' show RouteNames;

/// Email OTP Verification
class EmailVerificationPage extends StatefulWidget {
  final String email;
  const EmailVerificationPage({required this.email, Key? key}) : super(key: key);

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isResending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nodes.isNotEmpty) _nodes.first.requestFocus();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 4-digit code")),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "otp": code}),
      );

      final ok = res.statusCode == 200 && res.body.contains("success");
      if (!mounted) return;

      if (ok) {
        context.goNamed(RouteNames.icVerification);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error verifying OTP")),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isResending = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to resend OTP")),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error resending OTP")),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // Smart paste + next focus on type + fallback backspace handling
  void _onOtpChanged(int index, String value) {
    // Smart paste in first box
    if (index == 0 && value.length >= 2) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = i < digits.length ? digits[i] : '';
        }
        final nextIndex = digits.length.clamp(0, 3);
        _nodes[nextIndex].requestFocus();
        return;
      }
    }

    // Keep only last char
    if (value.length > 1) {
      _controllers[index].text = value.characters.last;
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    // NEW: fallback backspace logic — if field becomes empty, hop back & clear previous
    if (value.isEmpty && index > 0) {
      _controllers[index - 1].text = '';
      _nodes[index - 1].requestFocus();
      return;
    }

    // Move forward when typed
    if (value.isNotEmpty && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    }
  }

  // Key-event backspace helper (for hardware keyboards)
  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].text = '';
      _nodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.white70;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          const _BackgroundBlobs(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      const _CapsuleProgress(
                        steps: ["Start", "Verify", "Secure"],
                        currentIndex: 1,
                      ),

                      const SizedBox(height: 26),

                      const _WalletLogo(size: 86),
                      const SizedBox(height: 12),

                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Verify Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        "Enter the 4-digit code we sent to",
                        style: TextStyle(color: subtle, fontSize: 14.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 22),

                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        child: Column(
                          children: [
                            // OTP boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(4, (i) {
                                return _OtpBox(
                                  controller: _controllers[i],
                                  focusNode: _nodes[i],
                                  onChanged: (v) => _onOtpChanged(i, v),
                                  onBackspace: () => _onBackspace(i),
                                );
                              }),
                            ),

                            const SizedBox(height: 16),

                            // Resend row
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _isResending
                                  ? Row(
                                      key: const ValueKey("resending"),
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 10),
                                        Text("Sending code...",
                                            style: TextStyle(color: Colors.white70)),
                                      ],
                                    )
                                  : _canResend
                                      ? TextButton.icon(
                                          key: const ValueKey("resend"),
                                          onPressed: _resendOtp,
                                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                          label: const Text(
                                            'Resend Code',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            backgroundColor: Colors.white.withOpacity(0.06),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Colors.white.withOpacity(0.08),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Resend available in $_secondsRemaining s',
                                          key: const ValueKey("countdown"),
                                          style: const TextStyle(color: Colors.white60),
                                        ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Continue button
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 22,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _verifying ? null : verifyOtp,
                          icon: _verifying
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.verified_rounded, color: Colors.black),
                          label: Text(
                            _verifying ? "Verifying..." : "Continue",
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      SizedBox(height: bottomInset > 0 ? bottomInset + 10 : 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Capsule Step Progress Bar
class _CapsuleProgress extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const _CapsuleProgress({
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final trackColor = Colors.white.withOpacity(0.12);
    final fillColor = accentColor;
    final doneColor = accentColor.withOpacity(0.75);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: List.generate(steps.length, (i) {
              final isDone = i < currentIndex;
              final isCurrent = i == currentIndex;
              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(
                    left: i == 0 ? 0 : 2,
                    right: i == steps.length - 1 ? 0 : 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? fillColor
                        : isDone
                            ? doneColor
                            : trackColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: fillColor.withOpacity(0.35),
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
            final isActive = i == currentIndex || i < currentIndex;
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
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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

/// OTP input box (one digit) with backspace handling
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
    );

    return SizedBox(
      width: 64,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty) {
              onBackspace();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          cursorColor: accentColor,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: baseBorder,
            focusedBorder: baseBorder.copyWith(
              borderSide: BorderSide(color: accentColor, width: 1.6),
            ),
          ),
          onChanged: onChanged,
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
      width: double.infinity,
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
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WalletLogo extends StatelessWidget {
  final double size;
  const _WalletLogo({required this.size});

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
        // Circle
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
        const Icon(
          Icons.mark_email_read_outlined,
          color: Colors.white,
          size: 42,
        ),
      ],
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned(top: -70, right: -70, child: _blob(accentColor.withOpacity(0.25), 280)),
          Positioned(bottom: -120, left: -70, child: _blob(Colors.white.withOpacity(0.08), 300)),
          Positioned(top: 240, left: -60, child: _blob(accentColor.withOpacity(0.10), 220)),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.02)]),
      ),
    );
  }
}