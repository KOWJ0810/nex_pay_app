import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
  final storage = const FlutterSecureStorage();

  String outletName = "Loading...";
  String outletAddress = "";
  bool loading = true;

  // Temporary mock values until you provide revenue API
  double totalRevenue = 0.00;
  int totalTransactions = 0;

  String _selectedFilter = "day";

  @override
  void initState() {
    super.initState();
    _loadOutletDetails();
    _loadStatsForDay();
  }

  Future<void> _loadStatsForDay() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    final today = DateTime.now();
    final dateStr = "${today.year.toString().padLeft(4,'0')}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}";

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/analytics/outlets/${widget.outletId}/day?date=$dateStr"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          final data = jsonRes["data"];
          setState(() {
            totalRevenue = (data["totalRevenue"] ?? 0).toDouble();
            totalTransactions = data["totalTransactions"] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStatsForMonth() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    final now = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/analytics/outlets/${widget.outletId}/month?year=${now.year}&month=${now.month}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          final data = jsonRes["data"];
          setState(() {
            totalRevenue = (data["totalRevenue"] ?? 0).toDouble();
            totalTransactions = data["totalTransactions"] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStatsForYear() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    final now = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/analytics/outlets/${widget.outletId}/year?year=${now.year}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          final data = jsonRes["data"];
          setState(() {
            totalRevenue = (data["totalRevenue"] ?? 0).toDouble();
            totalTransactions = data["totalTransactions"] ?? 0;
          });
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
          setState(() {
            outletName = data["outletName"];
            outletAddress = data["outletAddress"];
            loading = false;
          });
        }
      } else {
        setState(() {
          outletName = "Error loading outlet";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        outletName = "Error: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          // ───────────────────────── HEADER ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(.85),
                  accentColor.withOpacity(.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  outletName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  outletAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(.85),
                  ),
                ),
              ],
            ),
          ),

          // ───────────────────────── CONTENT ─────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: primaryColor),
                          items: const [
                            DropdownMenuItem(
                              value: "day",
                              child: Text("Today", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                            ),
                            DropdownMenuItem(
                              value: "month",
                              child: Text("This Month", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                            ),
                            DropdownMenuItem(
                              value: "year",
                              child: Text("This Year", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedFilter = value);
                            if (value == "day") {
                              _loadStatsForDay();
                            } else if (value == "month") {
                              _loadStatsForMonth();
                            } else if (value == "year") {
                              _loadStatsForYear();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Revenue & Transactions Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statBox(
                          title: "Revenue",
                          value: "RM ${totalRevenue.toStringAsFixed(2)}",
                          icon: Icons.payments_rounded,
                        ),
                        _statBox(
                          title: "Transactions",
                          value: "$totalTransactions",
                          icon: Icons.receipt_long_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Menu Buttons
                  _menuButton(
                    icon: Icons.qr_code_rounded,
                    label: "Generate Business QR",
                    onTap: () => context.pushNamed(
                      RouteNames.home,
                      extra: {"outletId": widget.outletId},
                    ),
                  ),
                  const SizedBox(height: 16),

                  _menuButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: "Scan QR",
                    onTap: () => context.pushNamed(
                      RouteNames.merchantEnterPayAmount,
                      extra: {"outletId": widget.outletId},
                    ),
                  ),
                  const SizedBox(height: 16),

                  _menuButton(
                    icon: Icons.history_rounded,
                    label: "Transaction History",
                    onTap: () => context.pushNamed(
                      RouteNames.outletTransactionHistory,
                      extra: {"outletId": widget.outletId},
                    ),
                  ),
                  const SizedBox(height: 16),

                  _menuButton(
                    icon: Icons.account_circle_rounded,
                    label: "Back to Account",
                    onTap: () => context.goNamed(RouteNames.account),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({required String title, required String value, required IconData icon}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _menuButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 26),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}