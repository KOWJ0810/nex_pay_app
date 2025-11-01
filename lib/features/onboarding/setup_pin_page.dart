// lib/features/onboarding/setup_pin_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../router.dart';
import '../../widgets/custom_pin_keyboard.dart';

class SetupPinPage extends StatefulWidget {
  const SetupPinPage({super.key});

  @override
  State<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends State<SetupPinPage> with TickerProviderStateMixin {
  final List<String> _pin = [];
  late final AnimationController _bump;
  late final Animation<double> _scale;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    if (_pin.length < 6) {
      HapticFeedback.selectionClick();
      setState(() => _pin.add(value));
      _animateBump();
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _pin.removeLast());
      _animateBump();
    }
  }

  void _onClear() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _pin.clear());
    }
  }

  void _onProceed() {
    if (_pin.length == 6) {
      context.pushNamed(
        RouteNames.confirmPin,
        extra: {'originalPin': _pin.join()},
      );
    }
  }

  String _pinHint() {
    if (_pin.isEmpty) return "Create a unique 6-digit PIN.";
    final s = _pin.join();
    final allSame = s.split('').every((c) => c == s[0]);
    final is123456 = s == '123456';
    final is654321 = s == '654321';
    if (allSame || is123456 || is654321) {
      return "This PIN is easy to guess. Try something stronger.";
    }
    if (_pin.length < 6) {
      final remain = 6 - _pin.length;
      return "Keep going… $remain more digit${remain == 1 ? '' : 's'}.";
    }
    return "Looks good. Tap Proceed.";
  }

  Color _pinHintColor() {
    final msg = _pinHint();
    if (msg.startsWith("This PIN")) return Colors.amberAccent;
    if (msg.startsWith("Keep")) return Colors.white70;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    final subtle = Colors.white70;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          const _BackgroundBlobs(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── TOP CONTENT ───────────────────────────────────────────────
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
                        const _ShieldLogo(size: 84),
                        const SizedBox(height: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Set a 6-digit PIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Avoid birth dates or repeated digits.",
                          style: TextStyle(color: subtle),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),

                        // PIN bubbles + hint
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
                                    final filled = i < _pin.length;
                                    final char = filled ? _pin[i] : '';
                                    return _PinBubble(filled: filled, showChar: _showPin ? char : null);
                                  }),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // NEW: non-truncating hint bar that wraps
                              _HintBar(
                                text: _pinHint(),
                                color: _pinHintColor(),
                                showPin: _showPin,
                                onToggle: () => setState(() => _showPin = !_showPin),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // ── BOTTOM KEYPAD ─────────────────────────────────────────────
                CustomPinKeyboard(
                  onKeyTap: _onKeyTap,
                  onBackspace: _onBackspace,
                  onBackspaceLongPress: _onClear,
                  onClear: _onClear,
                  isEnabled: _pin.length == 6,
                  onProceed: _onProceed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrap-based hint/action row that never truncates the hint text.
class _HintBar extends StatelessWidget {
  final String text;
  final Color color;
  final bool showPin;
  final VoidCallback onToggle;

  const _HintBar({
    required this.text,
    required this.color,
    required this.showPin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w * 0.78),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showPin ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  showPin ? "Hide" : "Show",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
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

// ── UI helpers ───────────────────────────────────────────────────────────────

class _PinBubble extends StatelessWidget {
  final bool filled;
  final String? showChar; // if not null, show this instead of dot

  const _PinBubble({required this.filled, this.showChar});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: filled
              ? Text(
                  showChar ?? '●',
                  key: ValueKey(showChar ?? 'dot'),
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700),
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
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _CapsuleProgress extends StatelessWidget {
  final List<String> steps;
  final int currentIndex; // 1-indexed visual
  const _CapsuleProgress({required this.steps, required this.currentIndex});

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
                    color: isCurrent ? fillColor : (isDone ? doneColor : trackColor),
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
            final isActive = i <= currentIndex - 1;
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

class _ShieldLogo extends StatelessWidget {
  final double size;
  const _ShieldLogo({required this.size});

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
        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 42),
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