import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/colors.dart';

class WithdrawBankSuccessPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const WithdrawBankSuccessPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Formatters
    final currency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
    final dateStr = data['requestDate'] ?? DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr);
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Icon (Clock/Pending)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                          ],
                        ),
                        child: const Icon(Icons.access_time_filled_rounded, color: Colors.orange, size: 48),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                const Text(
                  "Request Submitted",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your bank withdrawal is pending approval.",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),

                const SizedBox(height: 32),

                // 2. Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Amount Requested",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(data['amount']),
                        style: const TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Processing Time Alert
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Processing time: 1-3 working days for admin approval.",
                                style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1.5),
                      const SizedBox(height: 16),

                      _ReceiptRow(label: "Date", value: dateFormat.format(date)),
                      const SizedBox(height: 12),
                      _ReceiptRow(label: "Bank Details", value: data['bankDetails'] ?? '-'),
                      const SizedBox(height: 12),
                      _ReceiptRow(label: "Reference ID", value: "#${data['id']}", isMono: true),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed(RouteNames.merchantDashboard), // Back to dashboard
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;

  const _ReceiptRow({required this.label, required this.value, this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}