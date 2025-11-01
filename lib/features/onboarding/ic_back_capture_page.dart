// lib/features/onboarding/ic_back_capture_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/colors.dart';
import '../../router.dart';

class ICBackCapturePage extends StatefulWidget {
  final String fullName;
  final String icNumber;
  final File frontImage;

  const ICBackCapturePage({
    super.key,
    required this.fullName,
    required this.icNumber,
    required this.frontImage,
  });

  @override
  State<ICBackCapturePage> createState() => _ICBackCapturePageState();
}

class _ICBackCapturePageState extends State<ICBackCapturePage> {
  File? backImage;
  bool _processing = false;

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        backImage = File(picked.path);
      });
    }
  }

  void _goToConfirmPage() {
    if (backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture the back of your IC.")),
      );
      return;
    }

    context.pushNamed(
      RouteNames.confirmICInfo,
      extra: {
        'fullName': widget.fullName,
        'icNumber': widget.icNumber,
        'icImage': widget.frontImage,
        'icBackImage': backImage!,
      },
    );
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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      const _CapsuleProgress(
                        steps: ["Start", "Verify", "Secure"],
                        currentIndex: 2,
                      ),

                      const SizedBox(height: 24),

                      const _IdCardLogo(size: 84),
                      const SizedBox(height: 10),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Capture IC Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ensure the back of your IC is clearly visible and readable.",
                        style: TextStyle(color: subtle),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      _GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Take a photo of the back of your IC",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AspectRatio(
                              aspectRatio: 16 / 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.05),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: backImage == null
                                            ? const Center(
                                                child: Icon(
                                                  Icons.credit_card,
                                                  color: Colors.white70,
                                                  size: 56,
                                                ),
                                              )
                                            : Image.file(backImage!, fit: BoxFit.cover),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: _CornersOverlay(
                                        color: accentColor.withOpacity(0.7),
                                      ),
                                    ),
                                    if (backImage != null)
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: TextButton.icon(
                                          onPressed: _openCamera,
                                          icon: const Icon(Icons.camera_alt_outlined,
                                              color: Colors.white),
                                          label: const Text("Retake",
                                              style: TextStyle(color: Colors.white)),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.black.withOpacity(0.35),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    if (backImage == null)
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: _openCamera,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _TipChip(icon: Icons.light_mode_outlined, text: "Bright lighting"),
                                _TipChip(icon: Icons.grid_on_outlined, text: "Flat surface"),
                                _TipChip(icon: Icons.camera_enhance_outlined, text: "No glare"),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openCamera,
                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.black),
                                label: const Text(
                                  "Open Camera",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  minimumSize: const Size(double.infinity, 50),
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

                      const SizedBox(height: 20),
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
                          onPressed: _processing ? null : _goToConfirmPage,
                          icon: _processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.black),
                          label: Text(
                            _processing ? "Processing..." : "Next",
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
          if (_processing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _CornersOverlay extends StatelessWidget {
  final Color color;
  const _CornersOverlay({required this.color});

  @override
  Widget build(BuildContext context) {
    const double len = 26;
    const double stroke = 3;
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornersPainter(color: color, length: len, stroke: stroke),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  final Color color;
  final double length;
  final double stroke;
  _CornersPainter({required this.color, required this.length, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(length, 0), p);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), p);

    canvas.drawLine(Offset(size.width - length, 0), Offset(size.width, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), p);

    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), p);
    canvas.drawLine(Offset(0, size.height - length), Offset(0, size.height), p);

    canvas.drawLine(
        Offset(size.width - length, size.height), Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, size.height - length),
        Offset(size.width, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) =>
      old.color != color || old.length != length || old.stroke != stroke;
}

class _CapsuleProgress extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
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
                    color: isCurrent
                        ? fill
                        : isDone
                            ? done
                            : track,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      width: double.infinity,
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

class _IdCardLogo extends StatelessWidget {
  final double size;
  const _IdCardLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
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
        const Icon(Icons.credit_card_rounded, color: Colors.white, size: 42),
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