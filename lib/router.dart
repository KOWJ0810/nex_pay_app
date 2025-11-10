// lib/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/features/auth/security_fallback_page.dart';
import 'package:nex_pay_app/features/onboarding/biometric_opt_in_page.dart';
import 'package:nex_pay_app/features/onboarding/setup_security_questions_page.dart';
import 'package:nex_pay_app/features/wallet/waiting_transaction_limit_page.dart';
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
import 'package:nex_pay_app/features/topup/top_up_page.dart';
import 'package:nex_pay_app/features/wallet/emergency_wallet_page.dart';
import 'package:nex_pay_app/features/wallet/add_relationship_page.dart';
import 'package:nex_pay_app/features/wallet/receiver_verification_page.dart';
import 'package:nex_pay_app/features/wallet/sender_generate_code_page.dart';
import 'package:nex_pay_app/features/transaction/transaction_history_page.dart';
import 'package:nex_pay_app/features/wallet/receiver_generate_code_page.dart';
import 'package:nex_pay_app/features/wallet/sender_verification_page.dart';
import 'package:nex_pay_app/features/wallet/emerg_transaction_limit_page.dart';
import 'package:nex_pay_app/features/wallet/receiver_success_page.dart';
import 'package:nex_pay_app/features/wallet/sender_success_page.dart';
import 'package:nex_pay_app/features/transfer/search_transfer_user_page.dart';
import 'package:nex_pay_app/features/transfer/enter_amount_page.dart';
import 'package:nex_pay_app/features/transfer/transfer_success_page.dart';
import 'package:nex_pay_app/features/QrCode/receive_qr_code_page.dart';
import 'package:nex_pay_app/features/QrCode/scan_qr_code_page.dart';
import 'package:nex_pay_app/features/paychat/paychat_page.dart';
import 'package:nex_pay_app/features/paychat/chatroom_page.dart';
import 'package:nex_pay_app/features/schedulePayment/schedule_date_page.dart';
import 'package:nex_pay_app/features/schedulePayment/schedule_amount_page.dart';
import 'package:nex_pay_app/features/schedulePayment/schedule_confirm_page.dart';
import 'package:nex_pay_app/features/schedulePayment/schedule_success_page.dart';
import 'package:nex_pay_app/features/schedulePayment/all_schedule_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_list_page.dart';
import 'package:nex_pay_app/features/piggyBank/add_goal_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_success_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_detail_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_save_money_page.dart';
import 'package:nex_pay_app/features/piggyBank/save_money_success_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_history_page.dart';
import 'package:nex_pay_app/features/piggyBank/goal_claim_money_page.dart';
import 'package:nex_pay_app/features/piggyBank/claim_money_success_page.dart';
import 'package:nex_pay_app/features/merchantOnboarding/merchant_register_landing_page.dart';

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
  static const transactionHistory = 'transaction-history';

  static const account = 'account';
  static const trustedDevices = 'trusted-devices';
  static const topUpSuccess = 'topup-success';
  static const takeover = 'takeover';
  static const securityFallback = 'security-fallback';
  static const topUp = 'top-up';
  static const emergencyWallet = 'emergency-wallet';
  static const addRelationship = 'add-relationship';
  static const receiverVerification = 'receiver-verification';
  static const senderGenerateCode = 'sender-generate-code';
  static const receiverGenerateCode = 'receiver-generate-code';
  static const senderVerification = 'sender-verification';
  static const setEmergencyTransactionLimit = 'set-emergency-transaction-limit';
  static const waitingTransactionLimit = 'waiting-transaction-limit';
  static const receiverSuccess = 'receiver-success';
  static const senderSuccess = 'sender-success';
  static const searchTransferUser = 'search-transfer-user';
  static const enterAmount = 'enter-amount';
  static const transferSuccess = 'transfer-success';
  static const receiveQrCode = 'receive-qr-code';
  static const scanQrCode = 'scan-qr-code';
  static const paychat = 'paychat';
  static const chatroom = 'chatroom';
  static const scheduleDate = 'schedule-date';
  static const scheduleAmount = 'schedule-amount';
  static const scheduleConfirm = 'schedule-confirm';
  static const scheduleSuccess = 'schedule-success';
  static const allSchedule = 'all-schedule';
  static const goalList = 'goal-list';
  static const addGoal = 'add-goal';
  static const goalSuccess = 'goal-success';
  static const goalDetail = 'goal-detail';
  static const goalSaveMoney = 'goal-save-money';
  static const saveMoneySuccess = 'save-money-success';
  static const goalHistory = 'goal-history';
  static const goalClaimMoney = 'goal-claim-money';
  static const claimMoneySuccess = 'claim-money-success';
  static const merchantRegisterLanding = 'merchant-register-landing';
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
      name: RouteNames.takeover,
      path: '/takeover',
      builder: (ctx, st) {
        String phoneNum = '';
        int userId = 0;

        final extra = st.extra;

        if (extra is Map) {
          phoneNum = (extra['phoneNum'] ?? '').toString();
          final raw = extra['userId'];
          userId = raw is int ? raw : int.tryParse('$raw') ?? 0;
        } else {
          try {
            final dyn = extra as dynamic;
            phoneNum = (dyn.phoneNum as String?) ?? '';
            userId  = (dyn.userId  as int?)    ?? 0;
          } catch (_) {
            // leave defaults
          }
        }
        return DeviceTakeoverPage(
          phoneNum: phoneNum,
          userId: userId,
        );
      },
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
    GoRoute(
      name: RouteNames.securityFallback,
      path: '/security-fallback',
      builder: (ctx, st) {
        final args = st.extra as SecurityFallbackArgs;
        return SecurityQuestionsFallbackPage(args: args);
      },
    ),
    GoRoute(
      name: RouteNames.topUp,
      path: '/top-up',
      builder: (ctx, st) => const TopUpPage(),
    ),
    GoRoute(
      name: RouteNames.emergencyWallet,
      path: '/emergency-wallet',
      builder: (ctx, st) => const EmergencyWalletPage(),
    ),
    GoRoute(
      name: RouteNames.addRelationship,
      path: '/add-relationship',
      builder: (ctx, st) => const AddRelationshipPage(),
    ),
    GoRoute(
      name: RouteNames.receiverVerification,
      path: '/receiver-verification',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ReceiverVerificationPage(
          phone: extras['phone'],
          userId: extras['userId'] as int,
          userName: extras['userName'],
          pairingId: extras['pairingId'] as int,
          status: extras['status'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.senderGenerateCode,
      path: '/sender-generate-code',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return SenderGenerateCodePage(
          phone: extras['phone'],
          userId: extras['userId'] as int,
          userName: extras['userName'],
          pairingId: extras['pairingId'] as int,
          status: extras['status'],
          firstCode: extras['firstCode'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.transactionHistory,
      path: '/transaction-history',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: TransactionHistoryPage()),
    ),
    GoRoute(
      name: RouteNames.receiverGenerateCode,
      path: '/receiver-generate-code',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>?;
        return ReceiverGenerateCodePage(
          phone: extras?['phone'],
          userId: extras?['userId'] as int?,
          userName: extras?['userName'],
          pairingId: extras?['pairingId'] as int?,
          status: extras?['status'],
          secondCode: extras?['secondCode'],
        );
      },
    ),
    GoRoute(
      name: RouteNames.senderVerification,
      path: '/sender-verification',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return SenderVerificationPage(
          phone: extras['phone'],
          userId: extras['userId'] as int,
          userName: extras['userName'],
          pairingId: extras['pairingId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.setEmergencyTransactionLimit,
      path: '/set-emergency-transaction-limit',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return EmergTransactionLimitPage(
          phone: extras['phone'],
          userId: extras['userId'] as int,
          userName: extras['userName'],
          pairingId: extras['pairingId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.waitingTransactionLimit,
      path: '/waiting-transaction-limit',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return WaitingTransactionLimitPage(
          pairingId: extras['pairingId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.receiverSuccess,
      path: '/receiver-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ReceiverSuccessPage(
          pairingId: extras['pairingId'] as int,
          status: extras['status'],
          maxTotalLimit: extras['maxTotalLimit'] as double,
          perTxnCap: extras['perTxnCap'] as double,
          dailyCap: extras['dailyCap'] as double,
        );
      },
    ),
    GoRoute(
      name: RouteNames.senderSuccess,
      path: '/sender-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return SenderSuccessPage(
          pairingId: extras['pairingId'] as int,
          maxTotalLimit: extras['maxTotalLimit'] as double,
          perTxnCap: extras['perTxnCap'] as double,
          dailyCap: extras['dailyCap'] as double,
        );
      },
    ),
    GoRoute(
      name: RouteNames.searchTransferUser,
      path: '/search-transfer-user',
      builder: (ctx, st) => const SearchTransferUserPage(),
    ),
    GoRoute(
      name: RouteNames.enterAmount,
      path: '/enter-amount',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return EnterAmountPage(
          userId: extras['user_id'] as int,
          userName: extras['user_name'] as String,
          phoneNum: extras['phoneNum'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.transferSuccess,
      path: '/transfer-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return TransferSuccessPage(
          transactionId: extras['transactionId'] as int,
          transactionRefNum: extras['transactionRefNum'] as String,
          amount: extras['amount'] as double,
          fromUserId: extras['fromUserId'] as int,
          toUserId: extras['toUserId'] as int,
          timestamp: extras['timestamp'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.receiveQrCode,
      path: '/receive-qr-code',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ReceiveQrCodePage(
          payload: extras['payload'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scanQrCode,
      path: '/scan-qr-code',
      builder: (ctx, st) => const ScanQrCodePage(),
    ),
    // ===== PayChat (placeholder) =====
    GoRoute(
      name: RouteNames.paychat,
      path: '/paychat',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: PayChatPage()),
    ),
    GoRoute(
      name: RouteNames.chatroom,
      path: '/chatroom',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ChatRoomPage(
          userId: extras['user_id'] as int,
          userName: extras['user_name'] as String,
          chatroomId: extras['chatroom_id'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scheduleDate,
      path: '/schedule-date',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ScheduleDatePage(
          userId: extras['user_id'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scheduleAmount,
      path: '/schedule-amount',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ScheduleAmountPage(
          userId: extras['user_id'] as int,
          userName: extras['user_name'] as String,
          phoneNo: extras['phone_no'] as String,
          startDate: DateTime.parse(extras['start_date'] as String),
          frequency: extras['frequency'] as String,
          endDate: extras['end_date'] != null
      ? DateTime.parse(extras['end_date'] as String)
      : null,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scheduleConfirm,
      path: '/schedule-confirm',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ScheduleConfirmPage(
          userId: extras['user_id'] as int,
          userName: extras['user_name'] as String,
          phoneNo: extras['phone_no'] as String,
          startDate: extras['start_date'] as DateTime, 
          frequency: extras['frequency'] as String,
          amount: extras['amount'] as double,
          endDate: extras['end_date'] as DateTime?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scheduleSuccess,
      path: '/schedule-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ScheduleSuccessPage(
          userId: extras['user_id'] as int,
          userName: extras['user_name'] as String,
          phoneNo: extras['phone_no'] as String,
          startDate: extras['start_date'] as DateTime,
          frequency: extras['frequency'] as String,
          amount: extras['amount'] as double,
          endDate: extras['end_date'] as DateTime?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.allSchedule,
      path: '/all-schedule',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return AllSchedulePage(
          userId: extras['user_id'] as int,
        );
      },
    ),
    // ===== Goal List (placeholder) =====
    GoRoute(
      name: RouteNames.goalList,
      path: '/goal-list',
      builder: (ctx, st) => const GoalListPage(),
    ),
    GoRoute(
      name: RouteNames.addGoal,
      path: '/add-goal',
      builder: (ctx, st) => const AddGoalPage(),
    ),
    GoRoute(
      name: RouteNames.goalSuccess,
      path: '/goal-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return GoalSuccessPage(
          goalName: extras['goal_name'] as String,
          targetAmount: extras['target_amount'] as double,
          dueDate: DateTime.parse(extras['due_date'] as String),
          allowEarlyWithdraw: extras['allow_early_withdraw'] as bool,
          notes: extras['notes'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.goalDetail,
      path: '/goal-detail',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return GoalDetailPage(
          piggyBankId: extras['piggy_bank_id'] as int,
          name: extras['name'] as String,
          goalAmount: extras['goal_amount'] as double,
          totalSaved: extras['total_saved'] as double,
          targetAt: extras['target_at'] as String,
          status: extras['status'] as String,
          allowEarlyWithdraw: extras['allow_early_withdraw'] as bool,
          reachedAt: extras['reached_at'] as String?,
          createdAt: extras['created_at'] as String,
          updatedAt: extras['updated_at'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.goalSaveMoney,
      path: '/goal-save-money',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return GoalSaveMoneyPage(
          piggyBankId: extras['piggy_bank_id'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.saveMoneySuccess,
      path: '/save-money-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return SaveMoneySuccessPage(
          piggyBankId: extras['piggy_bank_id'] as int,
          amount: extras['amount'] as double,
          reason: extras['reason'] as String?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.goalHistory,
      path: '/goal-history',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return GoalHistoryPage(
          piggyBankId: extras['piggy_bank_id'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.goalClaimMoney,
      path: '/goal-claim-money',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return GoalClaimMoneyPage(
          piggyBankId: extras['piggy_bank_id'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.claimMoneySuccess,
      path: '/claim-money-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return ClaimMoneySuccessPage(
          piggyBankId: extras['piggy_bank_id'] as int,
          amount: extras['amount'] as double,
          reason: extras['reason'] as String?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.merchantRegisterLanding,
      path: '/merchant-register-landing',
      builder: (ctx, st) => const MerchantRegisterLandingPage(),
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
  final secure = const FlutterSecureStorage();

  final loggedIn = prefs.getBool('is_logged_in') ?? false;
  final token = await secure.read(key: 'token');

  if (!mounted) return;

  if (loggedIn && token != null && token.isNotEmpty) {
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