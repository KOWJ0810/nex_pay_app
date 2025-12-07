import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/colors.dart';

class ReportSuccessPage extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ReportSuccessPage({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    // Format Date
    final dateStr = reportData['createdAt'] ?? DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr);
    final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

    // Format Category
    String category = (reportData['category'] ?? 'General')
        .toString()
        .split('_')
        .map((w) => w[0] + w.substring(1).toLowerCase())
        .join(' ');

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Animated Icon
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
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: primaryColor, size: 48),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                const Text(
                  "Report Submitted",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Our support team has received your ticket.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "We usually respond within 24 hours. You can see the status of your ticket in the 'Suport Tickets' section.",
                                style: TextStyle(color: Colors.blue[900], fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1.5),
                      const SizedBox(height: 16),

                      _InfoRow(label: "Ticket ID", value: reportData['reportRefNum'] ?? '-', isMono: true),
                      const SizedBox(height: 12),
                      _InfoRow(label: "Category", value: category),
                      const SizedBox(height: 12),
                      _InfoRow(label: "Date", value: dateFormat.format(date)),
                      const SizedBox(height: 12),
                      _InfoRow(label: "Status", value: reportData['status'] ?? 'PENDING', valueColor: Colors.orange),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop(true); 
                      } else {
                        context.goNamed(RouteNames.reportList);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Return to Tickets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final Color? valueColor;

  const _InfoRow({
    required this.label, 
    required this.value, 
    this.isMono = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF102520), 
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