//import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
//import 'email_otp_verification_page.dart'; // Update this path as needed
import '../dashboard/dashboard_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
  final phone = _phoneController.text.trim();
  final pin = _pinController.text.trim();

  if (phone.isEmpty || pin.isEmpty) {
    setState(() {
      errorMessage = 'Please enter both phone number and PIN.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    errorMessage = '';
  });

  // Hardcoded credentials
  const hardcodedPhone = '0123456789';
  const hardcodedPin = '1234';

  await Future.delayed(Duration(seconds: 1)); // simulate loading

  if (phone == hardcodedPhone && pin == hardcodedPin) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_In', true);
    await prefs.setString('user_phone', phone);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(),
      ),
    );
  } else {
    setState(() {
      errorMessage = 'Invalid phone number or PIN.';
    });
  }

  setState(() {
    _isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Spacer(),
                Text(
                  'Login',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: TextStyle(color: Colors.white),
                  enabled: !_isLoading,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: TextStyle(color: Colors.white),
                  enabled: !_isLoading,
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Forgot PIN'),
                                content: Text('Please contact support or reset PIN from the main app (to be implemented).'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'OK',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ),
                if (errorMessage.isNotEmpty)
                  Text(errorMessage, style: TextStyle(color: Colors.redAccent)),
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator(color: accentColor)
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: primaryColor),
                        ),
                      ),
                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
