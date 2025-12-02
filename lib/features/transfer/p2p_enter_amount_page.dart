import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_config.dart';
import '../../router.dart';

class P2PEnterAmountPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? phoneNum;

  const P2PEnterAmountPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phoneNum,
  });

  @override
  State<P2PEnterAmountPage> createState() => _P2PEnterAmountPageState();
}

class _P2PEnterAmountPageState extends State<P2PEnterAmountPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

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
          "Transfer Money",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient Info
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accentColor.withOpacity(0.4),
                    child: const Icon(Icons.person, size: 30, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? "Unknown User",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.phoneNum ?? "-",
                        style: const TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Enter Amount
            const Text(
              "Enter Amount",
              style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "0.00",
                prefixText: "RM ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (_) {
                if (errorMessage != null) {
                  setState(() => errorMessage = null);
                }
              },
            ),

            const SizedBox(height: 22),

            // Optional note
            const Text(
              "Note (optional)",
              style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: noteController,
              maxLength: 40,
              decoration: InputDecoration(
                hintText: "e.g. Lunch, Grab money, etc.",
                filled: true,
                fillColor: Colors.white,
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _checkBiometricAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: primaryColor, strokeWidth: 2)
                    : const Text(
                        "Pay",
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkBiometricAndSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (biometricEnabled) {
      bool authenticated = false;
      try {
        authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to proceed with the transfer',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } catch (e) {
        setState(() {
          errorMessage = "Biometric authentication failed.";
        });
        return;
      }

      if (!authenticated) {
        setState(() {
          errorMessage = "Authentication failed or cancelled.";
        });
        return;
      }
    }

    await _submitTransfer();
  }

  // ============================================================
  // 🔥 CALL P2P TRANSFER API
  // ============================================================
  Future<void> _submitTransfer() async {
    final amountStr = amountController.text.trim();
    final amount = double.tryParse(amountStr);

    if (amount == null || amount <= 0) {
      setState(() => errorMessage = "Please enter a valid amount.");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final storage = secureStorage;
    final token = await storage.read(key: "token");

    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Not logged in.";
      });
      return;
    }

    final body = {
      "toPhone": widget.phoneNum,
      "amount": amount,
      "note": noteController.text.trim(),
    };

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/p2p/transfer"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(res.body);

      if (json["success"] == true) {
        final data = json["data"];

        if (!mounted) return;

        context.pushNamed(
          RouteNames.p2pTransferSuccess,
          extra: {
            "transactionId": data["transactionId"],
            "transactionRefNum": data["transactionRefNum"],
            "amount": data["amount"],
            "fromUserId": data["fromUserId"],
            "toUserId": data["toUserId"],
            "fromBalanceAfter": data["fromBalanceAfter"],
            "toBalanceAfter": data["toBalanceAfter"],
            "at": data["at"],
            "receiverName": widget.userName,
            "receiverPhone": widget.phoneNum,
          },
        );
      } else {
        setState(() {
          errorMessage = json["message"] ?? "Transfer failed.";
        });
      }
    } catch (e) {
      setState(() => errorMessage = "Something went wrong.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}