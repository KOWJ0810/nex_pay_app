// lib/widgets/custom_pin_keyboard.dart
import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class CustomPinKeyboard extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool isEnabled;
  final VoidCallback? onProceed;

  const CustomPinKeyboard({
    required this.onKeyTap,
    required this.onBackspace,
    required this.onClear,
    this.isEnabled = false,
    this.onProceed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      'Clear', '0', '<'
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8, // smaller height
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final isClear = key == 'Clear';
              final isBackspace = key == '<';

              return GestureDetector(
                onTap: () {
                  if (isClear) {
                    onClear();
                  } else if (isBackspace) {
                    onBackspace();
                  } else {
                    onKeyTap(key);
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isBackspace
                        ? Icon(Icons.backspace_outlined, color: primaryColor)
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: 22,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isEnabled ? primaryColor : Colors.grey[600],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextButton(
              onPressed: isEnabled && onProceed != null ? onProceed : null,
              child: Text(
                "Proceed",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}