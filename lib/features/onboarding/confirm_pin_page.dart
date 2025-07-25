import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/colors.dart';
import '../../widgets/custom_pin_keyboard.dart';
import 'success_page.dart';
import '../../models/registration_data.dart';
import '../../core/constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmPinPage extends StatefulWidget {
  final String originalPin;

  const ConfirmPinPage({required this.originalPin, super.key});

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
  List<String> _confirmPin = [];
  String? _error;

  void _onKeyTap(String value) {
    if (_confirmPin.length < 6) {
      setState(() => _confirmPin.add(value));
    }
  }

  void _onBackspace() {
    if (_confirmPin.isNotEmpty) {
      setState(() => _confirmPin.removeLast());
    }
  }

  void _onClear() {
    setState(() {
      _confirmPin.clear();
      _error = null;
    });
  }

  Future<String> uploadImage(File file, String fileName) async {
    final ref = FirebaseStorage.instance.ref().child('users/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  void _onProceed() async {
    final pin = _confirmPin.join();

    if (pin != widget.originalPin) {
      setState(() {
        _error = "PIN does not match. Please try again.";
        _confirmPin.clear();
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _error = null);
        }
      });
      return;
    }

    try {
      RegistrationData.pin = pin;
      print("PIN confirmed: $pin");

      print("Initiate Upload Image to Firebase");
      // Upload images
      final icFrontUrl = await uploadImage(
        RegistrationData.icFrontImage!,
        'ic_front_${RegistrationData.icNum}.jpg',
      );

      print("stuck here");
      

      final icBackUrl = await uploadImage(
        RegistrationData.icBackImage!,
        'ic_back_${RegistrationData.icNum}.jpg',
      );

      final selfieUrl = await uploadImage(
        RegistrationData.selfieImage!,
        'selfie_${RegistrationData.icNum}.jpg',
      );
      

      // API call
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/users/createUser"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_name": RegistrationData.fullName,
          "ic_num": RegistrationData.icNum,
          "phoneNum": RegistrationData.phoneNum,
          "ic_image_front": icFrontUrl,
          "ic_image_back": icBackUrl,
          "user_verification_image": selfieUrl,
          "email": RegistrationData.email,
          "street_address": RegistrationData.street,
          "postcode": RegistrationData.postcode,
          "city": RegistrationData.city,
          "state": RegistrationData.state,
          "country": "Malaysia",
          "account_pin_num": RegistrationData.pin,
        }),
      );

      if (response.statusCode == 200) {
        print("User created successfully");

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', RegistrationData.email);

        // Navigate to success page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuccessPage()),
          );
        }
      } else {
        print("Failed to create user: ${response.body}");
        setState(() => _error = "Failed to create user. Please try again.");
      }
    } catch (e) {
      print("Error during submission: $e");
      setState(() => _error = "An error occurred. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 3, color: accentColor),
                const SizedBox(width: 10),
                Container(width: 80, height: 3, color: accentColor),
                const SizedBox(width: 10),
                Container(width: 80, height: 3, color: accentColor),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "Confirm PIN",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const Text(
              "Re-enter your 6-digit PIN",
              style: TextStyle(color: accentColor, fontSize: 18),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool filled = index < _confirmPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _error != null ? Colors.redAccent : accentColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filled ? '●' : '',
                      style: const TextStyle(fontSize: 20, color: primaryColor),
                    ),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Spacer(),
            CustomPinKeyboard(
              onKeyTap: _onKeyTap,
              onBackspace: _onBackspace,
              onClear: _onClear,
              isEnabled: _confirmPin.length == 6,
              onProceed: _onProceed,
            ),
          ],
        ),
      ),
    );
  }
}
