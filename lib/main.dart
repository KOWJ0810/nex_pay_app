// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'package:nex_pay_app/router.dart';
// adjust the path if different:
import 'features/auth/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Stripe.publishableKey =
      'pk_test_51RsIOV2zHCnMrgzi3rmJo62TK9ZWWTTLOMu77vKhzBb6YMXYKxOtcAkTq8BdzyizNxI3yVWRr4uwMmHHr9l42Xeo00xejQkbbd';

  runApp(const NexPayApp());
}

class NexPayApp extends StatelessWidget {
  const NexPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NexPay',
      routerConfig: appRouter,
      // ⬇️ Wrap the rendered child with AppLockGate so Directionality already exists
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}