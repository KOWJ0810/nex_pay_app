// lib/features/onboarding/welcome_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing wallet logo
                      const _WalletLogo(size: 130),
                      const SizedBox(height: 28),

                      const Text(
                        'Welcome to',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Gradient NexPay text
                      ShaderMask(
                        shaderCallback: (Rect bounds) => const LinearGradient(
                          colors: [Color(0xFFB8E986), Color(0xFF78D64B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'NexPay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Your journey to effortless e-wallet payments starts here.',
                        style: TextStyle(color: subtle, fontSize: 16, height: 1.35),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 30),

                      // Features card
                      const _GlassCard(
                        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FeatureChip(icon: Icons.lock_outline, label: 'Bank-grade Security'),
                            _FeatureChip(icon: Icons.bolt_outlined, label: 'Fast Top-ups'),
                            _FeatureChip(icon: Icons.qr_code_scanner, label: 'QR Payments'),
                            _FeatureChip(icon: Icons.insights_outlined, label: 'Smart Insights'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Glowing CTA Button
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed('contact-info'),
                          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                          label: const Text(
                            'Get Started',
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

                      const SizedBox(height: 16),

                      // Login link
                      GestureDetector(
                        onTap: () => context.pushNamed('login'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Have an account? ',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: accentColor,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: bottomInset > 0 ? bottomInset + 8 : 8),
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

/// ✅ Glowing wallet icon
class _WalletLogo extends StatelessWidget {
  final double size;
  const _WalletLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.5),
                blurRadius: 45,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        // Main circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withOpacity(0.35),
                accentColor.withOpacity(0.15),
                accentColor.withOpacity(0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: accentColor.withOpacity(0.6), width: 3),
          ),
        ),
        // Wallet icon
        Icon(
          Icons.account_balance_wallet_outlined,
          color: Colors.white,
          size: size * 0.52,
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ],
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
        borderRadius: BorderRadius.circular(24),
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

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _blob(accentColor.withOpacity(0.25), 260)),
          Positioned(bottom: -100, left: -60, child: _blob(Colors.white.withOpacity(0.08), 280)),
          Positioned(top: 220, left: -50, child: _blob(accentColor.withOpacity(0.1), 200)),
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