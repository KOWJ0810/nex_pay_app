import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class GoalListPage extends StatefulWidget {
  const GoalListPage({super.key});

  @override
  State<GoalListPage> createState() => _GoalListPageState();
}

class _GoalListPageState extends State<GoalListPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authorization token missing")),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/piggy-banks"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _goals = List<Map<String, dynamic>>.from(data['data'].map((item) => {
                  'goalId': item['piggyBankId'],
                  'goalName': item['name'],
                  'targetAmount': item['goalAmount'],
                  'currentAmount': item['totalSaved'],
                  'status': item['status'],
                  'targetAt': item['targetAt'],
                  'allowEarlyWithdraw': item['allowEarlyWithdraw'],
                  'reachedAt': item['reachedAt'],
                  'createdAt': item['createdAt'],
                  'updatedAt': item['updatedAt'],
                }));
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(
                  child: Text(
                    "No saving goals yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 60, bottom: 20),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => context.goNamed(RouteNames.account),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "My Saving Goals",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // keeps title centered visually
                        ],
                      ),
                    ),

                    // Goal List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          if (goal['status'] == 'CLOSED') {
                            return Card(
                              color: Colors.grey.shade200,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  goal['goalName'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Text(
                                  "Goal closed on ${goal['updatedAt']}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                trailing: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                              ),
                            );
                          }
                          final progress =
                              (goal['currentAmount'] / goal['targetAmount'])
                                  .clamp(0.0, 1.0);
                          final isCompleted = goal['status'] == 'COMPLETED';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                goal['goalName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? Colors.green
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade300,
                                    color: isCompleted
                                        ? Colors.green
                                        : primaryColor,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "RM ${goal['currentAmount']} / RM ${goal['targetAmount']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                isCompleted
                                    ? Icons.celebration_rounded
                                    : Icons.savings_rounded,
                                color:
                                    isCompleted ? Colors.green : accentColor,
                              ),
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.goalDetail,
                                  extra: {
                                    'piggy_bank_id': goal['goalId'],
                                    'name': goal['goalName'],
                                    'goal_amount': goal['targetAmount'],
                                    'total_saved': goal['currentAmount'],
                                    'target_at': goal['targetAt'],
                                    'status': goal['status'],
                                    'allow_early_withdraw': goal['allowEarlyWithdraw'],
                                    'reached_at': goal['reachedAt'],
                                    'created_at': goal['createdAt'],
                                    'updated_at': goal['updatedAt'],
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () {
          context.pushNamed(RouteNames.addGoal);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
