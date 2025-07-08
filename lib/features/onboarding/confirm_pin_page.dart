// lib/features/onboarding/confirm_pin_page.dart
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../widgets/custom_pin_keyboard.dart';
import 'success_page.dart';

class ConfirmPinPage extends StatefulWidget {
  final String originalPin;

  const ConfirmPinPage({required this.originalPin, super.key});

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
  List<String> _confirmPin = [];
  String? _error;

  void _onKeyTap(String value) {
    if (_confirmPin.length < 6) {
      setState(() => _confirmPin.add(value));
    }
  }

  void _onBackspace() {
    if (_confirmPin.isNotEmpty) {
      setState(() => _confirmPin.removeLast());
    }
  }

  void _onClear() {
    setState(() {
      _confirmPin.clear();
      _error = null;
    });
  }

  void _onProceed() {
    final pin = _confirmPin.join();
    if (pin == widget.originalPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
      );
    } else {
      setState(() {
        _error = "PIN does not match. Please try again.";
        _confirmPin.clear();
      });

      // Clear error after 2.5 seconds
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _error = null);
        }
      });
    }
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
            Text("Confirm PIN", style: TextStyle(color: Colors.white, fontSize: 18)),
            Text("Re-enter your 6-digit PIN", style: TextStyle(color: accentColor, fontSize: 18)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                bool filled = index < _confirmPin.length;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _error != null ? Colors.redAccent : accentColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filled ? '●' : '',
                      style: TextStyle(fontSize: 20, color: primaryColor),
                    ),
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            Spacer(),
            CustomPinKeyboard(
              onKeyTap: _onKeyTap,
              onBackspace: _onBackspace,
              onClear: _onClear,
              isEnabled: _confirmPin.length == 6,
              onProceed: _onProceed,
            ),
          ],
        ),
      ),
    );
  }
}
