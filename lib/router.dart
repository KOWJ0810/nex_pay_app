// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/features/onboarding/biometric_opt_in_page.dart';
import 'package:nex_pay_app/features/onboarding/setup_security_questions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ========= Auth & Onboarding =========
import 'package:nex_pay_app/features/auth/login_page.dart';
import 'package:nex_pay_app/features/onboarding/email_verification_page.dart';
import 'package:nex_pay_app/features/auth/device_takeover_page.dart';

import 'package:nex_pay_app/features/onboarding/welcome_page.dart';
import 'package:nex_pay_app/features/onboarding/contact_info_page.dart';
import 'package:nex_pay_app/features/onboarding/ic_verification_page.dart';
import 'package:nex_pay_app/features/onboarding/ic_back_capture_page.dart';
import 'package:nex_pay_app/features/onboarding/confirm_ic_info_page.dart';
import 'package:nex_pay_app/features/onboarding/selfie_page.dart';
import 'package:nex_pay_app/features/onboarding/address_info_page.dart';
import 'package:nex_pay_app/features/onboarding/setup_pin_page.dart';
import 'package:nex_pay_app/features/onboarding/confirm_pin_page.dart';
import 'package:nex_pay_app/features/onboarding/success_page.dart';

// ========= App =========
import 'package:nex_pay_app/features/dashboard/dashboard_page.dart';
import 'package:nex_pay_app/features/account/account_page.dart';
import 'package:nex_pay_app/features/account/trusted_devices_page.dart';
import 'package:nex_pay_app/features/topup/top_up_success_page.dart';

class RouteNames {
  static const splash = 'splash';
  static const welcome = 'welcome';
  static const home = 'home';
  static const login = 'login';
  static const contactInfo = 'contact-info';
  static const emailVerification = 'email-verification';

  static const icVerification = 'ic-verification';
  static const icBackCapture = 'ic-back-capture';
  static const confirmICInfo = 'confirm-ic-info';
  static const selfie = 'selfie';
  static const addressInfo = 'address-info';
  static const setupSecurityQuestions = 'setup-security-questions';
  static const setupPin = 'setup-pin';
  static const confirmPin = 'confirm-pin';
  static const registerSuccess = 'register-success';
  static const enableBiometric = 'enable-biometric';

  static const account = 'account';
  static const trustedDevices = 'trusted-devices';
  static const takeover = 'takeover';
  static const topUpSuccess = 'topup-success';

}

/// (Optional) args holder used by takeover route
class TakeoverArgs {
  final String phoneNum;
  final int userId;
  const TakeoverArgs({required this.phoneNum, required this.userId});
}

final GoRouter appRouter = GoRouter(
  // Start here; Splash will immediately route to the proper place.
  initialLocation: '/splash',

  // IMPORTANT: No global redirect. Keep navigation simple during registration.
  routes: [
    // ===== Splash (decides where to go ONCE) =====
    GoRoute(
      name: RouteNames.splash,
      path: '/splash',
      builder: (ctx, st) => const SplashPage(),
    ),

    // ===== Public: Welcome & Login & Contact Info =====
    GoRoute(
      name: RouteNames.welcome,
      path: '/welcome',
      builder: (ctx, st) => WelcomePage(),
    ),
    GoRoute(
      name: RouteNames.login,
      path: '/login',
      builder: (ctx, st) => const LoginPage(),
    ),
    GoRoute(
      name: RouteNames.contactInfo,
      path: '/contact-info',
      builder: (ctx, st) => ContactInfoPage(),
    ),
    GoRoute(
      name: RouteNames.emailVerification,
      path: '/email-verification',
      builder: (ctx, st) {
        // Optional email passed via extra
        final extra = st.extra as Map<String, dynamic>?;
        final email = extra?['email'] as String? ?? '';
        return EmailVerificationPage(email: email);
      },
    ),

    // ===== Onboarding flow =====
    GoRoute(
      name: RouteNames.icVerification,
      path: '/ic-verification',
      builder: (ctx, st) => ICVerificationPage(),
    ),
    GoRoute(
      name: RouteNames.icBackCapture,
      path: '/ic-back-capture',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ICBackCapturePage(
          fullName: extras['fullName'],
          icNumber: extras['icNumber'],
          frontImage: extras['frontImage'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.confirmICInfo,
      path: '/confirm-ic-info',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ConfirmICInfoPage(
          fullName: extras['fullName'],
          icNumber: extras['icNumber'],
          icImage: extras['icImage'],
          icBackImage: extras['icBackImage'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.selfie,
      path: '/selfie',
      builder: (ctx, st) => SelfiePage(),
    ),
    GoRoute(
      name: RouteNames.addressInfo,
      path: '/address-info',
      builder: (ctx, st) => AddressInfoPage(),
    ),
    GoRoute(
      name: RouteNames.setupPin,
      path: '/setup-pin',
      builder: (ctx, st) => SetupPinPage(),
    ),
    GoRoute(
      name: RouteNames.confirmPin,
      path: '/confirm-pin',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ConfirmPinPage(originalPin: extras['originalPin']);
      },
    ),
    GoRoute(
      name: RouteNames.registerSuccess,
      path: '/register-success',
      builder: (ctx, st) => const SuccessPage(),
    ),

    // ===== App =====
    GoRoute(
      name: RouteNames.home,
      path: '/',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: DashboardPage()),
    ),
    GoRoute(
      name: RouteNames.account,
      path: '/account',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: AccountPage()),
    ),
    GoRoute(
      name: RouteNames.trustedDevices,
      path: '/trusted-devices',
      builder: (ctx, st) => const TrustedDevicesPage(),
    ),
    GoRoute(
      name: RouteNames.takeover,
      path: '/takeover',
      builder: (ctx, st) {
        final args = st.extra as TakeoverArgs;
        return DeviceTakeoverPage(
          phoneNum: args.phoneNum,
          userId: args.userId,
        );
      },
    ),
    GoRoute(
      name: RouteNames.topUpSuccess,
      path: '/topup-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return TopUpSuccessPage(
          amount: extras['amount'],
          paymentIntentId: extras['paymentIntentId'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.setupSecurityQuestions,
      path: '/setup-security-questions',
      builder: (ctx, st) => const SetupSecurityQuestionsPage(),
    ),
    // router.dart (inside your GoRouter routes)
    GoRoute(
      name: RouteNames.enableBiometric,
      path: '/enable-biometric',
      builder: (context, state) => const BiometricOptInPage(),
    ),
  ],
);

/// Splash decides ONCE where to go based on flags.
/// This will NOT interfere with the rest of the onboarding navigation.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarding_complete') ?? false;

  if (!mounted) return;

  if (onboarded) {
    context.goNamed(RouteNames.home);       // Done → Dashboard
  } else {
    context.goNamed(RouteNames.welcome);    // Not done → Welcome → OTP → IC → ...
  }
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}