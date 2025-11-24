import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    // 1. Formatters
    final currency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');
    
    // 2. Logic
    final progress = (totalSaved / (goalAmount == 0 ? 1 : goalAmount)).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final isGoalReached = totalSaved >= goalAmount;
    final isClosed = status == 'CLOSED';
    final isCompleted = status == 'COMPLETED';
    final canWithdraw = allowEarlyWithdraw || isGoalReached;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HEADER ──────────────────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF0D201C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            ),
                            onPressed: () => context.goNamed(RouteNames.goalList),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text("Total Saved", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(totalSaved),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                      if (isClosed)
                        _StatusBadge(label: "CLOSED", color: Colors.grey)
                      else if (isCompleted)
                        _StatusBadge(label: "COMPLETED", color: Colors.green),
                    ],
                  ),
                ),
                // Floating Progress Card
                Positioned(
                  bottom: -60,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Goal Progress", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                            Text("$percent%", style: TextStyle(color: isCompleted ? Colors.green : primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.grey[100],
                            color: isCompleted ? Colors.green : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("0%", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text("Target: ${currency.format(goalAmount)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // ─── CONTENT BODY ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoGrid(dateFormat, isClosed),
                  
                  const SizedBox(height: 30),

                  if (!isClosed) ...[
                    // ─── NEW: HIERARCHICAL ACTIONS ──────────────────────────
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                    const SizedBox(height: 16),
                    
                    // 1. HERO BUTTON (Save Money)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.pushNamed(RouteNames.goalSaveMoney, extra: {'piggy_bank_id': piggyBankId}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_circle_rounded, color: accentColor),
                            SizedBox(width: 12),
                            Text("Add Money to Goal", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 2. SECONDARY ACTIONS ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Nice spacing
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SecondaryActionBtn(
                          icon: Icons.history_rounded,
                          label: "History",
                          color: Colors.blue[50]!,
                          iconColor: Colors.blue[700]!,
                          onTap: () => context.pushNamed(RouteNames.goalHistory, extra: {'piggy_bank_id': piggyBankId}),
                        ),
                        _SecondaryActionBtn(
                          icon: Icons.download_rounded,
                          label: "Withdraw",
                          // Dim styling if disabled
                          color: canWithdraw ? Colors.green[50]! : Colors.grey[100]!,
                          iconColor: canWithdraw ? Colors.green[700]! : Colors.grey[400]!,
                          onTap: canWithdraw 
                              ? () => context.pushNamed(RouteNames.goalClaimMoney, extra: {'piggy_bank_id': piggyBankId})
                              : null, // Disable tap
                        ),
                        _SecondaryActionBtn(
                          icon: Icons.close_rounded,
                          label: "Close Goal",
                          color: Colors.red[50]!,
                          iconColor: Colors.red[700]!,
                          onTap: () => _confirmCancel(context),
                        ),
                      ],
                    ),
                  ] else ...[
                     // If Closed, only History is relevant
                     SizedBox(
                       width: double.infinity,
                       height: 50,
                       child: OutlinedButton.icon(
                         onPressed: () => context.pushNamed(RouteNames.goalHistory, extra: {'piggy_bank_id': piggyBankId}),
                         icon: const Icon(Icons.history, color: primaryColor),
                         label: const Text("View Transaction History", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                         style: OutlinedButton.styleFrom(
                           side: const BorderSide(color: primaryColor),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                         ),
                       ),
                     )
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildInfoGrid(DateFormat fmt, bool isClosed) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _infoRow(Icons.calendar_month_rounded, "Target Date", fmt.format(DateTime.parse(targetAt))),
          const Divider(height: 24),
          _infoRow(
            Icons.verified_user_outlined, 
            "Withdrawal", 
            allowEarlyWithdraw ? "Anytime" : "On Target Only",
            valueColor: allowEarlyWithdraw ? Colors.green : Colors.orange
          ),
          if (reachedAt != null) ...[
            const Divider(height: 24),
            _infoRow(Icons.flag_rounded, "Reached On", fmt.format(DateTime.parse(reachedAt!)), valueColor: Colors.green),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor ?? primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  // ─── Logic ─────────────────────────────────────────────────────────────────
  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Close Goal?"),
        content: const Text("Funds will be returned to your main wallet. This cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Keep Goal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Close Goal"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    
    // Execute Cancel Logic
    try {
      final storage = secureStorage;
      final token = await storage.read(key: 'token');
      if (token == null) return;

      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/piggy-banks/$piggyBankId/close'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (context.mounted) {
        if (res.statusCode == 200) {
          final jsonRes = jsonDecode(res.body);
          if (jsonRes['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Goal closed successfully.")));
            context.goNamed(RouteNames.goalList);
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to close goal.")));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

// ─── Custom Widgets for New Layout ───────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _SecondaryActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  const _SecondaryActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Opacity effect if disabled
    final isDisabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color, // Light pastel background
                borderRadius: BorderRadius.circular(20), // Soft squircle
                boxShadow: isDisabled ? null : [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            )
          ],
        ),
      ),
    );
  }
}