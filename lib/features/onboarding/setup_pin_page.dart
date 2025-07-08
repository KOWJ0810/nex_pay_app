// lib/features/onboarding/setup_pin_page.dart
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../widgets/custom_pin_keyboard.dart';
import 'confirm_pin_page.dart';

class SetupPinPage extends StatefulWidget {
  @override
  State<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends State<SetupPinPage> {
  List<String> _pin = [];

  void _onKeyTap(String value) {
    if (_pin.length < 6) {
      setState(() => _pin.add(value));
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
  }

  void _onClear() {
    setState(() => _pin.clear());
  }

  void _onProceed() {
    Navigator.push(
        context,
        MaterialPageRoute(
        builder: (context) => ConfirmPinPage(originalPin: _pin.join()),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 40),
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
            Text("Step 3", style: TextStyle(color: Colors.white, fontSize: 18)),
            Text("Setup your PIN", style: TextStyle(color: accentColor, fontSize: 18)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool filled = index < _pin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(bottom: BorderSide(color: accentColor, width: 3)),
                  ),
                  child: Center(
                    child: Text(filled ? '●' : '', style: TextStyle(fontSize: 20, color: primaryColor)),
                  ),
                );
              }),
            ),
            Spacer(),
            CustomPinKeyboard(
              onKeyTap: _onKeyTap,
              onBackspace: _onBackspace,
              onClear: _onClear,
              isEnabled: _pin.length == 6,
              onProceed: _onProceed,
            ),
          ],
        ),
      ),
    );
  }
}
