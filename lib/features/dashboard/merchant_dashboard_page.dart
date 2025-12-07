// lib/features/dashboard/merchant_dashboard_page.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';

import 'package:nex_pay_app/widgets/nex_merchant_scaffold.dart';
import 'package:nex_pay_app/core/constants/api_config.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  
  // Filters
  String _selectedPeriod = 'Day'; // Day, Month, Year
  int? _selectedOutletId; 
  
  // Summary Data
  double _totalRevenue = 0.0;
  int _totalTransactions = 0;
  String _periodLabel = '';

  // Outlets Data
  List<_OutletOption> _outletOptions = [];
  bool _isLoadingOutlets = false;

  // Chart Data
  bool _isLoadingChart = false;
  List<_ChartPoint> _chartPoints = [];
  int _touchedIndex = -1; // For chart interaction

  // Errors
  String? _errorMessage;

  // Theme Colors
  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);
  static const backgroundColor = Color(0xFFF8F9FC);
  static const cardColor = Colors.white;

  final FlutterSecureStorage _secureStorage = secureStorage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadOutlets();
    await _loadSummary();
    await _loadChart();
  }


  Future<void> _loadOutlets() async {
    setState(() => _isLoadingOutlets = true);
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final json = jsonDecode(res.body);
      if (json['success'] == true) {
        final List outlets = json['data']['outlets'];
        setState(() {
          _outletOptions = [
            const _OutletOption(id: null, label: 'All Outlets'),
            ...outlets.map((e) => _OutletOption(
                  id: e['outletId'],
                  label: e['outletName'],
                ))
          ];
        });
      }
    } catch (_) {}
    setState(() => _isLoadingOutlets = false);
  }

  Future<void> _loadSummary() async {
    setState(() => _errorMessage = null);
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return;

      final now = DateTime.now();
      late Uri uri;

      String baseUrl = "${ApiConfig.baseUrl}/merchants/analytics";
      String endpoint = _selectedOutletId == null 
          ? "$baseUrl/merchant" 
          : "$baseUrl/outlets/$_selectedOutletId";

      if (_selectedPeriod == 'Day') {
        uri = Uri.parse("$endpoint/day?date=${_formatDate(now)}");
        _periodLabel = "Today, ${_formatDateDisplay(now)}";
      } else if (_selectedPeriod == 'Month') {
        uri = Uri.parse("$endpoint/month?year=${now.year}&month=${now.month}");
        _periodLabel = "${_getMonthName(now.month)} ${now.year}";
      } else {
        uri = Uri.parse("$endpoint/year?year=${now.year}");
        _periodLabel = "Year ${now.year}";
      }

      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      final json = jsonDecode(res.body);
      
      if (json['success'] == true) {
        final data = json['data'];
        setState(() {
          _totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
          _totalTransactions = data['totalTransactions'] ?? 0;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _loadChart() async {
    setState(() => _isLoadingChart = true);
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return;

      String range = _selectedPeriod.toLowerCase();
      Uri url;

      if (_selectedOutletId == null) {
        url = Uri.parse("${ApiConfig.baseUrl}/merchants/revenue?range=$range");
      } else {
        url = Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/$_selectedOutletId/revenue?range=$range");
      }

      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      final json = jsonDecode(res.body);

      if (json['success'] == true && json['data']['points'] != null) {
        List points = json['data']['points'];
        setState(() {
          _chartPoints = points
              .map((p) => _ChartPoint(
                    label: p['label'] ?? "",
                    amount: (p['amount'] ?? 0).toDouble(),
                  ))
              .toList();
        });
      } else {
        setState(() => _chartPoints = []);
      }
    } catch (_) {
      setState(() => _chartPoints = []);
    }
    setState(() => _isLoadingChart = false);
  }

  
  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  
  String _formatDateDisplay(DateTime d) => "${d.day}/${d.month}/${d.year}";

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatYAxis(double value) {
    if (value >= 1_000_000) return "${(value / 1_000_000).toStringAsFixed(1)}M";
    if (value >= 1_000) return "${(value / 1_000).toStringAsFixed(1)}K";
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return NexMerchantScaffold(
      currentIndex: 0,
      body: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            color: accentColor,
            backgroundColor: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterSection(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildChartSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _periodLabel,
              style: TextStyle(
                fontSize: 14,
                color: primaryColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: primaryColor),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period Selector 
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: ["Day", "Month", "Year"].map((period) {
              final isSelected = _selectedPeriod == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPeriod = period);
                    _loadSummary();
                    _loadChart();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        period,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? accentColor : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Outlet Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedOutletId,
              isExpanded: true,
              icon: const Icon(Icons.storefront_rounded, color: primaryColor),
              hint: const Text("Select Outlet"),
              items: _outletOptions.map((o) {
                return DropdownMenuItem(
                  value: o.id,
                  child: Text(
                    o.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedOutletId = val);
                _loadSummary();
                _loadChart();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard(
          title: "Total Revenue",
          value: "RM ${_totalRevenue.toStringAsFixed(2)}",
          icon: Icons.attach_money_rounded,
          iconBg: accentColor,
          iconColor: primaryColor,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          title: "Transactions",
          value: _totalTransactions.toString(),
          icon: Icons.receipt_long_rounded,
          iconBg: Colors.grey.shade200,
          iconColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    // Calculate chart scaling
    double maxY = 0;
    for (final p in _chartPoints) {
      if (p.amount > maxY) maxY = p.amount;
    }
    if (maxY == 0) maxY = 1;
    final double chartMaxY = maxY * 1.2;
    
    final List<double> yValues = [
      chartMaxY,
      chartMaxY * 0.5,
      0,
    ];

    // Calculate chart width for scrolling
    const double baseBarWidth = 24;
    const double barSpacing = 24;
    final int n = _chartPoints.length;
    final double computedWidth = n == 0 ? 0 : n * (baseBarWidth + barSpacing) + 40;
    final double minWidth = MediaQuery.of(context).size.width - 80;
    final double chartWidth = math.max(computedWidth, minWidth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Revenue Analytics",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              if (_isLoadingChart)
                const SizedBox(
                  height: 16, 
                  width: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _chartPoints.isEmpty && !_isLoadingChart
                ? Center(child: Text("No data available", style: TextStyle(color: Colors.grey[400])))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Y-Axis Labels
                      SizedBox(
                        width: 40,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: yValues.map((v) {
                            return Text(
                              _formatYAxis(v),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // Scrollable Chart
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SizedBox(
                            width: chartWidth,
                            child: BarChart(
                              BarChartData(
                                maxY: chartMaxY,
                                alignment: BarChartAlignment.spaceBetween,
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: chartMaxY / 2, 
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[100],
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final i = value.toInt();
                                        if (i < 0 || i >= _chartPoints.length) return const SizedBox();
                                        
                                        int skip = _chartPoints.length > 10 ? 2 : 1;
                                        if (_chartPoints.length > 20) skip = 3;
                                        
                                        if (i % skip != 0) return const SizedBox();

                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            _chartPoints[i].label,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => primaryColor,
                                    tooltipPadding: const EdgeInsets.all(8),
                                    tooltipMargin: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        '${_chartPoints[group.x.toInt()].label}\n',
                                        const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: rod.toY.toStringAsFixed(2),
                                            style: const TextStyle(
                                              color: accentColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          barTouchResponse == null ||
                                          barTouchResponse.spot == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                    });
                                  },
                                ),
                                barGroups: _chartPoints.asMap().entries.map((e) {
                                  final index = e.key;
                                  final p = e.value;
                                  final isTouched = index == _touchedIndex;

                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: p.amount,
                                        width: isTouched ? baseBarWidth + 4 : baseBarWidth,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        gradient: LinearGradient(
                                          colors: isTouched 
                                            ? [accentColor, accentColor]
                                            : [primaryColor, primaryColor.withOpacity(0.7)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: chartMaxY, 
                                          color: Colors.grey[100],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}


class _OutletOption {
  final int? id;
  final String label;

  const _OutletOption({required this.id, required this.label});
}

class _ChartPoint {
  final String label;
  final double amount;

  _ChartPoint({required this.label, required this.amount});
}