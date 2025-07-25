import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import 'address_info_page.dart';
import '../../models/registration_data.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ConfirmICInfoPage extends StatefulWidget {
  final String fullName;
  final String icNumber;
  final File icImage;
  final File icBackImage;

  const ConfirmICInfoPage({
    required this.fullName,
    required this.icNumber,
    required this.icImage,
    required this.icBackImage,
  });

  @override
  State<ConfirmICInfoPage> createState() => _ConfirmICInfoPageState();
}

class _ConfirmICInfoPageState extends State<ConfirmICInfoPage> {
  late TextEditingController nameController;
  late TextEditingController icController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.fullName);
    icController = TextEditingController(text: widget.icNumber);
  }

  @override
  void dispose() {
    nameController.dispose();
    icController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 3, color: accentColor),
                  SizedBox(width: 10),
                  Container(width: 80, height: 3, color: accentColor),
                  SizedBox(width: 10),
                  Container(width: 80, height: 3, color: accentColor),
                ],
              ),
              SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Text("Step 4", style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text("Confirm Your IC Details",
                        style: TextStyle(color: accentColor, fontSize: 18)),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Full Name
              Text("Full Name (as per IC)", style: TextStyle(color: Colors.white)),
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: _inputDecoration("e.g. LEE HONG WEI"),
              ),
              SizedBox(height: 20),

              // IC Number
              Text("IC Number", style: TextStyle(color: Colors.white)),
              TextField(
                controller: icController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("e.g. 040303-09-8765"),
              ),
              SizedBox(height: 30),

              // IC Images in a Row
              Text("IC Images", style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text("Front", style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(widget.icImage, height: 180, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text("Back", style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(widget.icBackImage, height: 180, fit: BoxFit.cover),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                    RegistrationData.fullName = nameController.text;
                    RegistrationData.icNum = icController.text;
                    RegistrationData.icFrontImage = widget.icImage;
                    RegistrationData.icBackImage = widget.icBackImage;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddressInfoPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Next",
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accentColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
    );
  }
}
