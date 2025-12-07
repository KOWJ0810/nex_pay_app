import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../core/constants/api_config.dart';

class AllSchedulePage extends StatefulWidget {
  final int userId; // Receiver’s ID passed from chatroom

  const AllSchedulePage({super.key, required this.userId});

  @override
  State<AllSchedulePage> createState() => _AllSchedulePageState();
}

class _AllSchedulePageState extends State<AllSchedulePage> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      isLoading = true;
    });
    try {
      const storage = secureStorage;
      final token = await storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        throw Exception('Missing auth token');
      }

      // Normalize Authorization header
      String authHeader =
          token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token';

      final uri = Uri.parse('${ApiConfig.baseUrl}/schedules/getSchedulesForUser');

      final res = await http.get(
        uri,
        headers: {
          'Authorization': authHeader,
          'Accept': 'application/json',
        },
      );

      print('GET /schedules/getSchedulesForUser -> ${res.statusCode}');
      print('Body: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode} - ${res.body}');
      }

      final Map<String, dynamic> jsonBody = jsonDecode(res.body);
      if (jsonBody['success'] != true) {
        throw Exception(jsonBody['message'] ?? 'Failed to load schedules');
      }

      final List<dynamic> data = jsonBody['data'] ?? [];

      // Filter schedules where payee.userId == receiver’s ID from chatroom and status == 'ACTIVE'
      final filtered = data
          .where((item) =>
              item['payee'] is Map<String, dynamic> &&
              item['payee']['userId'] == widget.userId &&
              (item['status'] == 'ACTIVE'))
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      setState(() {
        schedules = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedules: $e')),
        );
      }
    }
  }

  Future<void> _cancelSchedule(int scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Schedule'),
        content: const Text('Are you sure you want to cancel this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFB2DD62)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      const storage = secureStorage;
      final token = await storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing auth token');
      }

      final authHeader = token.toLowerCase().startsWith('bearer ') ? token : 'Bearer $token';
      final uri = Uri.parse('${ApiConfig.baseUrl}/schedules/$scheduleId/cancel');

      final res = await http.patch(
        uri,
        headers: {
          'Authorization': authHeader,
          'Accept': 'application/json',
        },
      );

      print('PATCH /schedules/$scheduleId/cancel -> ${res.statusCode}');
      print('Body: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule cancelled successfully.')),
          );
          _fetchSchedules();
        } else {
          throw Exception(body['message'] ?? 'Failed to cancel schedule');
        }
      } else {
        throw Exception('Failed with status ${res.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiverName = schedules.isNotEmpty
        ? (schedules.first['payee']?['userName'] ?? 'User')
        : 'User';

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
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.goNamed(RouteNames.paychat);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  // FIX: Wrapped text in Expanded to prevent overflow
                  Expanded(
                    child: Text(
                      "Schedules with $receiverName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        onPressed: () {
          context.pushNamed(
            RouteNames.scheduleDate,
            extra: {'user_id': widget.userId},
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : schedules.isEmpty
              ? const Center(
                  child: Text(
                    "You haven’t scheduled any payments for this user yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final s = schedules[index];
                    final startDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss")
                        .parse(s['startAt']);
                    final payeeName =
                        (s['payee']?['userName'] ?? 'U') as String;

                    // End date (if exists)
                    DateTime? endDate;
                    if (s['endAt'] != null) {
                      endDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss")
                          .parse(s['endAt']);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                payeeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "RM${s['amount'].toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade300, thickness: 1),
                          const SizedBox(height: 8),
                          Text(
                            "Frequency: ${s['frequency']}",
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                          Text(
                            "Start: ${DateFormat('dd MMM yyyy').format(startDate)}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          if (endDate != null)
                            Text(
                              "End: ${DateFormat('dd MMM yyyy').format(endDate)}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          const SizedBox(height: 10),
                          if (s['status'] == 'ACTIVE')
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                ),
                                icon: const Icon(Icons.cancel, size: 18),
                                label: const Text("Cancel"),
                                onPressed: () => _cancelSchedule(s['scheduleId']),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}