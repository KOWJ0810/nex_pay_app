// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';

import 'firebase_options.dart';
import 'package:nex_pay_app/router.dart' show rootNavigatorKey, appRouter, RouteNames;
import 'features/auth/app_lock_gate.dart';

import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Stripe.publishableKey =
      'pk_test_51RsIOV2zHCnMrgzi3rmJo62TK9ZWWTTLOMu77vKhzBb6YMXYKxOtcAkTq8BdzyizNxI3yVWRr4uwMmHHr9l42Xeo00xejQkbbd';

  runApp(const NexPayApp());
}

class NexPayApp extends StatefulWidget {
  const NexPayApp({super.key});
  @override
  State<NexPayApp> createState() => NexPayAppState();
}

class NexPayAppState extends State<NexPayApp> {
  StreamSubscription? _sub;
  Timer? clipboardTimer;

  String lastDetectedLink = "";

  /// ⭐ NEW: Permanently ignored links (merchant copied links)
  Set<String> ignoredLinks = {};

  @override
  void initState() {
    super.initState();
    _startClipboardListener();
  }


  void _handleUri(Uri uri) async {
    // nexpay://pay?to=plink_xxx
    if (uri.scheme == "nexpay" && uri.host == "pay") {
      final storage = secureStorage;
      final loginToken = await storage.read(key: "token");
      if (loginToken == null || loginToken.isEmpty) return;

      final token = uri.queryParameters["to"];
      if (token != null) {
        rootNavigatorKey.currentContext?.pushNamed(
          RouteNames.paymentLinkPreview,
          extra: {"token": token},
        );
      }
    }
  }

  // ============================================================
  // 📋 Clipboard listener (only detect *user* clicked links)
  // ============================================================
  void _startClipboardListener() {
    clipboardTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      ClipboardData? data = await Clipboard.getData("text/plain");
      if (data == null) return;

      final text = data.text ?? "";

      // Skip merchant-copied links forever
      if (ignoredLinks.contains(text)) return;

      // Only detect nexpay://pay links
      if (!text.startsWith("nexpay://pay")) return;

      // Avoid showing popup twice for same link
      if (lastDetectedLink == text) return;
      lastDetectedLink = text;

      final uri = Uri.tryParse(text);
      final token = uri?.queryParameters["to"];
      if (token == null) return;

      // If user not logged in, do not show popup
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (!isLoggedIn) return;

      _showPaymentPopup(token);
    });
  }

  // ============================================================
  // ❗ Allow merchant page to call this when copying link
  // ============================================================
  void ignoreForever(String link) {
    ignoredLinks.add(link);
  }

  // ============================================================
  // Popup asking "Open payment request?"
  // ============================================================
  void _showPaymentPopup(String token) {
    if (rootNavigatorKey.currentState == null) return;

    showDialog(
      context: rootNavigatorKey.currentState!.overlay!.context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Payment Link Detected"),
          content: const Text("Would you like to open the payment request?"),
          actions: [
            TextButton(
              child: const Text("Ignore"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Open"),
              onPressed: () {
                Navigator.pop(context);
                rootNavigatorKey.currentContext?.pushNamed(
                  RouteNames.paymentLinkPreview,
                  extra: {"token": token},
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // Cleanup
  // ============================================================
  @override
  void dispose() {
    _sub?.cancel();
    clipboardTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // App Root
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NexPay',
      routerConfig: appRouter,
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}