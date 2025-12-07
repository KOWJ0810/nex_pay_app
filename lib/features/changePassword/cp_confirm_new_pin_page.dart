
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';

import '../../core/constants/api_config.dart';
import '../../router.dart';

class CPConfirmNewPinPage extends StatefulWidget {
  final String currentPin;
  final String newPin;

  const CPConfirmNewPinPage({
    super.key,
    required this.currentPin,
    required this.newPin,
  });

  @override
  State<CPConfirmNewPinPage> createState() => _CPConfirmNewPinPageState();
}

class _CPConfirmNewPinPageState extends State<CPConfirmNewPinPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

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
          "Confirm New PIN",
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
              "Re-enter New PIN",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              "Please confirm your new PIN.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 32),

            // Hidden Input Field
            SizedBox(
              height: 0,
              width: 0,
              child: TextField(
                focusNode: _pinFocus,
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(counterText: "", border: InputBorder.none),
                onChanged: (_) {
                  setState(() {});
                  if (errorMessage != null) errorMessage = null;
                },
              ),
            ),

            // PIN Box
            GestureDetector(
              onTap: () => _pinFocus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final filled = i < _pinController.text.length;
                  return Container(
                    width: 48,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled ? accentColor : Colors.black26,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      filled ? "•" : "",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pinController.text.length == 6 && !isLoading
                    ? _onConfirmPin
                    : null,
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                    : const Text(
                        "Continue",
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

  // confirm pin and send OTP
  Future<void> _onConfirmPin() async {
    final confirmPin = _pinController.text;

    // Check if confirm matches newPin
    if (confirmPin != widget.newPin) {
      setState(() => errorMessage = "PIN does not match. Try again.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      const storage = secureStorage;
      final authToken = await storage.read(key: "token");
      final email = await storage.read(key: "user_email"); 

      if (authToken == null || email == null) {
        setState(() => errorMessage = "Authentication required.");
        return;
      }

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"email": email}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;

        context.pushNamed(
          RouteNames.cpVerifyOTP,
          extra: {
            "currentPin": widget.currentPin,
            "newPin": widget.newPin,
          },
        );
      } else {
        setState(() => errorMessage = "Failed to send OTP.");
      }
    } catch (e) {
      setState(() => errorMessage = "Something went wrong.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }
}