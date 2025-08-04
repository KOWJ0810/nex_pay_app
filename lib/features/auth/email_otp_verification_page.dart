import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import 'package:http/http.dart' as http;
import '../dashboard/dashboard_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _timer?.cancel();
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
          (route) => false,
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

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP resent successfully")),
        );
        _startCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to resend OTP")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error resending OTP")),
      );
    } finally {
      setState(() => _isResending = false);
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
                '',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildCodeField(index)),
              ),
              SizedBox(height: 20),
              if (_isResending)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: accentColor, strokeWidth: 2),
                    SizedBox(width: 10),
                    Text("Sending code...", style: TextStyle(color: Colors.white70)),
                  ],
                )
              else if (_canResend)
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'Didn’t receive any code? Resend Code',
                    style: TextStyle(color: accentColor),
                  ),
                )
              else
                Text(
                  'Resend available in $_secondsRemaining seconds',
                  style: TextStyle(color: Colors.grey[400]),
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
