import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'email_verification_page.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:your_app_name/core/constants/api_config.dart';

class ContactInfoPage extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child:SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 40),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 3, color: accentColor),
                SizedBox(width: 10),
                Container(width: 80, height: 3, color: Colors.grey[400]),
                SizedBox(width: 10),
                Container(width: 80, height: 3, color: Colors.grey[400]),
              ],
            ),
            SizedBox(height: 30),
            Text("Step 1", style: TextStyle(color: Colors.white, fontSize: 18)),
            Text("Enter your Contact Information", style: TextStyle(color: accentColor, fontSize: 18)),
            SizedBox(height: 30),
            Icon(Icons.phone, size: 100, color: accentColor),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phone Number", style: TextStyle(color: Colors.white)),
                  TextField(
                    controller: phoneController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),
                  Text("Email", style: TextStyle(color: Colors.white)),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();

                        if (email.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please enter both phone and email")),
                            );
                            return;
                        }

                        try {
                            final response = await http.post(
                            Uri.parse("${ApiConfig.baseUrl}/otp/send"),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({"email": email}),
                            );

                            if (response.statusCode == 200) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                builder: (context) => EmailVerificationPage(email: email),
                                ),
                            );
                            } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to send OTP")),
                            );
                            }
                        } catch (e) {
                            print("Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error sending OTP")),
                            );
                        }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text("Next", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ),
    );
  }
}