// lib/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/features/auth/security_fallback_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_success_page.dart';
import 'package:nex_pay_app/features/onboarding/biometric_opt_in_page.dart';
import 'package:nex_pay_app/features/onboarding/setup_security_questions_page.dart';
import 'package:nex_pay_app/features/outlet/merchant_add_staff_page.dart';
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
import 'package:nex_pay_app/features/merchantOnboarding/merchant_setup_name_page.dart';
import 'package:nex_pay_app/features/merchantOnboarding/merchant_setup_detail_page.dart';
import 'package:nex_pay_app/features/merchantOnboarding/merchant_setup_pin_page.dart';
import 'package:nex_pay_app/features/merchantOnboarding/merchant_confirm_pin_page.dart';
import 'package:nex_pay_app/features/merchantOnboarding/merchant_pending_approve_page.dart';
import 'package:nex_pay_app/features/dashboard/merchant_dashboard_page.dart';
import 'package:nex_pay_app/features/account/merchant_account_page.dart';
import 'package:nex_pay_app/features/transfer/merchant_enter_pay_amount_page.dart';
import 'package:nex_pay_app/features/QrCode/merchant_scan_qr_code_page.dart';
import 'package:nex_pay_app/features/outlet/merchant_outlet_list_page.dart';
import 'package:nex_pay_app/features/outlet/merchant_add_outlet_page.dart';
import 'package:nex_pay_app/features/outlet/merchant_outlet_detail_page.dart';
import 'package:nex_pay_app/features/outlet/merchant_add_staff_page.dart';
import 'package:nex_pay_app/features/QrCode/pay_qr_code_page.dart';
import 'package:nex_pay_app/features/transfer/merchant_payment_success_page.dart';
import 'package:nex_pay_app/features/outlet/add_outlet_success_page.dart';
import 'package:nex_pay_app/features/outlet/add_staff_success_page.dart';
import 'package:nex_pay_app/features/outlet/edit_outlet_page.dart';
import 'package:nex_pay_app/features/outlet/scan_outlet_list_page.dart';
import 'package:nex_pay_app/features/transaction/merchant_transaction_history_page.dart';
import 'package:nex_pay_app/features/staff/staff_outlet_list_page.dart';
import 'package:nex_pay_app/features/staff/staff_dashboard_page.dart';
import 'package:nex_pay_app/features/transaction/outlet_transaction_history_page.dart';
import 'package:nex_pay_app/features/transaction/outlet_transaction_detail_page.dart';
import 'package:nex_pay_app/features/transaction/merchant_transaction_detail_page.dart';
import 'package:nex_pay_app/features/QrCode/merchant_receive_qr_code_page.dart';
import 'package:nex_pay_app/features/paymentLink/show_payment_link_page.dart';
import 'package:nex_pay_app/features/paymentLink/payment_link_preview_page.dart';
import 'package:nex_pay_app/features/paymentLink/outlet_list_payment_link_page.dart';
import 'package:nex_pay_app/features/paymentLink/payment_link_success_page.dart';
import 'package:nex_pay_app/features/QrCode/outlet_list_qr_code_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_enter_current_pin_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_enter_new_pin_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_confirm_new_pin_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_verify_otp_page.dart';
import 'package:nex_pay_app/features/changePassword/cp_success_page.dart';
import 'package:nex_pay_app/features/transaction/transaction_limit_page.dart';
import 'package:nex_pay_app/features/transfer/p2p_enter_amount_page.dart';
import 'package:nex_pay_app/features/transfer/p2p_transfer_success_page.dart';
import 'package:nex_pay_app/features/wallet/emergency_transfer_success_page.dart';

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
  static const merchantSetupName = 'merchant-setup-name';
  static const merchantSetupDetail = 'merchant-setup-detail';
  static const merchantSetupPin = 'merchant-setup-pin';
  static const merchantConfirmPin = 'merchant-confirm-pin';
  static const merchantPendingApprove = 'merchant-pending-approve';
  static const merchantDashboard = 'merchant-dashboard';
  static const merchantAccount = 'merchant-account';
  static const merchantEnterPayAmount = 'merchant-enter-pay-amount';
  static const merchantScanQrCode = 'merchant-scan-qr-code';
  static const merchantOutletList = 'merchant-outlet-list';
  static const merchantAddOutlet = 'merchant-add-outlet';
  static const merchantOutletDetail = 'merchant-outlet-detail';
  static const merchantAddStaff = 'merchant-add-staff';
  static const payQrCode = 'pay-qr-code';
  static const merchantPaymentSuccess = 'merchant-payment-success';
  static const addOutletSuccess = 'add-outlet-success';
  static const addStaffSuccess = 'add-staff-success';
  static const editOutletPage = 'edit-outlet-page';
  static const scanOutletList = 'scan-outlet-list';
  static const merchantTransactionHistory = 'merchant-transaction-history';
  static const staffOutletList = 'staff-outlet-list';
  static const staffDashboard = 'staff-dashboard';
  static const outletTransactionHistory = 'outlet-transaction-history';
  static const outletTransactionDetail = 'outlet-transaction-detail';
  static const merchantTransactionDetail = 'merchant-transaction-detail';
  static const merchantReceiveQrCode = 'merchant-receive-qr-code';
  static const showPaymentLink = 'show-payment-link';
  static const paymentLinkPreview = 'payment-link-preview'; 
  static const outletListPaymentLink = 'outlet-list-payment-link';
  static const paymentLinkSuccess = 'payment-link-success';
  static const outletListQrCode = 'outlet-list-qr-code';
  static const cpEnterCurrentPin = 'cp-enter-current-pin';
  static const cpEnterNewPin = 'cp-enter-new-pin';
  static const cpConfirmNewPin = 'cp-confirm-new-pin';
  static const cpSuccess = 'cp-success';
  static const cpVerifyOTP = 'cp-verify-otp';
  static const transactionLimit = 'transaction-limit';
  static const p2pEnterAmountPage = 'p2p-enter-amount-page';
  static const p2pTransferSuccess = 'p2p-transfer-success';
  static const emergencyTransferSuccess = 'emergency-transfer-success';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();


