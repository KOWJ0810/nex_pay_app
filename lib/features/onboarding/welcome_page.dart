/// File: lib/features/onboarding/welcome_page.dart
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'contact_info_page.dart';
import '../auth/login_page.dart';
import '../../router.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 3, color: accentColor),
                SizedBox(width: 10),
                Container(width: 80, height: 3, color: Colors.grey[400]),
                SizedBox(width: 10),
                Container(width: 80, height: 3, color: Colors.grey[400]),
              ],
            ),
            Spacer(),
            Icon(Icons.account_balance_wallet_outlined, size: 120, color: accentColor),
            SizedBox(height: 40),
            Text(
              'Welcome To',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'NexPay',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Your journey to effortless e-wallet payment starts here. We’re thrilled to have you on board!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton(
                onPressed: () {
                    context.push('/contact-info');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                context.push('/login');
              },
              child: RichText(
                text: TextSpan(
                  text: 'Have an account? ',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(color: accentColor, decoration: TextDecoration.underline),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
