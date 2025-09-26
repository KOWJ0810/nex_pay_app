import 'package:flutter/material.dart';
import '../../widgets/custom_pin_keyboard.dart';
import 'top_up_success_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  String _amount = '';
  String _rawInput = '';
  double balance = 35.89;

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

  void _onProceed() async {
  if (_amount.isEmpty) return;

  final amountInCents = (double.parse(_amount) * 100).round();

  try {
    // 1. Call your backend to create PaymentIntent
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/topUp/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amountInSen': amountInCents, 'currency': 'myr', 'userId': 152}),
    );
    debugPrint("RAW RESPONSE: ${response.body}");

    print("Backend response raw: ${response.body}");
   

    final json = jsonDecode(response.body);
    debugPrint("DECODED JSON: $json");
    debugPrint("clientSecret key exists? ${json.containsKey('clientSecret')}");
    debugPrint("paymentIntentClientSecret key exists? ${json.containsKey('paymentIntentClientSecret')}");

    final clientSecret = json['clientSecret'] ?? json['client_secret'];
    final paymentIntentId = json['paymentIntentId'] ?? json['payment_intent_id'];

    // 2. Present payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'NexPay',
        style: ThemeMode.light,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    

    // 3. Navigate to success screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopUpSuccessPage(
          amount: _amount,
          paymentIntentId: paymentIntentId,
        ),
      ),
    );
  } catch (e) {
    print('Stripe error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${e.toString()}')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2F24),
        elevation: 0,
        title: const Text('Top Up', style: TextStyle(color: Color(0xFFB8E986))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(fontSize: 20, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _amount.isEmpty ? '0.00' : _amount,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Current Balance : RM ${balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 150), // Space for keyboard
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            
              child: CustomPinKeyboard(
                onKeyTap: _onKeyTap,
                onBackspace: _onBackspace,
                onClear: _onClear,
                isEnabled: _amount.isNotEmpty,
                onProceed: _onProceed,
              ),
            
          ),
        ],
      ),
    );
  }
}