final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
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
          type: extras['type'] as String?,
          userId: extras['userId'] as int?,
          userName: extras['userName'] as String?,
          userPhone: extras['userPhone'] as String?,
          merchantId: extras['merchantId'] as int?,
          merchantName: extras['merchantName'] as String?,
          merchantType: extras['merchantType'] as String?,
          outletId: extras['outletId'] as int?,
          outletName: extras['outletName'] as String?,
          qrPayload: extras['qrPayload'] as String?,
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
          senderUserId: extras['senderUserId'] as int?,
          receiverUserId: extras['receiverUserId'] as int?,
          type: extras['type'] as String?,
          status: extras['status'] as String?,
          merchantId: extras['merchantId'] as int?,
          outletId: extras['outletId'] as int?,
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
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChatroomPage(
          chatroomId: extra['chatroom_id'] as int,
          chatTitle: extra['user_name'] as String,
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
    GoRoute(
      name: RouteNames.merchantSetupName,
      path: '/merchant-setup-name',
      builder: (ctx, st) => const MerchantSetupNamePage(),
    ),
    GoRoute(
      name: RouteNames.merchantSetupDetail,
      path: '/merchant-setup-detail',
      builder: (ctx, st) => const MerchantSetupDetailPage(),
    ),
    GoRoute(
      name: RouteNames.merchantSetupPin,
      path: '/merchant-setup-pin',
      builder: (ctx, st) => const MerchantSetupPinPage(),
    ),
    GoRoute(
      name: RouteNames.merchantConfirmPin,
      path: '/merchant-confirm-pin',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return MerchantConfirmPinPage(
          pin: extras['pin'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.merchantPendingApprove,
      path: '/merchant-pending-approve',
      builder: (ctx, st) => const MerchantPendingApprovePage(),
    ),
    GoRoute(
      name: RouteNames.merchantDashboard,
      path: '/merchant-dashboard',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: MerchantDashboardPage()),
    ),
    GoRoute(
      name: RouteNames.merchantAccount,
      path: '/merchant-account',
      pageBuilder: (ctx, st) => const NoTransitionPage(child: MerchantAccountPage()),
    ),
    GoRoute(
      name: RouteNames.merchantEnterPayAmount,
      path: '/merchant-enter-pay-amount',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return MerchantEnterPayAmountPage(
          outletId: extras['outletId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.merchantScanQrCode,
      path: '/merchant-scan-qr-code',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return MerchantScanQrCodePage(
          amount: extras['amount'] as double,
          note: extras['note'] as String?,
          outletId: extras['outletId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.merchantOutletList,
      path: '/merchant-outlet-list',
      builder: (ctx, st) {
        return const MerchantOutletListPage();
      },
    ),
    GoRoute(
      name: RouteNames.merchantAddOutlet,
      path: '/merchant-add-outlet',
      builder: (ctx, st) {
        return MerchantAddOutletPage();
      },
    ),
    GoRoute(
      name: RouteNames.merchantOutletDetail,
      path: '/merchant-outlet-detail',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final outletId = extras['outletId'] as int;
        return MerchantOutletDetailPage(outletId: outletId);
      },
    ),
    GoRoute(
      name: RouteNames.merchantAddStaff,
      path: '/merchant-add-staff',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final outletId = extras['outletId'] as int;
        return MerchantAddStaffPage(outletId: outletId);
      },
    ),
    GoRoute(
      name: RouteNames.payQrCode,
      path: '/pay-qr-code',
      builder: (ctx, st) => const PayQrCodePage(),
    ),
    GoRoute(
      name: RouteNames.merchantPaymentSuccess,
      path: '/merchant-payment-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return MerchantPaymentSuccessPage(
          transactionRefNum: extras['transactionRefNum'] as String,
          amountCharged: extras['amountCharged'] as double,
          payerUserId: extras['payerUserId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.addOutletSuccess,
      path: '/add-outlet-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return AddOutletSuccessPage(
          outletName: extras['outletName'] as String,
          outletAddress: extras['outletAddress'] as String,
          dateCreated: extras['dateCreated'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.addStaffSuccess,
      path: '/add-staff-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return AddStaffSuccessPage(
          userId: extras['userId'] as int,
          name: extras['name'] as String,
          phone: extras['phone'] as String,
          accessRole: extras['accessRole'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.editOutletPage,
      path: '/edit-outlet-page',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return EditOutletPage(
          outletId: extras['outletId'] as int,
          initialName: extras['outletName'] as String,
          initialAddress: extras['outletAddress'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.scanOutletList,
      path: '/scan-outlet-list',
      builder: (ctx, st) {
        return const ScanOutletListPage();
      },
    ),
    GoRoute(
      name: RouteNames.merchantTransactionHistory,
      path: '/merchant-transaction-history',
      builder: (ctx, st) {
        return const MerchantTransactionHistoryPage();
      },
    ),
    GoRoute(
      name: RouteNames.staffOutletList,
      path: '/staff-outlet-list',
      builder: (ctx, st) {
        return const StaffOutletListPage();
      },
    ),
    GoRoute(
      name: RouteNames.staffDashboard,
      path: '/staff-dashboard',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return StaffDashboardPage(
          outletId: extras['outletId'] as int,
        );
      },
    ),
    GoRoute(
      name: RouteNames.outletTransactionHistory,
      path: '/outlet-transaction-history',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final outletId = extras['outletId'] as int;
        return OutletTransactionHistoryPage(outletId: outletId);
      },
    ),
    GoRoute(
      name: RouteNames.outletTransactionDetail,
      path: '/outlet-transaction-detail',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final transactionId = extras['transactionId'] as int;
        return OutletTransactionDetailPage(transactionId: transactionId);
      },
    ),
    GoRoute(
      name: RouteNames.merchantTransactionDetail,
      path: '/merchant-transaction-detail',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final transactionId = extras['transactionId'] as int;
        return MerchantTransactionDetailPage(transactionId: transactionId);
      },
    ),
    GoRoute(
      name: RouteNames.merchantReceiveQrCode,
      path: '/merchant-receive-qr-code',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final outletId = extras['outletId'] as int;
        return MerchantReceiveQrCodePage(outletId: outletId);
      },
    ),
    GoRoute(
      name: RouteNames.showPaymentLink,
      path: '/show-payment-link',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final outletId = extras['outletId'] as int;
        return ShowPaymentLinkPage(outletId: outletId);
      },
    ),
    GoRoute(
      name: RouteNames.paymentLinkPreview,
      path: '/payment-link-preview',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        final token = extras['token'] as String;
        return PaymentLinkPreviewPage(token: token);
      },
    ),
    GoRoute(
      name: RouteNames.outletListPaymentLink,
      path: '/outlet-list-payment-link',
      builder: (ctx, st) {
        return OutletListPaymentLinkPage();
      },
    ),
    GoRoute(
      name: RouteNames.paymentLinkSuccess,
      path: '/payment-link-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return PaymentLinkSuccessPage(
          transactionId: extras['transactionId'] as int?,
          transactionRefNum: extras['transactionRefNum'] as String?,
          amount: extras['amount'] as double?,
          status: extras['status'] as String?,
          merchantName: extras['merchantName'] as String?,
          outletName: extras['outletName'] as String?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.outletListQrCode,
      path: '/outlet-list-qr-code',
      builder: (ctx, st) {
        return const OutletListQrCodePage();
      },
    ),
    GoRoute(
      name: RouteNames.cpEnterCurrentPin,
      path: '/cp-enter-current-pin',
      builder: (ctx, st) {
        return const CPEnterCurrentPinPage();
      },
    ),
    GoRoute(
      name: RouteNames.cpEnterNewPin,
      path: '/cp-enter-new-pin',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return CPEnterNewPinPage(
          currentPin: extras['currentPin'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.cpConfirmNewPin,
      path: '/cp-confirm-new-pin',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return CPConfirmNewPinPage(
          currentPin: extras['currentPin'] as String,
          newPin: extras['newPin'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.cpSuccess,
      path: '/cp-success',
      builder: (ctx, st) {
        return const CPSuccessPage();
      },
    ),
    GoRoute(
      name: RouteNames.cpVerifyOTP,
      path: '/cp-verify-otp',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return CPVerifyOTPPage(
          currentPin: extras['currentPin'] as String,
          newPin: extras['newPin'] as String,
        );
      },
    ),
    GoRoute(
      name: RouteNames.transactionLimit,
      path: '/transaction-limit',
      builder: (ctx, st) {
        return const TransactionLimitPage();
      },
    ),
    GoRoute(
      name: RouteNames.p2pEnterAmountPage,
      path: '/p2p-enter-amount',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return P2PEnterAmountPage(
          userId: extras['userId'] as int?,
          userName: extras['userName'] as String?,
          phoneNum: extras['phoneNum'] as String?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.p2pTransferSuccess,
      path: '/p2p-transfer-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return P2PTransferSuccessPage(
          transactionId: extras['transactionId'] as int?,
          transactionRefNum: extras['transactionRefNum'] as String?,
          amount: extras['amount'] as double?,
          fromUserId: extras['fromUserId'] as int?,
          toUserId: extras['toUserId'] as int?,
          fromBalanceAfter: extras['fromBalanceAfter'] as double?,
          toBalanceAfter: extras['toBalanceAfter'] as double?,
          at: extras['at'] as String?,
          receiverName: extras['receiverName'] as String?,
          receiverPhone: extras['receiverPhone'] as String?,
        );
      },
    ),
    GoRoute(
      name: RouteNames.emergencyTransferSuccess,
      path: '/emergency-transfer-success',
      builder: (ctx, st) {
        final extras = st.extra as Map<String, dynamic>;
        return EmergencyTransferSuccessPage(
          data: extras,
        );
      },
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
  final secure = secureStorage;

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