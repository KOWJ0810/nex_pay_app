import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_config.dart';

class MerchantReceiveQrCodePage extends StatefulWidget {
  final int outletId;

  const MerchantReceiveQrCodePage({
    super.key,
    required this.outletId,
  });

  @override
  State<MerchantReceiveQrCodePage> createState() =>
      _MerchantReceiveQrCodePageState();
}

class _MerchantReceiveQrCodePageState extends State<MerchantReceiveQrCodePage> {
  String? qrPayload;
  bool isLoading = true;
  String? errorMessage;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  @override
  void initState() {
    super.initState();
    _fetchQr();
  }

  Future<void> _fetchQr() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      qrPayload = null;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      setState(() => errorMessage = "Session expired. Please log in again.");
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/qr/outlets/${widget.outletId}/receive"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes["success"] == true && jsonRes["data"] != null) {
          setState(() {
            qrPayload = jsonRes["data"]["payload"];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Failed to generate QR code.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${res.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Receive Payment",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchQr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(color: primaryColor),
                ),
              )
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          const SizedBox(height: 20),
          const Text(
            "Show this QR to the customer\nto receive payment",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 40),

          // Square QR Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: QrImageView(
              data: qrPayload ?? "",
              version: QrVersions.auto,
              size: 260,
              gapless: true,
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: _fetchQr,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
            label: const Text(
              "Regenerate QR",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    ),
    );
  }
}