// lib/features/onboarding/confirm_ic_info_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../models/registration_data.dart';
import '../../router.dart';

/// Uppercase input (kept from your version)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Auto-format IC number as XXXXXX-XX-XXXX while typing
class ICNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only digits
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Cap at 12 digits
    if (digits.length > 12) digits = digits.substring(0, 12);

    // Build formatted
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i == 5 || i == 7) buf.write('-'); // after 6th and 8th digit
    }
    final formatted = buf.toString();

    // Keep caret at end (simple + reliable for OTP-like entry)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ConfirmICInfoPage extends StatefulWidget {
  final String fullName;
  final String icNumber;
  final File icImage;
  final File icBackImage;

  const ConfirmICInfoPage({
    super.key,
    required this.fullName,
    required this.icNumber,
    required this.icImage,
    required this.icBackImage,
  });

  @override
  State<ConfirmICInfoPage> createState() => _ConfirmICInfoPageState();
}

class _ConfirmICInfoPageState extends State<ConfirmICInfoPage> {
  late TextEditingController nameController;
  late TextEditingController icController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.fullName);
    // Normalize incoming IC to dashed format once at init
    icController = TextEditingController(
      text: _formatInitialIC(widget.icNumber),
    );
  }

  String _formatInitialIC(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      if (i == 5 || i == 7) buf.write('-');
    }
    return buf.toString();
  }

  @override
  void dispose() {
    nameController.dispose();
    icController.dispose();
    super.dispose();
  }

  void _onNext() {
    RegistrationData.fullName = nameController.text.trim();
    // Store as digits-only (clean) OR keep dashed—choose one. Here we keep dashed for readability:
    RegistrationData.icNum = icController.text.trim();
    RegistrationData.icFrontImage = widget.icImage;
    RegistrationData.icBackImage = widget.icBackImage;

    context.pushNamed(RouteNames.addressInfo);
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

                      // Capsule progress — still "Step 2" in overall flow (no explicit Step label)
                      const _CapsuleProgress(
                        steps: ["Start", "Verify", "Secure"],
                        currentIndex: 2, // still at step 2
                      ),

                      const SizedBox(height: 24),

                      const _IdCardLogo(size: 84),
                      const SizedBox(height: 10),

                      // Gradient title
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Confirm Your IC Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Double-check and edit if needed before continuing.",
                        style: TextStyle(color: subtle),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      // Form Card
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Full Name (as per IC)'),
                            const SizedBox(height: 8),
                            _FilledField(
                              controller: nameController,
                              hintText: "e.g. LEE HONG WEI",
                              inputFormatters: [UpperCaseTextFormatter()],
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel('IC Number'),
                            const SizedBox(height: 8),
                            _FilledField(
                              controller: icController,
                              hintText: "e.g. 040303-09-8765",
                              prefixIcon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [ICNumberFormatter()],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Images card
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('IC Images'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _ImagePreview(
                                    title: "Front",
                                    image: widget.icImage,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ImagePreview(
                                    title: "Back",
                                    image: widget.icBackImage,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Continue CTA
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
                          onPressed: _onNext,
                          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                          label: const Text(
                            "Next",
                            style: TextStyle(
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

/// Label style above inputs
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14.5,
      ),
    );
  }
}

/// Filled rounded input used across onboarding
class _FilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FilledField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.prefixIcon,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
    );

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      cursorColor: accentColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: accentColor, width: 1.6),
        ),
      ),
    );
  }
}

/// Preview each IC image with caption
class _ImagePreview extends StatelessWidget {
  final String title;
  final File image;

  const _ImagePreview({required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    final chipBg = Colors.white.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.file(image, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

/// Capsule Step Progress Bar (no explicit "Step X" label)
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
              final isDone = i < currentIndex - 1;     // completed before current step
              final isCurrent = i == currentIndex - 1; // current step (1-indexed visual)
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

/// Glass card container
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

/// Glowing ID logo (for title area)
class _IdCardLogo extends StatelessWidget {
  final double size;
  const _IdCardLogo({required this.size});

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
        // Circle w/ border
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
        const Icon(Icons.verified_user_outlined, color: Colors.white, size: 42),
      ],
    );
  }
}

/// Soft background blobs
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