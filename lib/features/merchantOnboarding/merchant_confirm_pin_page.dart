import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:nex_pay_app/models/merchant_registration_data.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class MerchantConfirmPinPage extends StatefulWidget {
  final String pin;

  const MerchantConfirmPinPage({super.key, required this.pin});

  @override
  State<MerchantConfirmPinPage> createState() => _MerchantConfirmPinPageState();
}

class _MerchantConfirmPinPageState extends State<MerchantConfirmPinPage> {
  final TextEditingController _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? errorText;
  final storage = secureStorage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, bottom: 30, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(.85),
                  accentColor.withOpacity(.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Confirm PIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Re-enter your 6-digit PIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Please confirm your PIN to ensure it's correct.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _confirmPinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 8,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          errorText: errorText,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please re-enter your PIN";
                          } else if (value.length != 6) {
                            return "PIN must be 6 digits";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onConfirmPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Confirm",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _uploadImage(File file, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('merchants/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[ConfirmPin] Firebase upload failed ($fileName): ${e.code} ${e.message}');
      throw Exception('Upload failed. Please try again.');
    } catch (e) {
      debugPrint('[ConfirmPin] Upload error ($fileName): $e');
      rethrow;
    }
  }

  void _onConfirmPressed() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final enteredPin = _confirmPinController.text;
        if (enteredPin == widget.pin) {
          final token = await storage.read(key: 'token');
          if (token == null) throw Exception("Session expired. Please log in again.");

          // Upload SSM Image
          final ssmUrl = await _uploadImage(
            MerchantRegistrationData.businessSsmImage!,
            'ssm_${DateTime.now().millisecondsSinceEpoch}.png',
          );

          // Prepare payload
          final body = jsonEncode({
            "merchantName": MerchantRegistrationData.merchantName,
            "merchantType": MerchantRegistrationData.merchantType,
            "businessRegistrationCode": MerchantRegistrationData.businessRegCode,
            "bankAccountNum": MerchantRegistrationData.bankAccountNum,
            "ssmImageUpload": ssmUrl,
            "pin": enteredPin,
          });

          final res = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/merchants'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: body,
          );

          final jsonRes = jsonDecode(res.body);
          if (res.statusCode == 200 && jsonRes['success'] == true) {
            MerchantRegistrationData.pin = enteredPin;
            context.goNamed(RouteNames.merchantPendingApprove);
          } else {
            throw Exception(jsonRes['message'] ?? 'Failed to register merchant.');
          }
        } else {
          setState(() => errorText = "PINs do not match. Please try again.");
        }
      } catch (e) {
        setState(() => errorText = 'Error: $e');
      } finally {
        setState(() => isLoading = false);
      }
    }
  }
}
