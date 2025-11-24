import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class ClaimMoneySuccessPage extends StatelessWidget {
  final int piggyBankId;
  final double amount;
  final String? reason;

  const ClaimMoneySuccessPage({
    super.key,
    required this.piggyBankId,
    required this.amount,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    // Formatters
    final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: primaryColor, // Immersive Dark Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ─── 1. ANIMATED ICON ────────────────────────────────────────
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // White bg for withdrawal to differentiate slightly
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded, // Downward arrow for withdrawal
                          color: primaryColor,
                          size: 40,
                          weight: 800,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  "Withdrawal Successful!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Funds have been moved to your wallet.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                // ─── 2. RECEIPT CARD ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Total Claimed",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1.5),
                      const SizedBox(height: 24),

                      // Details
                      _ReceiptRow(label: "Date", value: dateFormat.format(DateTime.now())),
                      const SizedBox(height: 16),
                      const _ReceiptRow(label: "Destination", value: "Main Wallet"),
                      const SizedBox(height: 16),
                      if (reason != null && reason!.isNotEmpty) ...[
                        _ReceiptRow(label: "Note", value: reason!),
                        const SizedBox(height: 16),
                      ],
                      // Fake Reference ID
                      _ReceiptRow(
                        label: "Reference ID", 
                        value: "W-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}",
                        isMono: true
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ─── 3. ACTION BUTTON ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed(RouteNames.goalList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    context.pushNamed(
                      RouteNames.goalHistory,
                      extra: {'piggy_bank_id': piggyBankId},
                    );
                  },
                  child: Text(
                    "View Transaction Details",
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Widget for Rows ──────────────────────────────────────────────────
class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;

  const _ReceiptRow({
    required this.label, 
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}