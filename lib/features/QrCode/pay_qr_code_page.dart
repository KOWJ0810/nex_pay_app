import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';

class PayQrCodePage extends StatefulWidget {
  const PayQrCodePage({super.key});

  @override
  State<PayQrCodePage> createState() => _PayQrCodePageState();
}

class _PayQrCodePageState extends State<PayQrCodePage> {
  String? qrPayload;
  DateTime? expiresAt;
  bool isLoading = false;
  String? errorMessage;
  int remainingSeconds = 0;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateQrCode() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      setState(() {
        errorMessage = "Session expired. Please log in again.";
        isLoading = false;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pay/qr/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true && jsonRes['data'] != null) {
          final data = jsonRes['data'];
          setState(() {
            qrPayload = data['qrPayload'];
            expiresAt = DateTime.fromMillisecondsSinceEpoch(
              (data['expiresAtEpochSec'] * 1000).toInt(),
            );
          });
          countdownTimer?.cancel();
          final expiry = expiresAt;
          if (expiry != null) {
            remainingSeconds = expiry.difference(DateTime.now()).inSeconds;
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (remainingSeconds <= 0) {
                timer.cancel();
                _generateQrCode(); // auto regenerate
              } else {
                setState(() => remainingSeconds--);
              }
            });
          }
        } else {
          setState(() => errorMessage = "Invalid response from server.");
        }
      } else {
        setState(() => errorMessage = "Server Error: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(.85),
                accentColor.withOpacity(.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Payment QR Code",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const CircularProgressIndicator(color: primaryColor)
              : errorMessage != null
                  ? Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    )
                  : qrPayload != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QrImageView(
                              data: qrPayload!,
                              version: QrVersions.auto,
                              size: 260,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Expires in: ${remainingSeconds}s",
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Expires at: ${expiresAt != null ? expiresAt!.toLocal().toString().substring(0, 19) : '-'}",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _generateQrCode,
                              icon: const Icon(Icons.refresh_rounded, color: primaryColor),
                              label: const Text(
                                "Regenerate",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "No QR Code available",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
        ),
      ),
    );
  }
}