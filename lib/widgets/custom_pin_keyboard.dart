import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';

class CustomPinKeyboard extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onBackspaceLongPress;
  final VoidCallback onClear;
  final bool isEnabled;
  final VoidCallback? onProceed;

  const CustomPinKeyboard({
    Key? key,
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBackspaceLongPress,
    required this.onClear,
    this.isEnabled = false,
    this.onProceed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use viewPadding (includes system insets even when SafeArea is off)
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    // Pull the sheet slightly *below* SafeArea so it visually touches screen edge
    final tightBottom = (safeBottom - 8).clamp(0.0, double.infinity);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true, // do not add any extra bottom space
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        // Bottom padding is the *tight* value (often 0–6px on iOS with home indicator)
        padding: EdgeInsets.fromLTRB(16, 10, 16, tightBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const _KeyGrid(),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: isEnabled && onProceed != null ? onProceed : null,
                icon: Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: isEnabled ? Colors.black : Colors.black54,
                ),
                label: Text(
                  "Proceed",
                  style: TextStyle(
                    color: isEnabled ? Colors.black : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isEnabled ? accentColor : accentColor.withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['Clear', '0', '<'],
    ];

    const spacing = 8.0;

    return LayoutBuilder(
      builder: (context, c) {
        final totalGapW = spacing * 2;
        final btnW = (c.maxWidth - totalGapW) / 3;
        final btnH = (btnW * 0.9).clamp(44.0, 64.0);

        Widget rowOf(String a, String b, String c3) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _KeyBox(label: a, width: btnW, height: btnH),
              const SizedBox(width: spacing),
              _KeyBox(label: b, width: btnW, height: btnH),
              const SizedBox(width: spacing),
              _KeyBox(label: c3, width: btnW, height: btnH),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            rowOf(keys[0][0], keys[0][1], keys[0][2]),
            const SizedBox(height: spacing),
            rowOf(keys[1][0], keys[1][1], keys[1][2]),
            const SizedBox(height: spacing),
            rowOf(keys[2][0], keys[2][1], keys[2][2]),
            const SizedBox(height: spacing),
            rowOf(keys[3][0], keys[3][1], keys[3][2]),
          ],
        );
      },
    );
  }
}

class _KeyBox extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const _KeyBox({
    Key? key,
    required this.label,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '<';

    void dispatch() {
      HapticFeedback.selectionClick();
      final parent = context.findAncestorWidgetOfExactType<CustomPinKeyboard>()!;
      if (label == 'Clear') {
        parent.onClear();
      } else if (isBackspace) {
        parent.onBackspace();
      } else {
        parent.onKeyTap(label);
      }
    }

    void longPress() {
      final parent = context.findAncestorWidgetOfExactType<CustomPinKeyboard>()!;
      if (isBackspace) parent.onBackspaceLongPress();
    }

    return SizedBox(
      width: width,
      height: height,
      child: _KeyButton(
        label: label,
        isIcon: isBackspace,
        onTap: dispatch,
        onLongPress: isBackspace ? longPress : null,
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final bool isIcon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _KeyButton({
    Key? key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isIcon = false,
  }) : super(key: key);

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withOpacity(0.10);
    final bgPressed = Colors.white.withOpacity(0.16);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: _pressed ? bgPressed : bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onLongPress: widget.onLongPress,
        child: Center(
          child: widget.isIcon
              ? const Icon(Icons.backspace_outlined, color: Colors.white, size: 18)
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}