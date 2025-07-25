import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ic_back_capture_page.dart';
import '../../core/constants/colors.dart';

class ICVerificationPage extends StatefulWidget {
  @override
  State<ICVerificationPage> createState() => _ICVerificationPageState();
}

class _ICVerificationPageState extends State<ICVerificationPage> {
  File? icImage;
  String detectedName = '';
  String detectedIC = '';
  List<String> excludedKeywords = [];

  @override
  void initState() {
    super.initState();
    _loadExcludedKeywords();
  }

  Future<void> _loadExcludedKeywords() async {
    final content = await rootBundle.loadString('assets/excluded_words.txt');
    final lines = content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() {
      excludedKeywords = lines;
    });
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      final imageFile = File(pickedImage.path);
      setState(() {
        icImage = imageFile;
      });

      await _extractTextFromImage(imageFile);
    }
  }

  Future<void> _extractTextFromImage(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

  final fullText = recognizedText.text;
  print('Extracted Text:\n$fullText');

  // Extract IC number
  final icRegex = RegExp(r'\d{6}-\d{2}-\d{4}|\d{12}');
  final icMatch = icRegex.firstMatch(fullText);

  // Print all non-excluded lines (for debugging)
  print('--- Non-excluded lines ---');
  recognizedText.blocks
      .expand((block) => block.lines)
      .where((line) {
        final text = line.text.trim();
        final upperLine = text.toUpperCase().replaceAll(' ', '');
        return RegExp(r'^[A-Z\s]{6,}$').hasMatch(text) &&
            !excludedKeywords.any((keyword) =>
                upperLine.contains(keyword.toUpperCase().replaceAll(' ', ''))) &&
            !RegExp(r'\d').hasMatch(text);
      })
      .forEach((line) {
        print('${line.text.trim()}  (height: ${line.boundingBox.height.toStringAsFixed(2)})');
      });

  // Find first valid name line
  final nameMatch = recognizedText.blocks
      .expand((block) => block.lines)
      .where((line) {
        final text = line.text.trim();
        final upperLine = text.toUpperCase().replaceAll(' ', '');
        return RegExp(r'^[A-Z\s]{6,}$').hasMatch(text) &&
            !excludedKeywords.any((keyword) =>
                upperLine.contains(keyword.toUpperCase().replaceAll(' ', ''))) &&
            !RegExp(r'\d').hasMatch(text) &&
            line.boundingBox.height > 300;
      })
      .map((line) => line.text.trim())
      .firstWhere((_) => true, orElse: () => '');

  setState(() {
    detectedIC = icMatch?.group(0) ?? '';
    detectedName = nameMatch;
  });

  await textRecognizer.close();
}

  void _goToConfirmPage() {
    if (icImage == null || detectedIC.isEmpty || detectedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please make sure IC is clearly visible and try again.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ICBackCapturePage(
          fullName: detectedName,
          icNumber: detectedIC,
          frontImage: icImage!,
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
                    Text("Step 2", style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text("Capture Your Identity Card (IC)",
                        style: TextStyle(color: accentColor, fontSize: 18)),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text("Take photo of your IC", style: TextStyle(color: Colors.white)),
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
                  child: icImage == null
                      ? Center(child: Icon(Icons.credit_card, color: accentColor, size: 60))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(icImage!, fit: BoxFit.cover),
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