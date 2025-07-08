import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/welcome_page.dart';
import 'features/dashboard/dashboard_page.dart'; // Replace with your actual home page

void main() {
  runApp(NexPayApp());
}

class NexPayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexPay',
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return DashboardPage(); // Navigate to home if logged in
        } else {
          return WelcomePage(); // Else show onboarding
        }
      },
    );
  }
}
