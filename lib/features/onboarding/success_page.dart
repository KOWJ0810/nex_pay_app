// lib/features/onboarding/success_page.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../router.dart' show RouteNames;

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _burst;
  late final AnimationController _ribbonSpin;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _ribbonSpin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    _ribbonSpin.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!context.mounted) return;
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    primaryColor.withOpacity(0.95),
                    primaryColor,
                    Colors.black.withOpacity(0.92),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Confetti burst (plays once)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                return CustomPaint(
                  painter: _BurstPainter(
                    progress: Curves.easeOut.transform(_burst.value),
                  ),
                );
              },
            ),
          ),

          // Main content (centered)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tick + pulse + ribbon
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulse, _ribbonSpin]),
                    builder: (_, __) {
                      final t = Curves.easeInOut.transform(_pulse.value);
                      final glow = 24.0 + (t * 14.0);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glowing aura
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.35 + t * 0.25),
                                  blurRadius: glow,
                                  spreadRadius: 6 + (t * 4),
                                ),
                              ],
                            ),
                          ),

                          // Permanently visible rotating ribbon
                          Transform.rotate(
                            angle: _ribbonSpin.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: _RibbonPainter(),
                            ),
                          ),

                          // Checkmark circle
                          Container(
                            width: 122,
                            height: 122,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withOpacity(0.3 + t * 0.1),
                                  accentColor.withOpacity(0.16),
                                  accentColor.withOpacity(0.06),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              border: Border.all(
                                color: accentColor.withOpacity(0.65),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Gradient title
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(r),
                    child: const Text(
                      "Account Created!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Frosted info card
                  const _FrostedCard(
                    child: Text(
                      "Your NexPay account has been successfully created.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // CTA button
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: math.min(480, media.size.width),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _finishOnboarding(context),
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black87,
                      ),
                      label: const Text(
                        "Go to Dashboard",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: accentColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted info card
class _FrostedCard extends StatelessWidget {
  final Widget child;
  const _FrostedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
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
        ),
      ),
    );
  }
}

/// Confetti painter
class _BurstPainter extends CustomPainter {
  final double progress;
  _BurstPainter({required this.progress});

  final List<Color> _colors = const [
    Color(0xFFB8E986),
    Color(0xFF78D64B),
    Color(0xFFA3F7BF),
    Color(0xFFDAFFD8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.42);
    final baseRadius = 18.0;
    final spread = lerpDouble(0, size.shortestSide * 0.45, Curves.easeOut.transform(progress))!;
    const count = 26;

    for (var i = 0; i < count; i++) {
      final t = i / count;
      final angle = t * math.pi * 2;
      final radius = baseRadius + spread * (0.65 + 0.35 * math.sin(i * 3));
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;
      final fade = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = _colors[i % _colors.length].withOpacity(0.22 * fade)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), 5.0 + 3.0 * (1 - fade), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}

/// Ribbon painter — always visible rotating arcs
class _RibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFB8E986),
          Color(0xFF78D64B),
          Color(0xFFFFFFFF),
          Color(0xFFB8E986),
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(rect);

    const gap = math.pi / 8;
    const arcs = 3;
    for (int i = 0; i < arcs; i++) {
      final start = (i * (2 * math.pi / arcs)) + gap;
      const sweep = math.pi / 1.5;
      canvas.drawArc(
        Rect.fromLTWH(stroke, stroke, size.width - stroke * 2, size.height - stroke * 2),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}