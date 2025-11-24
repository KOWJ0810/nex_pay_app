import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart'; // Ensure this has primaryColor & accentColor

class GoalHistoryPage extends StatefulWidget {
  final int piggyBankId;

  const GoalHistoryPage({super.key, required this.piggyBankId});

  @override
  State<GoalHistoryPage> createState() => _GoalHistoryPageState();
}

class _GoalHistoryPageState extends State<GoalHistoryPage> {
  final storage = secureStorage;
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> movements = [];

  @override
  void initState() {
    super.initState();
    _fetchMovements();
  }

  Future<void> _fetchMovements() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if(mounted) setState(() => errorMessage = 'Session expired.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/piggy-banks/${widget.piggyBankId}/movements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          if(mounted) setState(() => movements = jsonRes['data']);
        } else {
          if(mounted) setState(() => errorMessage = 'Failed to load history.');
        }
      } else {
        if(mounted) setState(() => errorMessage = 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      if(mounted) setState(() => errorMessage = 'Error: $e');
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Column(
        children: [
          // ─── CUSTOM HEADER ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.95),
                  const Color(0xFF0D201C),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    'Transaction History',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48), // Balance for centering
              ],
            ),
          ),

          // ─── CONTENT ──────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : errorMessage != null
                    ? _buildErrorState()
                    : movements.isEmpty
                        ? _buildEmptyState()
                        : _buildGroupedList(),
          ),
        ],
      ),
    );
  }

  // ─── LIST LOGIC ───────────────────────────────────────────────────────────
  Widget _buildGroupedList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      physics: const BouncingScrollPhysics(),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final move = movements[index];
        final currentDt = DateTime.parse(move['createdAt']);
        
        // Determine if we need a date header
        bool showHeader = false;
        if (index == 0) {
          showHeader = true;
        } else {
          final prevDt = DateTime.parse(movements[index - 1]['createdAt']);
          if (!_isSameDay(currentDt, prevDt)) {
            showHeader = true;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildDateHeader(currentDt),
            _buildTransactionTile(move),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String label;
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      label = "Today";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    } else {
      label = DateFormat('EEE, dd MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTransactionTile(dynamic move) {
    final isDeposit = move['type'] == 'DEPOSIT';
    final amount = (move['amount'] as num).toDouble();
    final date = DateTime.parse(move['createdAt']);
    final timeStr = DateFormat('hh:mm a').format(date);
    final reason = move['reason']?.toString() ?? (isDeposit ? 'Quick Save' : 'Withdrawal');

    // Visual Styles
    final icon = isDeposit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final iconColor = isDeposit ? const Color(0xFF4A7A00) : Colors.red[700];
    final iconBg = isDeposit ? accentColor.withOpacity(0.3) : Colors.red[50];
    final amountColor = isDeposit ? const Color(0xFF2E7D32) : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          isDeposit ? "Saved Money" : "Withdrew Funds",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(reason, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            const SizedBox(height: 4),
            Text(timeStr, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
        trailing: Text(
          "${isDeposit ? '+' : '-'} RM ${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey[300]),
          ),
          const SizedBox(height: 20),
          Text("No activity yet", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(errorMessage ?? "Unknown Error", style: const TextStyle(color: Colors.black54)),
          TextButton(
            onPressed: _fetchMovements,
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }
}