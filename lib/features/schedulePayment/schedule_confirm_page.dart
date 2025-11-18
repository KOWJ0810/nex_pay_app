import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'dart:convert';
import '../../core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';

class ScheduleConfirmPage extends StatelessWidget {
  final int userId;
  final String userName;
  final String phoneNo;
  final DateTime startDate;
  final String frequency;
  final double amount;
  final DateTime? endDate;

  const ScheduleConfirmPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phoneNo,
    required this.startDate,
    required this.frequency,
    required this.amount,
    this.endDate,
  });

  Future<void> _confirmSchedule(BuildContext context) async {
    final storage = secureStorage;
    try {
      final token = await storage.read(key: 'token');
      final url = Uri.parse('${ApiConfig.baseUrl}/schedules');
      final body = jsonEncode({
        'payeeUserId': userId,
        'amount': amount,
        'frequency': frequency,
        'startAt': startDate.toIso8601String(),
        if (endDate != null) 'endAt': endDate!.toIso8601String(),
      });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      final Map<String, dynamic> resp = jsonDecode(response.body);
      if (resp['success'] == true) {
            // Go to schedule success page with extras
            context.goNamed(RouteNames.scheduleSuccess, extra: {
              'user_id': userId,
              'user_name': userName,
              'phone_no': phoneNo,
              'start_date': startDate,
              'frequency': frequency,
              'amount': amount,
              'end_date': endDate,
            });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp['message'] ?? 'Failed to schedule.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
        ),
      );
    }
  }

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.goNamed('schedule-amount');
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Confirm Schedule",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Confirmation Card
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
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: accentColor.withOpacity(0.9),
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      phoneNo,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1.2),
                  _buildDetailRow("Start Date", formattedDate),
                  if (endDate != null)
                    _buildDetailRow(
                      "End Date",
                      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(endDate!),
                    ),
                  _buildDetailRow("Frequency", frequency),
                  _buildDetailRow(
                    "Amount (RM)",
                    amount.toStringAsFixed(2),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔹 Confirm Button
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
                onPressed: () => _confirmSchedule(context),
                child: const Text(
                  "Confirm Schedule",
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}