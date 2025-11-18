import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../widgets/custom_pin_keyboard.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final FlutterSecureStorage _secureStorage = secureStorage;
  String _amount = '';
  String _rawInput = '';
  double? balance;
  int? userId;
  String? token;

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

  void _onKeyTap(String value) {
    setState(() {
      if (_rawInput.length < 6 && RegExp(r'\d').hasMatch(value)) {
        _rawInput += value;
        double parsed = double.parse(_rawInput) / 100;
        _amount = parsed.toStringAsFixed(2);
      }
    });
  }

  void _onBackspace() {
    if (_rawInput.isNotEmpty) {
      setState(() {
        _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        double parsed = _rawInput.isEmpty ? 0.0 : double.parse(_rawInput) / 100;
        _amount = parsed.toStringAsFixed(2);
      });
    }
  }

  void _onClear() {
    setState(() {
      _rawInput = '';
      _amount = '';
    });
  }

  Future<void> _onProceed() async {
  if (_amount.isEmpty) return;

  final amountInCents = (double.parse(_amount) * 100).round();

  try {
    // 🔒 Step 1: Validate auth token before calling backend
    if (token == null || token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please sign in again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing user ID. Please log in again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 🛰️ Step 2: Call backend to create PaymentIntent
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/topUp/init'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amountInSen': amountInCents,
        'currency': 'myr',
        'userId': userId,
      }),
    );

    print('TOPUP /init status: ${response.statusCode}');
    print('TOPUP /init body: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = jsonDecode(response.body);
      throw Exception('Server error: ${err['message'] ?? response.body}');
    }

    final data = jsonDecode(response.body);
    final clientSecret = data['clientSecret'] ?? data['client_secret'];
    final paymentIntentId =
        data['paymentIntentId'] ?? data['payment_intent_id'];

    if (clientSecret == null || (clientSecret as String).isEmpty) {
      throw Exception('Backend did not return a valid clientSecret');
    }

    // 💳 Step 3: Initialize and show Stripe PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'NexPay',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    // ✅ Step 4: Navigate on success
    context.pushNamed(
      RouteNames.topUpSuccess,
      extra: {
        'amount': _amount,
        'paymentIntentId': paymentIntentId,
      },
    );
  } catch (e) {
    print('TopUp Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Top Up',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient for subtle depth
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF102520), Color(0xFF1A3C31)],
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enter Top-Up Amount',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _amount.isEmpty ? 'RM 0.00' : 'RM $_amount',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      balance == null
                          ? const CircularProgressIndicator()
                          : Text(
                              'Current Balance: RM ${balance?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _amount.isEmpty ? null : _onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Proceed to Top-Up',
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed bottom keyboard
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomPinKeyboard(
              onKeyTap: _onKeyTap,
              onBackspace: _onBackspace,
              onClear: _onClear,
              isEnabled: _amount.isNotEmpty,
              onProceed: _onProceed,
              onBackspaceLongPress: _onClear,
            ),
          ),
        ],
      ),
    );
  }
}