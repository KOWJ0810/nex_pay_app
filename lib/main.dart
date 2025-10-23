import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this
import 'features/onboarding/welcome_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before Firebase.init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );// Firebase initialization

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  Stripe.publishableKey = 'pk_test_51RsIOV2zHCnMrgzi3rmJo62TK9ZWWTTLOMu77vKhzBb6YMXYKxOtcAkTq8BdzyizNxI3yVWRr4uwMmHHr9l42Xeo00xejQkbbd';
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
    return false;
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
          return DashboardPage(); // Go to dashboard if logged in
        } else {
          return WelcomePage(); // Go to onboarding if not logged in
        }
      },
    );
  }
}
