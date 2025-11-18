// lib/features/dashboard/merchant_dashboard_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';

import 'package:nex_pay_app/router.dart';
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
  int? _selectedOutletId; // null = all outlets
  String _selectedOutletLabel = 'All outlets';

  // Summary
  double _totalRevenue = 0.0;
  int _totalTransactions = 0;
  String _periodLabel = '';

  // Outlets
  List<_OutletOption> _outletOptions = [];
  bool _isLoadingOutlets = false;

  // Chart
  bool _isLoadingChart = false;
  List<_ChartPoint> _chartPoints = [];

  // Errors
  String? _errorMessage;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  final FlutterSecureStorage _secureStorage = secureStorage;

  @override
  void initState() {
    super.initState();
    _loadOutlets();
    _loadSummary();
    _loadChart();
  }

  //---------------------------------------------------------------------------
  // LOAD OUTLETS
  //---------------------------------------------------------------------------
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
            const _OutletOption(id: null, label: 'All outlets'),
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

  //---------------------------------------------------------------------------
  // LOAD SUMMARY (Already implemented earlier)
  //---------------------------------------------------------------------------
  Future<void> _loadSummary() async {
    setState(() => _errorMessage = null);

    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return;

      final now = DateTime.now();
      late Uri uri;

      if (_selectedOutletId == null) {
        // Merchant aggregated
        if (_selectedPeriod == 'Day') {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/merchant/day?date=${_formatDate(now)}");
          _periodLabel = _formatDate(now);
        } else if (_selectedPeriod == 'Month') {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/merchant/month?year=${now.year}&month=${now.month}");
          _periodLabel = "${now.year}-${now.month}";
        } else {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/merchant/year?year=${now.year}");
          _periodLabel = "${now.year}";
        }
      } else {
        // Outlet
        final id = _selectedOutletId!;
        if (_selectedPeriod == 'Day') {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/day?date=${_formatDate(now)}");
          _periodLabel = _formatDate(now);
        } else if (_selectedPeriod == 'Month') {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/month?year=${now.year}&month=${now.month}");
          _periodLabel = "${now.year}-${now.month}";
        } else {
          uri = Uri.parse(
              "${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/year?year=${now.year}");
          _periodLabel = "${now.year}";
        }
      }

      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

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

  String _formatDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  //---------------------------------------------------------------------------
  // LOAD CHART DATA
  //---------------------------------------------------------------------------
  Future<void> _loadChart() async {
    setState(() => _isLoadingChart = true);

    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) return;

      String range = _selectedPeriod.toLowerCase(); // day / month / year
      Uri url;

      if (_selectedOutletId == null) {
        // All outlets
        url = Uri.parse(
            "${ApiConfig.baseUrl}/merchants/revenue?range=$range");
      } else {
        // Specific outlet
        url = Uri.parse(
            "${ApiConfig.baseUrl}/merchants/outlets/${_selectedOutletId}/revenue?range=$range");
      }

      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

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

  //---------------------------------------------------------------------------
  // BUILD UI
  //---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return NexMerchantScaffold(
      currentIndex: 0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(),
              const SizedBox(height: 18),
              _filtersCard(),
              const SizedBox(height: 18),
              _summarySection(),
              const SizedBox(height: 26),
              _chartSection(),
            ],
          ),
        ),
      ),
    );
  }

  //---------------------------------------------------------------------------
  // UI WIDGETS
  //---------------------------------------------------------------------------

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(.9),
            accentColor.withOpacity(.9),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(Icons.storefront_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Merchant Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Period: $_periodLabel",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            _selectedOutletId == null
                ? "All outlets"
                : _selectedOutletLabel,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filters",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdownContainer(
                  label: "Period",
                  child: DropdownButton(
                    value: _selectedPeriod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: "Day", child: Text("Day")),
                      DropdownMenuItem(value: "Month", child: Text("Month")),
                      DropdownMenuItem(value: "Year", child: Text("Year")),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _loadSummary();
                      _loadChart();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownContainer(
                  label: "Outlet",
                  child: DropdownButton(
                    value: _selectedOutletId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _outletOptions
                        .map((o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(o.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOutletId = value;
                        _selectedOutletLabel = _outletOptions
                            .firstWhere((e) => e.id == value)
                            .label;
                      });
                      _loadSummary();
                      _loadChart();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summarySection() {
    return Row(
      children: [
        _summaryCard(
          title: "Revenue",
          value: "RM ${_totalRevenue.toStringAsFixed(2)}",
          color: accentColor,
          icon: Icons.paid_rounded,
        ),
        const SizedBox(width: 16),
        _summaryCard(
          title: "Transactions",
          value: _totalTransactions.toString(),
          color: Colors.orangeAccent,
          icon: Icons.swap_horiz_rounded,
        )
      ],
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  //---------------------------------------------------------------------------
  // CHART SECTION
  //---------------------------------------------------------------------------
  Widget _chartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Revenue chart",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: primaryColor)),
        const SizedBox(height: 12),
        Container(
          height: 260,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: _isLoadingChart
              ? const Center(child: CircularProgressIndicator())
              : _chartPoints.isEmpty
                  ? const Center(child: Text("No data"))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: (_chartPoints.length * 50).toDouble(),
                        child: BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 35,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black54),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (index, meta) {
                                    final i = index.toInt();
                                    if (i < 0 || i >= _chartPoints.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        _chartPoints[i].label,
                                        style: const TextStyle(
                                            fontSize: 9, color: Colors.black87),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: _chartPoints.asMap().entries.map((e) {
                              int index = e.key;
                              final p = e.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: p.amount,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(4),
                                    color: accentColor,
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
    );
  }

  //---------------------------------------------------------------------------
  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12.withOpacity(0.12)),
          ),
          child: child,
        ),
      ],
    );
  }
}

//---------------------------------------------------------------------------
// MODELS
//---------------------------------------------------------------------------

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