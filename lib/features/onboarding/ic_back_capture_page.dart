import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'confirm_ic_info_page.dart';
import '../../core/constants/colors.dart';

class ICBackCapturePage extends StatefulWidget {
  final String fullName;
  final String icNumber;
  final File frontImage;

  ICBackCapturePage({
    required this.fullName,
    required this.icNumber,
    required this.frontImage,
  });

  @override
  _ICBackCapturePageState createState() => _ICBackCapturePageState();
}

class _ICBackCapturePageState extends State<ICBackCapturePage> {
  File? backImage;

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        backImage = File(pickedImage.path);
      });
    }
  }

  void _goToConfirmPage() {
    if (backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please capture the back of your IC.")),
      );
      return;
    }

     Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ConfirmICInfoPage(
            fullName: widget.fullName,
            icNumber: widget.icNumber,
            icImage: widget.frontImage,
            icBackImage: backImage!, 
            ),
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
                    Text("Step 3", style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text("Capture Back of Your IC",
                        style: TextStyle(color: accentColor, fontSize: 18)),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text("Take photo of the back of your IC", style: TextStyle(color: Colors.white)),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _openCamera,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: accentColor),
                    borderRadius: BorderRadius.circular(12),
                    color: primaryColor,
                  ),
                  child: backImage == null
                      ? Center(child: Icon(Icons.credit_card, color: accentColor, size: 60))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(backImage!, fit: BoxFit.cover),
                        ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _openCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text("Open Camera", style: TextStyle(color: primaryColor)),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _goToConfirmPage,
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
}
