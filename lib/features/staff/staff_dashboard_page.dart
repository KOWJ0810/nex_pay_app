import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import '../../router.dart';

class StaffDashboardPage extends StatefulWidget {
  final int outletId;

  const StaffDashboardPage({super.key, required this.outletId});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  final storage = secureStorage;

  String outletName = "Loading...";
  String outletAddress = "";
  bool loading = true;

  double totalRevenue = 0.00;
  int totalTransactions = 0;

  // Filter State
  String _selectedFilter = "day"; // Options: 'day', 'month', 'year'

  @override
  void initState() {
    super.initState();
    _loadOutletDetails();
    _loadStatsForDay();
  }

  // ─── API LOGIC ─────────────────────────────────────────────────────────────

  Future<void> _loadStatsForDay() async {
    await _fetchStats("day", (date) => "date=$date");
  }

  Future<void> _loadStatsForMonth() async {
    final now = DateTime.now();
    await _fetchStats("month", (_) => "year=${now.year}&month=${now.month}");
  }

  Future<void> _loadStatsForYear() async {
    final now = DateTime.now();
    await _fetchStats("year", (_) => "year=${now.year}");
  }

  Future<void> _fetchStats(String endpoint, String Function(String) queryBuilder) async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year.toString().padLeft(4,'0')}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}";

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/analytics/outlets/${widget.outletId}/$endpoint?${queryBuilder(dateStr)}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          final data = jsonRes["data"];
          if (mounted) {
            setState(() {
              totalRevenue = (data["totalRevenue"] ?? 0).toDouble();
              totalTransactions = data["totalTransactions"] ?? 0;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadOutletDetails() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/${widget.outletId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          final data = jsonRes["data"];
          if (mounted) {
            setState(() {
              outletName = data["outletName"];
              outletAddress = data["outletAddress"];
              loading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    if (filter == "day") _loadStatsForDay();
    if (filter == "month") _loadStatsForMonth();
    if (filter == "year") _loadStatsForYear();
  }

  // ─── UI BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── HEADER & PERFORMANCE CARD ──────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Green Gradient Background
                Container(
                  height: 260,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF0D201C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  loading ? "Loading..." : outletName,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!loading)
                                  Text(
                                    outletAddress,
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // Balance spacing
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Floating Performance Card
                Positioned(
                  top: 140,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Segmented Control
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _FilterTab(text: "Today", isSelected: _selectedFilter == "day", onTap: () => _onFilterChanged("day")),
                              _FilterTab(text: "Month", isSelected: _selectedFilter == "month", onTap: () => _onFilterChanged("month")),
                              _FilterTab(text: "Year", isSelected: _selectedFilter == "year", onTap: () => _onFilterChanged("year")),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Total Revenue", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    "RM ${totalRevenue.toStringAsFixed(2)}",
                                    style: const TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: Colors.grey[200]),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Transactions", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  "$totalTransactions",
                                  style: const TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Spacer for the overlap
            const SizedBox(height: 30),

            // ─── COMMAND GRID ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Slightly wider cards
                    children: [
                      _ActionCard(
                        icon: Icons.qr_code_2_rounded,
                        label: "Receive QR",
                        color: primaryColor,
                        iconColor: accentColor,
                        onTap: () => context.pushNamed(RouteNames.merchantReceiveQrCode, extra: {"outletId": widget.outletId}),
                      ),
                      _ActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        label: "Scan to Pay",
                        color: Colors.white,
                        iconColor: primaryColor,
                        onTap: () => context.pushNamed(RouteNames.merchantEnterPayAmount, extra: {"outletId": widget.outletId}),
                      ),
                      _ActionCard(
                        icon: Icons.link_rounded,
                        label: "Payment Link",
                        color: Colors.white,
                        iconColor: Colors.blueAccent,
                        onTap: () => context.pushNamed(RouteNames.showPaymentLink, extra: {"outletId": widget.outletId}),
                      ),
                      _ActionCard(
                        icon: Icons.history_rounded,
                        label: "History",
                        color: Colors.white,
                        iconColor: Colors.orangeAccent,
                        onTap: () => context.pushNamed(RouteNames.outletTransactionHistory, extra: {"outletId": widget.outletId}),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  
                  // Back to Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => context.goNamed(RouteNames.account),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text("Exit Dashboard"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER WIDGETS ──────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.grey[500],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color == primaryColor;
    
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isDark ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}