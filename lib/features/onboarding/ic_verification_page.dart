// lib/features/onboarding/ic_verification_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';

class ICVerificationPage extends StatefulWidget {
  const ICVerificationPage({super.key});

  @override
  State<ICVerificationPage> createState() => _ICVerificationPageState();
}

class _ICVerificationPageState extends State<ICVerificationPage> {
  File? icImage;
  String detectedName = '';
  String detectedIC = '';
  List<String> excludedKeywords = [];
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadExcludedKeywords();
  }

  Future<void> _loadExcludedKeywords() async {
    try {
      final content = await rootBundle.loadString('assets/excluded_words.txt');
      final lines = content
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      setState(() => excludedKeywords = lines);
    } catch (_) {
      excludedKeywords = [];
    }
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      setState(() => icImage = imageFile);
      await _extractTextFromImage(imageFile);
    }
  }
  // Text Extraction Using Google ML Kit
  Future<void> _extractTextFromImage(File imageFile) async {
    setState(() => _processing = true);
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      // Detect IC number
      final icRegex = RegExp(r'\d{6}-\d{2}-\d{4}|\d{12}');
      final icMatch = icRegex.firstMatch(fullText);

      // Probable name: uppercase, no digits, not keyword
      final nameMatch = recognizedText.blocks
          .expand((b) => b.lines)
          .where((line) {
            final text = line.text.trim();
            final upperNoSpace = text.toUpperCase().replaceAll(' ', '');
            final isLetters = RegExp(r'^[A-Z\s]{6,}$').hasMatch(text);
            final hasNoDigits = !RegExp(r'\d').hasMatch(text);
            final notKeyword = !excludedKeywords.any(
              (kw) => upperNoSpace.contains(kw.toUpperCase().replaceAll(' ', '')),
            );
            final tallEnough = line.boundingBox.height > 24;
            return isLetters && hasNoDigits && notKeyword && tallEnough;
          })
          .map((line) => line.text.trim())
          .cast<String?>()
          .firstWhere((_) => true, orElse: () => '');

      setState(() {
        detectedIC = icMatch?.group(0) ?? '';
        detectedName = nameMatch ?? '';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to read IC. Please try again.")),
        );
      }
    } finally {
      await textRecognizer.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  void _goToConfirmPage() {
    if (icImage == null || detectedIC.isEmpty || detectedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please capture a clear IC and ensure details are detected."),
        ),
      );
      return;
    }

    context.goNamed(
      'ic-back-capture',
      extra: {
        'fullName': detectedName,
        'icNumber': detectedIC,
        'frontImage': icImage,
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
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Capture Your IC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Make sure your card is inside the frame, well-lit, and readable.",
                        style: TextStyle(color: subtle),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),

                      // Capture card
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Take a photo of your IC",
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
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.06),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: icImage == null
                                            ? const Center(
                                                child: Icon(
                                                  Icons.credit_card,
                                                  color: Colors.white70,
                                                  size: 56,
                                                ),
                                              )
                                            : Image.file(
                                                icImage!,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: _CornersOverlay(
                                        color: accentColor.withOpacity(0.7),
                                      ),
                                    ),
                                    if (icImage != null)
                                      Positioned(
                                        right: 10,
                                        top: 10,
                                        child: TextButton.icon(
                                          onPressed: _openCamera,
                                          icon: const Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Retake",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.black.withOpacity(0.35),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (icImage == null)
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            onTap: _openCamera,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Info
                            Row(
                              children: const [
                                Expanded(
                                  child: _TipChip(
                                    icon: Icons.light_mode_outlined,
                                    text: "Good lighting",
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _TipChip(
                                    icon: Icons.grid_on_outlined,
                                    text: "Align within frame",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Spacer(),
                                Expanded(
                                  flex: 3,
                                  child: _TipChip(
                                    icon: Icons.clear_all,
                                    text: "Avoid reflections",
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),

                            const SizedBox(height: 12),
                            // Capture button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openCamera,
                                icon: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.black),
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

                      // Next button
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
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
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
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle corners overlay to guide framing
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
  _CornersPainter(
      {required this.color, required this.length, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(length, 0), p);
    canvas.drawLine(Offset(0, 0), Offset(0, length), p);

    // Top-right
    canvas.drawLine(Offset(size.width - length, 0), Offset(size.width, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), p);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), p);
    canvas.drawLine(Offset(0, size.height - length), Offset(0, size.height), p);

    // Bottom-right
    canvas.drawLine(Offset(size.width - length, size.height),
        Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, size.height - length),
        Offset(size.width, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.length != length ||
      oldDelegate.stroke != stroke;
}

/// Capsule progress show the 3 steps
class _CapsuleProgress extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;
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

/// Glass card
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

/// Glowing ID logo
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
        const Icon(Icons.perm_identity_rounded, color: Colors.white, size: 42),
      ],
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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