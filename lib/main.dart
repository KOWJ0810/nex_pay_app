import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nex_pay_app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  Stripe.publishableKey = 'pk_test_51RsIOV2zHCnMrgzi3rmJo62TK9ZWWTTLOMu77vKhzBb6YMXYKxOtcAkTq8BdzyizNxI3yVWRr4uwMmHHr9l42Xeo00xejQkbbd';

  runApp(const NexPayApp());
}

class NexPayApp extends StatelessWidget {
  const NexPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NexPay',
      routerConfig: appRouter, // <-- router drives the app
    );
  }
}