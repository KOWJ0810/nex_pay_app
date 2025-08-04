import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import 'email_verification_page.dart';
import '../../models/registration_data.dart';

class ContactInfoPage extends StatefulWidget {
  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String validationErrorEmail = '';
  String validationErrorPhone = '';
  bool isLoading = false;

  Future<void> _validateAndSendOTP() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    // if (email.isEmpty || phone.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("Please enter both phone and email")),
    //   );
    //   return;
    // }

    setState(() {
      isLoading = true;
      validationErrorEmail = '';
      validationErrorPhone = '';
    });

    try {
      // Step 1: Validate format
      final validationResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/validateContact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'phoneNum': phone}),
      );

      if (validationResponse.statusCode != 200) {
        final error = validationResponse.body.toLowerCase();

        setState(() {
          validationErrorEmail = '';
          validationErrorPhone = '';

          if (error.contains("email") && error.contains("phone")) {
            validationErrorEmail = "Invalid email format.";
            validationErrorPhone = "Invalid Malaysian phone number format.";
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Invalid phone format.")),
            );
          } else if (error.contains("email")) {
            validationErrorEmail = "Invalid email format.";
          } else if (error.contains("phone")) {
            validationErrorPhone = "Invalid Malaysian phone number format.";
          } else {
            // Unexpected message
            validationErrorEmail = error;
          }
        });

        

        setState(() => isLoading = false);
        return;
      }

      // Step 2: Check if phone exists
      final phoneCheckResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/checkPhone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_num': phone}),
      );

      if (phoneCheckResponse.statusCode == 200) {
        validationErrorPhone = "Phone number already in use";
        setState(() => isLoading = false);
        return;
      } else if (phoneCheckResponse.statusCode != 404) {
        validationErrorPhone = "Error checking phone number";
        setState(() => isLoading = false);
        return;
      }


      // Step 3: Send OTP
      final otpResponse = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/otp/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (otpResponse.statusCode == 200) {
        RegistrationData.email = email;
        RegistrationData.phoneNum = phone;

        print("OTP sent successfully to $email");
        print("Phone number: $phone");
        print("Email: $email");


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
        SnackBar(content: Text("Error occurred: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 40),
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
                  Text("Enter your Contact Information",
                      style: TextStyle(color: accentColor, fontSize: 18)),
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
                          cursorColor: accentColor, 
                          decoration: InputDecoration(
                            hintText: 'e.g. 0123456789',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        if (validationErrorPhone.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              validationErrorPhone,
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        SizedBox(height: 20),
                        Text("Email", style: TextStyle(color: Colors.white)),
                        TextField(
                          controller: emailController,
                          style: TextStyle(color: Colors.white),
                          cursorColor: accentColor, 
                          decoration: InputDecoration(
                            hintText: 'e.g. johndoe@email.com',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (validationErrorEmail.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              validationErrorEmail,
                              style: TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: isLoading ? null : _validateAndSendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            isLoading ? "Please wait..." : "Next",
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(color: accentColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
