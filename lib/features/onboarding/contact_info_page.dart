// lib/features/onboarding/contact_info_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../models/registration_data.dart';
import '../../router.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String validationErrorEmail = '';
  String validationErrorPhone = '';
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSendOTP() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    setState(() {
      isLoading = true;
      validationErrorEmail = '';
      validationErrorPhone = '';
    });

    try {
      // Validate format
      final validationResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/validateContact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'phoneNum': phone}),
      );

      if (validationResponse.statusCode != 200) {
        final error = validationResponse.body.toLowerCase();

        setState(() {
          validationErrorEmail = '';
          validationErrorPhone = '';
          if (error.contains("email") && error.contains("phone")) {
            validationErrorEmail = "Invalid email format.";
            validationErrorPhone = "Invalid Malaysian phone number format.";
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid phone format.")),
            );
          } else if (error.contains("email")) {
            validationErrorEmail = "Invalid email format.";
          } else if (error.contains("phone")) {
            validationErrorPhone = "Invalid Malaysian phone number format.";
          } else {
            validationErrorEmail = error;
          }
        });

        setState(() => isLoading = false);
        return;
      }

      // Check phone duplication
      final phoneCheckUri = Uri.parse('${ApiConfig.baseUrl}/users/checkPhone')
          .replace(queryParameters: {'phoneNum': phone});

      final phoneCheckResponse = await http.get(
        phoneCheckUri,
        headers: {'Accept': 'application/json'},
      );

      if (phoneCheckResponse.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(phoneCheckResponse.body);
        final bool duplicate = body['duplicate'] == true;
        final bool success   = body['success'] == true;

        if (!success) {
          setState(() {
            validationErrorPhone = body['message']?.toString() ?? 'Error checking phone number';
            isLoading = false;
          });
          return;
        }

        if (duplicate) {
          setState(() {
            validationErrorPhone = "Phone number already in use";
            isLoading = false;
          });
          return;
        }
      } else {
        setState(() {
          validationErrorPhone = "Error checking phone number (${phoneCheckResponse.statusCode})";
          isLoading = false;
        });
        return;
      }

      // Send OTP
      final otpResponse = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (otpResponse.statusCode == 200) {
        RegistrationData.email = email;
        RegistrationData.phoneNum = phone;

        context.goNamed(
          RouteNames.emailVerification,
          extra: {'email': email},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                        currentIndex: 0,
                      ),

                      const SizedBox(height: 26),

                      // Header (icon + title)
                      const _WalletLogo(size: 86),
                      const SizedBox(height: 12),
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Contact Info',
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
                        "We’ll send a verification code to your email.",
                        style: TextStyle(color: subtle, fontSize: 14.5),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 22),

                      // Form card
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Phone Number",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _PhoneField(
                              controller: phoneController,
                              errorText: validationErrorPhone.isEmpty ? null : validationErrorPhone,
                            ),

                            const SizedBox(height: 18),

                            const Text("Email",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _FilledField(
                              controller: emailController,
                              hintText: "e.g. johndoe@email.com",
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.alternate_email_rounded,
                              errorText: validationErrorEmail.isEmpty ? null : validationErrorEmail,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      
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
                          onPressed: isLoading ? null : _validateAndSendOTP,
                          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                          label: Text(
                            isLoading ? "Please wait..." : "Next",
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

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.45),
              alignment: Alignment.center,
              child: const SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
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

/// Phone field with phone icon
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const _PhoneField({
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
    );

    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white),
      cursorColor: accentColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: "e.g. 0123456789",
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: const Icon(Icons.phone_rounded, color: Colors.white70),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: accentColor, width: 1.6),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
      ),
    );
  }
}

class _FilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? errorText;

  const _FilledField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.prefixIcon,
    this.errorText,
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
      style: const TextStyle(color: Colors.white),
      cursorColor: accentColor,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: Colors.white70)
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: BorderSide(color: accentColor, width: 1.6),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
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
        // Icon
        const Icon(
          Icons.account_balance_wallet_outlined,
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