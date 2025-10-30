// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/features/account/account_page.dart';
import 'package:nex_pay_app/features/account/trusted_devices_page.dart';
import 'package:nex_pay_app/features/auth/device_takeover_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PAGES
import 'features/dashboard/dashboard_page.dart';
import 'features/onboarding/welcome_page.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/contact_info_page.dart';
// TODO: replace with your real import/signature if needed
// import 'features/auth/device_takeover_page.dart';

class RouteNames {
  static const splash = 'splash';
  static const welcome = 'welcome';
  static const home = 'home';
  static const takeover = 'takeover';
  static const login = 'login';
  static const contactInfo = 'contact-info';
  static const account = 'account';
  static const trustedDevices = 'trusted-devices';
}

/// GoRouter instance
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      name: RouteNames.splash,
      path: '/splash',
      pageBuilder: (ctx, st) => _fade(const SplashPage()),
    ),
    GoRoute(
      name: RouteNames.welcome,
      path: '/welcome',
      pageBuilder: (ctx, st) => _fade(WelcomePage()),
    ),
    GoRoute(
      name: RouteNames.home,
      path: '/',
      pageBuilder: (ctx, st) => _fade(const DashboardPage()),
    ),
    GoRoute(
      name: RouteNames.takeover,
      path: '/takeover',
      pageBuilder: (ctx, st) {
        final args = st.extra as TakeoverArgs; // we'll define this model
        return _fade(
          DeviceTakeoverPage(
            phoneNum: args.phoneNum,
            userId: args.userId,
          ),
        );
      },
    ),
    GoRoute(
      name: RouteNames.login,
      path: '/login',
      pageBuilder: (ctx, st) => _fade(LoginPage()),
    ),
    GoRoute(
      name: RouteNames.contactInfo,
      path: '/contact-info',
      pageBuilder: (ctx, st) => _fade(ContactInfoPage()),
    ),
    GoRoute(
      name: RouteNames.account,
      path: '/account',
      pageBuilder: (ctx, st) => _fade(AccountPage()),
    ),
    GoRoute(
      name: RouteNames.trustedDevices,
      path: '/trusted-devices',
      pageBuilder: (ctx, st) => _fade(const TrustedDevicesPage()),
    ),
  ],
);

/// Shared fade transition
CustomTransitionPage _fade(Widget child) => CustomTransitionPage(
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: child,
          ),
    );

/// Minimal splash that decides where to go
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
    final loggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!mounted) return;
    if (loggedIn) {
      context.goNamed(RouteNames.home);
    } else {
      context.goNamed(RouteNames.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}