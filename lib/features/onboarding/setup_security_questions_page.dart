// lib/features/onboarding/setup_security_questions_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../models/registration_data.dart'; 
import '../../router.dart' show RouteNames;

class SetupSecurityQuestionsPage extends StatefulWidget {
  const SetupSecurityQuestionsPage({Key? key}) : super(key: key);

  @override
  State<SetupSecurityQuestionsPage> createState() =>
      _SetupSecurityQuestionsPageState();
}

class _SetupSecurityQuestionsPageState
    extends State<SetupSecurityQuestionsPage> {
  final _formKey = GlobalKey<FormState>();

  // Neutral & memorable
  static const List<String> _questions = [
    "What is the name of your first school?",
    "What is your favourite childhood game?",
    "What city were you born in?",
    "What is your favourite teacher’s name?",
    "What is your favourite local food?",
    "What is the name of your first pet?",
    "What street did you grow up on?",
    "What is your dream travel destination?",
    "What is your favourite sports team?",
    "What is your father's birthplace?",
    "What is your mother's birthplace?",
  ];

  String? _q1;
  String? _q2;

  final TextEditingController _a1 = TextEditingController();
  final TextEditingController _a2 = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _a1.dispose();
    _a2.dispose();
    super.dispose();
  }

  String? _validateQuestionPair() {
    if (_q1 == null || _q2 == null) return "Please select two questions";
    if (_q1 == _q2) return "Questions must be different";
    return null;
  }

  String? _validateAnswer(String? value, {required String which}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return "Answer for $which is required";
    if (v.length < 3) return "Answer for $which must be at least 3 characters";
    final q = which == "Question 1" ? (_q1 ?? "") : (_q2 ?? "");
    if (q.isNotEmpty && v.toLowerCase() == q.toLowerCase()) {
      return "Answer cannot be the same as the question";
    }
    return null;
  }

  Future<void> _onContinue() async {
    final pairErr = _validateQuestionPair();
    if (pairErr != null) {
      _showSnack(pairErr);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      // Push into RegistrationData model for the createUser API
      RegistrationData.securityQuestions = [
        SecurityQuestion(question: _q1!.trim(), answer: _a1.text.trim()),
        SecurityQuestion(question: _q2!.trim(), answer: _a2.text.trim()),
      ];

      if (!mounted) return;
      context.pushNamed(RouteNames.setupPin);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                        currentIndex: 3,
                      ),

                      const SizedBox(height: 24),

                      const _ShieldLogo(size: 84),
                      const SizedBox(height: 10),

                     
                      Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            "Set Up Security Questions",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Choose two questions and answers only you know. "
                        "Used to help recover your account.",
                        style: TextStyle(color: subtle),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      // Info Card
                      _GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.18),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: Colors.white70, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Avoid using information that could be guessed or found online. "
                                "Add a small twist only you remember (e.g., add a year or inside joke).",
                                style: TextStyle(color: subtle, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Form Card
                      _GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const _LabelWithChip(label: "Question 1", chip: "Required"),
                              const SizedBox(height: 8),
                              _modernDropdown(
                                value: _q1,
                                items: _questions,
                                onChanged: (v) => setState(() => _q1 = v),
                                validator: (_) => _validateQuestionPair() == null ? null : "",
                              ),
                              const SizedBox(height: 12),
                              _modernTextField(
                                controller: _a1,
                                hint: "Your answer",
                                validator: (v) => _validateAnswer(v, which: "Question 1"),
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: Colors.white24, height: 1),
                              const SizedBox(height: 20),

                              const _LabelWithChip(label: "Question 2", chip: "Required"),
                              const SizedBox(height: 8),
                              _modernDropdown(
                                value: _q2,
                                items: _questions,
                                onChanged: (v) => setState(() => _q2 = v),
                                validator: (_) => _validateQuestionPair() == null ? null : "",
                              ),
                              const SizedBox(height: 12),
                              _modernTextField(
                                controller: _a2,
                                hint: "Your answer",
                                validator: (v) => _validateAnswer(v, which: "Question 2"),
                              ),

                              const SizedBox(height: 10),

                              // Inline pair error 
                              Builder(
                                builder: (_) {
                                  final err = _validateQuestionPair();
                                  if (err == null) return const SizedBox.shrink();
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      err,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Continue
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
                          onPressed: _saving ? null : _onContinue,
                          icon: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.black),
                          label: Text(
                            _saving ? "Saving..." : "Continue",
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

  // UI Elements

  Widget _modernDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: primaryColor,
      iconEnabledColor: accentColor,
      style: const TextStyle(color: Colors.white),
      menuMaxHeight: 340,
      borderRadius: BorderRadius.circular(14),

      hint: const Text(
        "Select a question",
        style: TextStyle(color: Colors.white),
      ),

      decoration: _fieldDecoration(
        prefixIcon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
      ),

      items: items
          .map(
            (q) => DropdownMenuItem<String>(
              value: q,
              child: Text(
                q,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),

      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: accentColor, 
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(
        hint: hint,
        prefixIcon: const Icon(Icons.edit_outlined, color: Colors.white70),
      ),
      validator: validator,
      textInputAction: TextInputAction.done,
    );
  }

  InputDecoration _fieldDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 1.8),
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
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
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabelWithChip extends StatelessWidget {
  final String label;
  final String? chip;
  const _LabelWithChip({required this.label, this.chip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.security_outlined, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (chip != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Text(
              chip!,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

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
        const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 42),
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