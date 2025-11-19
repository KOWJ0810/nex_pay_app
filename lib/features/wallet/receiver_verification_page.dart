import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_config.dart';

class ReceiverVerificationPage extends StatefulWidget {
  final String phone;
  final int userId;
  final String userName;
  final int pairingId;
  final String status;

  const ReceiverVerificationPage({
    super.key,
    required this.phone,
    required this.userId,
    required this.userName,
    required this.pairingId,
    required this.status,
  });

  @override
  State<ReceiverVerificationPage> createState() => _ReceiverVerificationPageState();
}

class _ReceiverVerificationPageState extends State<ReceiverVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isFilled = false;

  void _checkFilled() {
    setState(() {
      _isFilled = _controllers.every((c) => c.text.isNotEmpty);
    });
  }

  void _onSubmit() async {
  final enteredCode = _controllers.map((c) => c.text).join();
  const storage = secureStorage;
  final token = await storage.read(key: 'token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Authorization token missing. Please log in again.')),
    );
    return;
  }

  try {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/verify-code'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "pairingId": widget.pairingId,
        "role": "RECEIVER",
        "code": enteredCode,
      }),
    );

    if (res.statusCode == 200) {
      final jsonRes = jsonDecode(res.body);

      if (jsonRes['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonRes['message'] ?? 'Code verified successfully!')),
        );

        // Navigate to receiver_generate_code_page
        context.goNamed(
          RouteNames.receiverGenerateCode,
          extra: {
            'pairingId': widget.pairingId,
            'status': jsonRes['nextStatus'],
            'secondCode': jsonRes['secondCode'],
            'phone': widget.phone,
            'userId': widget.userId,
            'userName': widget.userName,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonRes['message'] ?? 'Verification failed.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server Error: ${res.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Emergency Wallet',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Verification",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Verify with the person you want to set up with",
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 40),
            const Text(
              "Enter the verification code",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 6 input boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 58,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: accentColor, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      _checkFilled();
                    },
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              "The verification code will show at the person who you want to setup with.",
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),

            const Spacer(),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFilled ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFilled ? accentColor : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}