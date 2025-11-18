import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../router.dart';

class CPEnterNewPinPage extends StatefulWidget {
  final String currentPin;

  const CPEnterNewPinPage({
    super.key,
    required this.currentPin,
  });

  @override
  State<CPEnterNewPinPage> createState() => _CPEenterNewPinPageState();
}

class _CPEenterNewPinPageState extends State<CPEnterNewPinPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String newPin = "";
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildPinBox(int index) {
    bool isFilled = index < newPin.length;

    return Container(
      width: 48,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? accentColor : Colors.black26,
          width: 1.5,
        ),
      ),
      child: Text(
        isFilled ? "•" : "",
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Enter New PIN",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                "Enter New PIN",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please set your new 6‑digit PIN.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),

              Opacity(
                opacity: 0,
                child: TextField(
                  focusNode: _focusNode,
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      newPin = value;
                      errorMessage = null;
                    });
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildPinBox(index)),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: newPin.length == 6
                      ? () {
                          context.pushNamed(
                            RouteNames.cpConfirmNewPin,
                            extra: {
                              "currentPin": widget.currentPin,
                              "newPin": newPin,
                            },
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        newPin.length == 6 ? accentColor : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}