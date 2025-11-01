// lib/features/onboarding/address_info_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/colors.dart';
import '../../models/registration_data.dart';

class AddressInfoPage extends StatefulWidget {
  const AddressInfoPage({super.key});

  @override
  State<AddressInfoPage> createState() => _AddressInfoPageState();
}

class _AddressInfoPageState extends State<AddressInfoPage> {
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postcodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postcodeController.dispose();
    super.dispose();
  }

  void _submitAddress() {
    if (_formKey.currentState!.validate()) {
      RegistrationData.street = streetController.text.trim();
      RegistrationData.city = cityController.text.trim();
      RegistrationData.state = stateController.text.trim();
      RegistrationData.postcode = postcodeController.text.trim();
      context.pushNamed(RouteNames.selfie);
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
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 14),

                        // Capsule progress
                        const _CapsuleProgress(
                          steps: ["Start", "Verify", "Secure"],
                          currentIndex: 2, // same flow level
                        ),
                        const SizedBox(height: 24),

                        const _AddressLogo(size: 84),
                        const SizedBox(height: 10),

                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Enter Your Address',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Provide your current residential details.",
                          style: TextStyle(color: subtle),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 22),

                        _GlassCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel("Street Address"),
                              const SizedBox(height: 8),
                              _FilledField(
                                controller: streetController,
                                hintText: "e.g. 123 Jalan ABC",
                                prefixIcon: Icons.home_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Required field" : null,
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel("City"),
                              const SizedBox(height: 8),
                              _FilledField(
                                controller: cityController,
                                hintText: "e.g. Kuala Lumpur",
                                prefixIcon: Icons.location_city_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Required field" : null,
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel("State"),
                              const SizedBox(height: 8),
                              _FilledField(
                                controller: stateController,
                                hintText: "e.g. Selangor",
                                prefixIcon: Icons.map_outlined,
                                validator: (v) =>
                                    v == null || v.isEmpty ? "Required field" : null,
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel("Postcode"),
                              const SizedBox(height: 8),
                              _FilledField(
                                controller: postcodeController,
                                hintText: "e.g. 47000",
                                prefixIcon: Icons.local_post_office_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return "Required field";
                                  if (!RegExp(r'^\d{5}$').hasMatch(v)) {
                                    return "Invalid postcode";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

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
                            onPressed: _submitAddress,
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
          ),
        ],
      ),
    );
  }
}

/// Reusable filled rounded field
class _FilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _FilledField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: accentColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(prefixIcon, color: Colors.white70),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: accentColor, width: 1.6),
        ),
      ),
    );
  }
}

/// Field label
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

/// Glass container
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
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Progress capsule (same style as IC verification)
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

/// Address icon
class _AddressLogo extends StatelessWidget {
  final double size;
  const _AddressLogo({required this.size});

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
        const Icon(Icons.location_on_outlined, color: Colors.white, size: 42),
      ],
    );
  }
}

/// Background glow blobs
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