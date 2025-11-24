import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../widgets/custom_pin_keyboard.dart'; // Your provided keyboard
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/colors.dart'; // Ensure this exists

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final FlutterSecureStorage _secureStorage = secureStorage;

  // State
  String _amount = '0.00';
  String _rawInput = ''; // Keeps track of keystrokes "123" -> 1.23
  double? balance;
  int? userId;
  String? token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecureData();
  }

  Future<void> _loadSecureData() async {
    final storedBalance = await _secureStorage.read(key: 'wallet_balance');
    final storedUserId = await _secureStorage.read(key: 'user_id');
    final storedToken = await _secureStorage.read(key: 'token');
    setState(() {
      balance = storedBalance != null ? double.tryParse(storedBalance) ?? 0.0 : 0.0;
      userId = storedUserId != null ? int.tryParse(storedUserId) : null;
      token = storedToken;
    });
  }

  // ─── Input Logic ─────────────────────────────────────────────────────────────

  void _onKeyTap(String value) {
    if (_rawInput.length < 9) { // Prevent unrealistic amounts
      setState(() {
        if (_rawInput == '0') _rawInput = '';
        _rawInput += value;
        _updateAmountString();
      });
    }
  }

  void _onBackspace() {
    if (_rawInput.isNotEmpty) {
      setState(() {
        _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        _updateAmountString();
      });
    }
  }

  void _onClear() {
    setState(() {
      _rawInput = '';
      _amount = '0.00';
    });
  }

  void _updateAmountString() {
    if (_rawInput.isEmpty) {
      _amount = '0.00';
    } else {
      double value = double.parse(_rawInput) / 100;
      _amount = value.toStringAsFixed(2);
    }
  }

  void _addQuickAmount(int addAmount) {
    HapticFeedback.lightImpact();
    
    // Parse current raw input to double, add amount, convert back to cents string
    double currentVal = _rawInput.isEmpty ? 0.0 : double.parse(_rawInput) / 100;
    double newVal = currentVal + addAmount;
    
    setState(() {
      // e.g. 10.00 -> "1000"
      _rawInput = (newVal * 100).round().toString(); 
      _amount = newVal.toStringAsFixed(2);
    });
  }

  // ─── Payment Logic ───────────────────────────────────────────────────────────

  Future<void> _onProceed() async {
    if (_amount == '0.00' || _amount.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final amountInCents = (double.parse(_amount) * 100).round();

      if (token == null) throw Exception('Session expired');
      if (userId == null) throw Exception('User ID missing');

      // 1. Backend Call
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/topUp/init'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amountInSen': amountInCents,
          'currency': 'myr',
          'userId': userId,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];
      final paymentIntentId = data['paymentIntentId'];

      // 2. Stripe SDK
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NexPay',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: primaryColor,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        context.pushNamed(
          RouteNames.topUpSuccess,
          extra: {'amount': _amount, 'paymentIntentId': paymentIntentId},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool canProceed = _amount != '0.00' && !_isLoading;

    return Scaffold(
      backgroundColor: primaryColor, // DARK BACKGROUND IS CRITICAL FOR YOUR KEYBOARD
      
      // Transparent AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Top Up Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        children: [
          // 1. Balance Indicator
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, size: 14, color: accentColor.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  'Current Balance: RM ${balance?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),

          // 2. Main Amount Display (The Hero)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Enter Amount',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'RM ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _amount,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -2,
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: accentColor),
                  ),
              ],
            ),
          ),

          // 3. Quick Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [10, 20, 50, 100].map((val) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => _addQuickAmount(val),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        '+ RM$val',
                        style: const TextStyle(
                          color: accentColor, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),

          // 4. YOUR Custom Keyboard
          // We anchor it to the bottom. 
          // Note: Your keyboard widget handles the "Proceed" button internally.
          CustomPinKeyboard(
            onKeyTap: _onKeyTap,
            onBackspace: _onBackspace,
            onBackspaceLongPress: _onClear,
            onClear: _onClear,
            isEnabled: canProceed,
            onProceed: _onProceed,
          ),
        ],
      ),
    );
  }
}