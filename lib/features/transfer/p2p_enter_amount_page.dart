import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
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

  // ─── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _checkBiometricAndSubmit() async {
    HapticFeedback.lightImpact();
    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (biometricEnabled) {
      bool authenticated = false;
      try {
        authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to pay RM ${amountController.text}',
          options: const AuthenticationOptions(stickyAuth: true, useErrorDialogs: true),
        );
      } catch (e) {
        setState(() => errorMessage = "Biometric error. Try again.");
        return;
      }

      if (!authenticated) return;
    }

    await _submitTransfer();
  }

  Future<void> _submitTransfer() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => errorMessage = "Enter a valid amount");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final storage = secureStorage;
    final token = await storage.read(key: "token");

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/p2p/transfer"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "toPhone": widget.phoneNum,
          "amount": amount,
          "note": noteController.text.trim(),
        }),
      );

      final jsonRes = jsonDecode(res.body);

      if (jsonRes["success"] == true) {
        if (!mounted) return;
        final data = jsonRes["data"];
        
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
            // Extra info for display
            "receiverName": widget.userName,
            "receiverPhone": widget.phoneNum,
          },
        );
      } else {
        setState(() => errorMessage = jsonRes["message"] ?? "Transfer failed");
      }
    } catch (e) {
      setState(() => errorMessage = "Connection error");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Dark immersive background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text("Transfer Money", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 1. Recipient Pill
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentColor,
                  child: Text(
                    (widget.userName ?? "U")[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "To: ${widget.userName ?? 'Unknown'}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      widget.phoneNum ?? "-",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // 2. Big Amount Input
          Expanded(
            child: Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                  cursorColor: accentColor,
                  decoration: InputDecoration(
                    prefixText: "RM ",
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.5)
                    ),
                    border: InputBorder.none,
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  ),
                  inputFormatters: [
                     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), 
                  ],
                  onChanged: (_) {
                    if (errorMessage != null) setState(() => errorMessage = null);
                  },
                ),
              ),
            ),
          ),

          // 3. Bottom Sheet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Note Input
                TextField(
                  controller: noteController,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: "Add a note (e.g. Lunch)",
                    filled: true,
                    fillColor: const Color(0xFFF4F6F5),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    counterText: "",
                  ),
                ),
                
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),

                const SizedBox(height: 24),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _checkBiometricAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Pay Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                
                // Keyboard padding
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}