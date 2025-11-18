import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_config.dart';

class GoalDetailPage extends StatelessWidget {
  final int piggyBankId;
  final String name;
  final double goalAmount;
  final double totalSaved;
  final String targetAt;
  final String status;
  final bool allowEarlyWithdraw;
  final String? reachedAt;
  final String createdAt;
  final String updatedAt;

  const GoalDetailPage({
    super.key,
    required this.piggyBankId,
    required this.name,
    required this.goalAmount,
    required this.totalSaved,
    required this.targetAt,
    required this.status,
    required this.allowEarlyWithdraw,
    this.reachedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final targetDate = DateFormat('dd MMM yyyy').format(DateTime.parse(targetAt));
    final createdDate = DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt));
    final updatedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(updatedAt));
    final reachedDate = reachedAt != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(reachedAt!)) : null;
    final progress = (totalSaved / goalAmount).clamp(0.0, 1.0);
    final isGoalReached = totalSaved >= goalAmount;

    return Scaffold(
      body: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 24),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                      onPressed: () => context.goNamed(RouteNames.goalList),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Target: RM ${goalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Goal details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Goal Progress",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    color: primaryColor,
                    backgroundColor: Colors.grey.shade300,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "RM ${totalSaved.toStringAsFixed(2)} / RM ${goalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),

                  _buildDetailRow("Status", status),
                  _buildDetailRow("Allow Early Withdraw", allowEarlyWithdraw ? "Yes" : "No"),
                  _buildDetailRow("Target Date", targetDate),
                  _buildDetailRow("Created", createdDate),
                  if (reachedDate != null) _buildDetailRow("Reached At", reachedDate),
                  _buildDetailRow("Updated At", updatedDate),
                  const SizedBox(height: 30),

                  // Action buttons
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            RouteNames.goalHistory,
                            extra: {'piggy_bank_id': piggyBankId},
                          );
                        },
                        icon: const Icon(Icons.history_rounded),
                        label: const Text("View Saving History"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: implement save money logic
                          context.pushNamed(
                            RouteNames.goalSaveMoney,
                            extra: {
                              'piggy_bank_id': piggyBankId,
                            },
                          );
                        },
                        icon: const Icon(Icons.savings_rounded),
                        label: const Text("Save Money"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: (!allowEarlyWithdraw && !isGoalReached)
                            ? null
                            : () {
                                // TODO: implement claim money logic
                                context.pushNamed(
                                  RouteNames.goalClaimMoney,
                                  extra: {
                                    'piggy_bank_id': piggyBankId,
                                  },
                                );
                              },
                        icon: const Icon(Icons.attach_money_rounded),
                        label: const Text("Claim Money"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (!allowEarlyWithdraw && !isGoalReached)
                                  ? Colors.grey
                                  : accentColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirm Cancel Goal"),
                              content: const Text("Are you sure you want to cancel this saving goal? This action cannot be undone."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text("No"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                                  child: const Text("Yes, Cancel"),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          try {
                            final storage = secureStorage;
                            final token = await storage.read(key: 'token');

                            if (token == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Session expired. Please login again.")),
                              );
                              return;
                            }

                            final res = await http.patch(
                              Uri.parse('${ApiConfig.baseUrl}/piggy-banks/$piggyBankId/close'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                            );

                            if (res.statusCode == 200) {
                              final jsonRes = jsonDecode(res.body);
                              if (jsonRes['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Goal cancelled successfully.")),
                                );
                                context.goNamed(RouteNames.goalList);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(jsonRes['message'] ?? "Failed to cancel goal.")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Server error: ${res.statusCode}")),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                        icon: const Icon(Icons.cancel_rounded),
                        label: const Text("Cancel Goal"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
