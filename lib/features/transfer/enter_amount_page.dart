import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';

class EnterAmountPage extends StatefulWidget {
  final int? userId;
  final String? userName;
  final String? userPhone;
  final String? type;
  final int? merchantId;
  final String? merchantName;
  final String? merchantType;
  final int? outletId;
  final String? outletName;
  final String? qrPayload;

  const EnterAmountPage({
    super.key,
    this.userId,
    this.userName,
    this.userPhone,
    this.type,
    this.merchantId,
    this.merchantName,
    this.merchantType,
    this.outletId,
    this.outletName,
    this.qrPayload,
  });

  @override
  _EnterAmountPageState createState() => _EnterAmountPageState();
}

class _EnterAmountPageState extends State<EnterAmountPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _storage = secureStorage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendTransfer() async {
  setState(() {
    _errorMessage = null;
  });

  final amountText = _amountController.text.trim();
  if (amountText.isEmpty) {
    setState(() => _errorMessage = 'Please enter an amount.');
    return;
  }

  final amount = double.tryParse(amountText);
  if (amount == null || amount <= 0) {
    setState(() => _errorMessage = 'Please enter a valid amount.');
    return;
  }

  final note = _noteController.text.trim();
  setState(() => _isLoading = true);

  try {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      setState(() {
        _errorMessage = 'Authentication token not found.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/qr/pay');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'qrPayload': widget.qrPayload ?? '',
        'amount': amount,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    // -----------------------------
    // 🚨 1. Check for INSIDE ERROR MESSAGE
    // -----------------------------
    if (data['success'] != true) {
      final msg = data['message']?.toString() ?? 'Transfer failed.';
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });

      // --------------------------------------------------
      //  CONDITION: insufficient balance + MERCHANT_OUTLET
      // --------------------------------------------------
      if (msg.toLowerCase().contains("insufficient") &&
          widget.type == "MERCHANT_OUTLET") {
        _triggerEmergencyWalletFlow(amount);
      }

      return;
    }

    // -----------------------------
    // SUCCESS → redirect
    // -----------------------------
    final tx = data['data'];
    setState(() => _isLoading = false);

    context.pushNamed(
      RouteNames.transferSuccess,
      extra: {
        'type': tx['type'],
        'transactionId': tx['transactionId'],
        'transactionRefNum': tx['transactionRefNum'],
        'amount': tx['amount'],
        'status': tx['status'],
        'senderUserId': tx['senderUserId'],
        'receiverUserId': tx['receiverUserId'],
        'merchantId': tx['merchantId'],
        'outletId': tx['outletId'],
      },
    );
  } catch (e) {
    setState(() {
      _errorMessage = 'An error occurred: $e';
      _isLoading = false;
    });
  }
}

Future<void> _triggerEmergencyWalletFlow(double amount) async {
  final token = await _storage.read(key: 'token');
  if (token == null) return;

  try {
    // ======================================================
    // STEP 1 — Get emergency sender info
    // ======================================================
    final pairingRes = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/emergency-wallet/pairings/my-sender"),
      headers: {"Authorization": "Bearer $token"},
    );

    final pairingJson = jsonDecode(pairingRes.body);
    if (pairingJson["success"] != true) return;

    final pairing = pairingJson["data"];
    final pairingId = pairing["pairingId"];

    // ======================================================
    // STEP 2 — Ask user: Want to use emergency wallet?
    // ======================================================
    if (!mounted) return;

    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Insufficient Balance"),
        content: Text(
            "Would you like to pay using your emergency sender (${pairing['partner']['name']})?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Use Emergency Wallet"),
          ),
        ],
      ),
    );

    if (shouldPay != true) return;

    // ======================================================
    // STEP 3 — Call emergency payment API
    // ======================================================
    final payRes = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/emergency-wallet/payments"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "pairingId": pairingId,
        "amount": amount,
        "qrPayload": widget.qrPayload ?? "",
      }),
    );

    final payJson = jsonDecode(payRes.body);

    if (payJson["success"] == true) {
      final d = payJson["data"];

      if (!mounted) return;

      context.pushNamed(
        RouteNames.emergencyTransferSuccess,
        extra: {
          "paymentId": d["paymentId"],
          "paymentStatus": d["paymentStatus"],
          "transactionId": d["transactionId"],
          "transactionRefNum": d["transactionRefNum"],
          "amount": d["amount"],
          "senderUserId": d["senderUserId"],
          "receiverUserId": d["receiverUserId"],
          "merchantId": d["merchantId"],
          "outletId": d["outletId"],
          "merchantName": d["merchantName"],
          "outletName": d["outletName"],
          "transactionDateTime": d["transactionDateTime"],
        },
      );
    }
  } catch (e) {
    print("Emergency wallet error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'Send Money',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F5F7), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final displayTitle = widget.type == 'MERCHANT_OUTLET'
                            ? (widget.merchantName ?? 'Unknown Merchant')
                            : (widget.userName ?? 'Unknown User');
                        final displaySubtitle = widget.type == 'MERCHANT_OUTLET'
                            ? (widget.outletName ?? '-')
                            : (widget.userPhone ?? '-');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displaySubtitle,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(Icons.currency_pound, color: Colors.grey),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                labelText: 'Enter Amount',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                // Shadow via Material widget below
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(Icons.edit, color: Colors.grey),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                labelText: 'Note (optional)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? LinearGradient(
                          colors: [accentColor.withOpacity(0.6), accentColor.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
