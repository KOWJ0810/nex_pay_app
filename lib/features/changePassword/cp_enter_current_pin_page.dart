import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';

import '../../core/constants/api_config.dart';
import '../../router.dart';

class CPEnterCurrentPinPage extends StatefulWidget {
  const CPEnterCurrentPinPage({super.key});

  @override
  State<CPEnterCurrentPinPage> createState() => _CPEnterCurrentPinPageState();
}

class _CPEnterCurrentPinPageState extends State<CPEnterCurrentPinPage> {
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
          "Verify PIN",
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
              "Enter Current PIN",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              "Please verify your current PIN before changing to a new one.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 32),

            // Hidden Input
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
                  if (errorMessage != null) {
                    setState(() => errorMessage = null);
                  }
                },
              ),
            ),

            // OTP PIN Boxes
            GestureDetector(
              onTap: () => _pinFocus.requestFocus(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFilled = index < _pinController.text.length;

                  return Container(
                    width: 48,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFilled ? accentColor : Colors.black26,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isFilled ? "•" : "",
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
                    ? _verifyPin
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

  // verify current pin
  Future<void> _verifyPin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      const storage = secureStorage;
      final authToken = await storage.read(key: "token");

      if (authToken == null) {
        setState(() => errorMessage = "Not logged in.");
        return;
      }

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/account/pin/verify"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "currentPin": _pinController.text,
        }),
      );

      final json = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          json["data"] != null &&
          json["data"]["verified"] == true) {

        if (!mounted) return;

        context.pushNamed(
          RouteNames.cpEnterNewPin,
          extra: {"currentPin": _pinController.text},
        );
      } else {
        setState(() => errorMessage = "Incorrect PIN. Try again.");
      }
    } catch (e) {
      setState(() => errorMessage = "Something went wrong. Please try again.");
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