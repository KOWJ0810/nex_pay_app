import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'package:nex_pay_app/widgets/nex_merchant_scaffold.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  String selectedPeriod = 'Day';

  final String merchantName = 'Kenneph Electronics Store';
  final double todayRevenue = 1245.50;
  final int todayTransactions = 38;

  final Map<String, List<FlSpot>> chartData = {
    'Day': [
      FlSpot(0, 2),
      FlSpot(1, 3),
      FlSpot(2, 2.5),
      FlSpot(3, 4),
      FlSpot(4, 5.5),
      FlSpot(5, 4.8),
      FlSpot(6, 6),
    ],
    'Week': [
      FlSpot(0, 3),
      FlSpot(1, 5),
      FlSpot(2, 4),
      FlSpot(3, 7),
      FlSpot(4, 6.5),
      FlSpot(5, 8),
      FlSpot(6, 9),
    ],
    'Month': [
      FlSpot(1, 10),
      FlSpot(5, 13),
      FlSpot(10, 15),
      FlSpot(15, 18),
      FlSpot(20, 22),
      FlSpot(25, 19),
      FlSpot(30, 25),
    ],
  };

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return NexMerchantScaffold(
      currentIndex: 0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant Name Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      primaryColor,
                      Color(0xFF1C3A2E),
                      accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back,",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      merchantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Today Summary Cards
              Row(
                children: [
                  _summaryCard(
                    title: "Today's Revenue",
                    value: "RM ${todayRevenue.toStringAsFixed(2)}",
                    icon: Icons.paid_rounded,
                    color: accentColor,
                  ),
                  const SizedBox(width: 16),
                  _summaryCard(
                    title: "Transactions",
                    value: "$todayTransactions",
                    icon: Icons.swap_horiz_rounded,
                    color: Colors.orangeAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Chart Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transaction Statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedPeriod,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (value) {
                        setState(() => selectedPeriod = value!);
                      },
                      items: ['Day', 'Week', 'Month']
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData[selectedPeriod]!,
                        isCurved: true,
                        color: accentColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: accentColor.withOpacity(0.2),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 22,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102520),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}