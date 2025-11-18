

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

import '../../core/constants/api_config.dart';
import '../../router.dart';

class CPVerifyOTPPage extends StatefulWidget {
  final String currentPin;
  final String newPin;

  const CPVerifyOTPPage({
    super.key,
    required this.currentPin,
    required this.newPin,
  });

  @override
  State<CPVerifyOTPPage> createState() => _CPVerifyOTPPageState();
}

class _CPVerifyOTPPageState extends State<CPVerifyOTPPage> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Verify OTP",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            const Text(
              "Enter OTP",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              "A 4‑digit verification code has been sent to your email.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 32),

            SizedBox(
              height: 0,
              width: 0,
              child: TextField(
                focusNode: _otpFocus,
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(counterText: "", border: InputBorder.none),
                onChanged: (_) {
                  setState(() {});
                  if (errorMessage != null) errorMessage = null;
                },
              ),
            ),

            GestureDetector(
              onTap: () => _otpFocus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) {
                  final filled = i < _otpController.text.length;
                  return Container(
                    width: 58,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled ? accentColor : Colors.black26,
                        width: 1.6,
                      ),
                    ),
                    child: Text(
                      filled ? "•" : "",
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  );
                }),
              ),
            ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _otpController.text.length == 4 && !isLoading ? _verifyOTP : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: accentColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : const Text(
                        "Verify",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      const storage = FlutterSecureStorage();
      final email = await storage.read(key: "user_email");
      final token = await storage.read(key: "token");

      if (email == null || token == null) {
        setState(() => errorMessage = "Authentication required.");
        return;
      }

      final verifyRes = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": _otpController.text,
        }),
      );

      if (verifyRes.statusCode != 200) {
        setState(() => errorMessage = "Incorrect OTP. Try again.");
        return;
      }

      final updateRes = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/account/pin/update"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "currentPin": widget.currentPin,
          "newPin": widget.newPin,
        }),
      );

      final json = jsonDecode(updateRes.body);

      if (json["data"]?["updated"] == true) {
        if (!mounted) return;
        context.goNamed(RouteNames.cpSuccess);
      } else {
        setState(() => errorMessage = "PIN update failed.");
      }
    } catch (e) {
      setState(() => errorMessage = "Something went wrong. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }
}