import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import 'setup_pin_page.dart';

class SelfiePage extends StatefulWidget {
  @override
  State<SelfiePage> createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> {
  File? selfieImage;

  Future<void> takeSelfie() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);

    if (pickedImage != null) {
      setState(() {
        selfieImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Bar
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
              SizedBox(height: 40),
              Text("Scan Your Face!", style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              CircleAvatar(
                radius: 90,
                backgroundColor: Colors.white12,
                backgroundImage: selfieImage != null ? FileImage(selfieImage!) : null,
                child: selfieImage == null
                    ? Icon(Icons.person, color: accentColor, size: 60)
                    : null,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: takeSelfie,
                icon: Icon(Icons.camera_alt, color: primaryColor),
                label: Text("Take Photo", style: TextStyle(color: primaryColor)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SetupPinPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text("Next", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}