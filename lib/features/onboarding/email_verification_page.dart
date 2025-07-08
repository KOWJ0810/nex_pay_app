import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'ic_verification_page.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  EmailVerificationPage({required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}



class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> verifyOtp() async {
  String code = _controllers.map((c) => c.text).join();

  if (code.length != 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please enter the full 4-digit code")),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/otp/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email, "otp": code}),
    );

    if (response.statusCode == 200 && response.body.contains("success")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ICVerificationPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP")),
      );
    }
  } catch (e) {
    print("Error verifying OTP: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error verifying OTP")),
    );
  }
}

  Widget _buildCodeField(int index) {
    return Container(
      width: 50,
      child: TextField(
        controller: _controllers[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(color: Colors.white, fontSize: 24),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: accentColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 3) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 3, color: accentColor),
                  SizedBox(width: 10),
                  Container(width: 80, height: 3, color: accentColor),
                  SizedBox(width: 10),
                  Container(width: 80, height: 3, color: Colors.grey[400]),
                ],
              ),
              SizedBox(height: 60),
              Text(
                'Verify your email',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Please verify 4 digit code sent to',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 5),
              Text(
                widget.email,
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildCodeField(index)),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                    final response = await http.post(
                        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({"email": widget.email}),
                    );

                    if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("OTP resent successfully")),
                        );
                    } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to resend OTP")),
                        );
                    }
                },
                child: Text(
                  'Didn’t receive any code? Resend Code',
                  style: TextStyle(color: accentColor),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: verifyOtp,
                style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    ),
                ),
                child: Text(
                    'Continue',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
            )
            ],
          ),
        ),
      ),
    );
  }
}