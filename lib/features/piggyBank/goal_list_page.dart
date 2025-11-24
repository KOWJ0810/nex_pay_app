import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for NumberFormat
import 'package:nex_pay_app/core/service/secure_storage.dart';
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
  final FlutterSecureStorage _storage = secureStorage;
  bool _isLoading = true;
  List<Map<String, dynamic>> _goals = [];

  // Formatter for Currency
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_MY',
    symbol: 'RM ',
    decimalDigits: 0, // Clean look (RM 1,200)
  );

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    final token = await _storage.read(key: 'token');

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authorization token missing")),
        );
        setState(() => _isLoading = false);
      }
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
          if (mounted) {
            setState(() {
              _goals = List<Map<String, dynamic>>.from(data['data'].map((item) => {
                    'goalId': item['piggyBankId'],
                    'goalName': item['name'],
                    'targetAmount': (item['goalAmount'] ?? 0).toDouble(),
                    'currentAmount': (item['totalSaved'] ?? 0).toDouble(),
                    'status': item['status'],
                    'targetAt': item['targetAt'],
                    'allowEarlyWithdraw': item['allowEarlyWithdraw'],
                    'reachedAt': item['reachedAt'],
                    'createdAt': item['createdAt'],
                    'updatedAt': item['updatedAt'],
                  }));
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5), // Light grey background
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: accentColor),
        label: const Text("New Goal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => context.pushNamed(RouteNames.addGoal),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchGoals,
        color: primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Modern Sliver Header ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
                onPressed: () => context.goNamed(RouteNames.account),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  "Savings Goals",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor, const Color(0xFF1A3C34)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Circle
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── 2. Content ──────────────────────────────────────────────────
            if (_isLoading)
               const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              )
            else if (_goals.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = _goals[index];
                      return _buildGoalCard(goal);
                    },
                    childCount: _goals.length,
                  ),
                ),
              ),
              
            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: const Icon(Icons.savings_outlined, size: 60, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        const Text(
          "No goals yet",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          "Start saving for your dreams today!",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final double target = goal['targetAmount'];
    final double current = goal['currentAmount'];
    final double progress = (current / (target == 0 ? 1 : target)).clamp(0.0, 1.0);
    final int percent = (progress * 100).toInt();
    
    final bool isCompleted = goal['status'] == 'COMPLETED';
    final bool isClosed = goal['status'] == 'CLOSED';

    // Status Styling
    Color statusColor;
    Color statusBg;
    String statusText = goal['status'] ?? 'ACTIVE';
    IconData statusIcon;

    if (isCompleted) {
      statusColor = Colors.green[800]!;
      statusBg = Colors.green[50]!;
      statusIcon = Icons.check_circle_rounded;
    } else if (isClosed) {
      statusColor = Colors.grey[600]!;
      statusBg = Colors.grey[100]!;
      statusIcon = Icons.lock_outline_rounded;
    } else {
      statusColor = primaryColor;
      statusBg = accentColor.withOpacity(0.3);
      statusIcon = Icons.trending_up_rounded;
    }

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteNames.goalDetail,
          extra: {
            'piggy_bank_id': goal['goalId'],
            'name': goal['goalName'],
            'goal_amount': target,
            'total_saved': current,
            'target_at': goal['targetAt'],
            'status': goal['status'],
            'allow_early_withdraw': goal['allowEarlyWithdraw'],
            'reached_at': goal['reachedAt'],
            'created_at': goal['createdAt'],
            'updated_at': goal['updatedAt'],
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal['goalName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isClosed ? Colors.grey : primaryColor,
                            decoration: isClosed ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Money Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(current),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isClosed ? Colors.grey : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "/ ${_currencyFormat.format(target)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress Bar (Full width)
            if (!isClosed)
              Container(
                height: 6,
                width: double.infinity,
                color: Colors.grey[100],
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : primaryColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Info (Footer)
            if (!isClosed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          goal['targetAt'] != null 
                            ? "Target: ${DateFormat('MMM d, y').format(DateTime.parse(goal['targetAt']))}"
                            : "No deadline",
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      "$percent%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
            // Closed State Footer
            if (isClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: const Center(
                  child: Text(
                    "This goal is closed",
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}