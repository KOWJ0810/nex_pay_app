import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';

class ScheduleSuccessPage extends StatelessWidget {
  final int userId;
  final String userName;
  final String phoneNo;
  final DateTime startDate;
  final String frequency;
  final double amount;
  final DateTime? endDate;

  const ScheduleSuccessPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phoneNo,
    required this.startDate,
    required this.frequency,
    required this.amount,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(startDate);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(.85),
                accentColor.withOpacity(.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                "Success",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // ✅ Success Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.9),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 70,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Schedule Payment Initiated Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Recipient", userName),
                  _buildDetailRow("Phone No.", phoneNo),
                  _buildDetailRow("Amount (RM)", amount.toStringAsFixed(2)),
                  _buildDetailRow("Start Date", formattedDate),
                  if (endDate != null)
                    _buildDetailRow(
                      "End Date",
                      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(endDate!),
                    ),
                  _buildDetailRow("Frequency", frequency),
                ],
              ),
            ),

            const Spacer(),

            // 🔹 Back Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.goNamed(RouteNames.paychat),
                child: const Text(
                  "Back to PayChat",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
