import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_config.dart';

class MerchantScanQrCodePage extends StatefulWidget {
  final double amount;
  final String? note;

  const MerchantScanQrCodePage({
    super.key,
    required this.amount,
    this.note,
  });

  @override
  State<MerchantScanQrCodePage> createState() => _MerchantScanQrCodePageState();
}

class _MerchantScanQrCodePageState extends State<MerchantScanQrCodePage> {
  bool _isScanning = true;
  String? _scannedData;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isScanning = false;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
      );
      return;
    }

    final body = {
      "qrPayload": code,
      "amount": widget.amount,
      "note": widget.note ?? "",
    };

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/merchant/qr/charge'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true && jsonRes['data'] != null) {
          final data = jsonRes['data'];

          context.goNamed(
            RouteNames.merchantPaymentSuccess,
            extra: {
              'transactionRefNum': data['transactionRefNum'],
              'amountCharged': data['amountCharged'],
              'payerUserId': data['payerUserId'],
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? "Charge failed")),
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Invalid QR Code"),
            content: Text("Server error: ${res.statusCode}. QR code is invalid or expired."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isScanning = true);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid QR Code"),
          content: const Text("Invalid QR code. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isScanning = true);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "Amount to Pay",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "RM ${widget.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 30,
              color: primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 300,
              height: 300,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: _onDetect,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}