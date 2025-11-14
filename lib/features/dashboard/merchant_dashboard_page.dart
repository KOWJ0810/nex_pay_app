// lib/features/dashboard/merchant_dashboard_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

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
  bool _isLoadingSummary = false;
  bool _isLoadingOutlets = false;
  String? _errorMessage;

  // Demo merchant name (could be wired to /merchants/user in future)
  final String merchantName = 'Kenneph Electronics Store';

  // Static chart data (still demo, not API driven)
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
    'Month': [
      FlSpot(1, 10),
      FlSpot(5, 13),
      FlSpot(10, 15),
      FlSpot(15, 18),
      FlSpot(20, 22),
      FlSpot(25, 19),
      FlSpot(30, 25),
    ],
    'Year': [
      FlSpot(1, 20),
      FlSpot(3, 25),
      FlSpot(6, 30),
      FlSpot(9, 40),
      FlSpot(12, 50),
    ],
  };

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadOutlets();
    _loadSummary(); // default: Day + All outlets (merchant scope)
  }

  Future<void> _loadOutlets() async {
    setState(() {
      _isLoadingOutlets = true;
    });

    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoadingOutlets = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true &&
            jsonRes['data'] != null &&
            jsonRes['data']['outlets'] != null) {
          final List outlets = jsonRes['data']['outlets'];
          final options = <_OutletOption>[
            const _OutletOption(id: null, label: 'All outlets'),
            ...outlets.map((e) {
              return _OutletOption(
                id: e['outletId'] as int,
                label: e['outletName'] as String? ?? 'Outlet ${e['outletId']}',
              );
            }),
          ];
          setState(() {
            _outletOptions = options;
          });
        } else {
          setState(() {
            _outletOptions = const [
              _OutletOption(id: null, label: 'All outlets'),
            ];
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load outlets (${res.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading outlets: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOutlets = false;
        });
      }
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _errorMessage = null;
    });

    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoadingSummary = false;
        });
        return;
      }

      final now = DateTime.now();
      late Uri uri;

      if (_selectedOutletId == null) {
        // MERCHANT scope
        if (_selectedPeriod == 'Day') {
          final dateStr =
              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/merchant/day?date=$dateStr');
          _periodLabel = dateStr;
        } else if (_selectedPeriod == 'Month') {
          final year = now.year;
          final month = now.month.toString().padLeft(2, '0');
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/merchant/month?year=$year&month=$month');
          _periodLabel = '$year-$month';
        } else {
          final year = now.year;
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/merchant/year?year=$year');
          _periodLabel = '$year';
        }
      } else {
        // OUTLET scope
        final id = _selectedOutletId!;
        if (_selectedPeriod == 'Day') {
          final dateStr =
              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/day?date=$dateStr');
          _periodLabel = dateStr;
        } else if (_selectedPeriod == 'Month') {
          final year = now.year;
          final month = now.month.toString().padLeft(2, '0');
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/month?year=$year&month=$month');
          _periodLabel = '$year-$month';
        } else {
          final year = now.year;
          uri = Uri.parse(
              '${ApiConfig.baseUrl}/merchants/analytics/outlets/$id/year?year=$year');
          _periodLabel = '$year';
        }
      }

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true && jsonRes['data'] != null) {
          final data = jsonRes['data'];
          setState(() {
            _totalRevenue =
                (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
            _totalTransactions = data['totalTransactions'] as int? ?? 0;
          });
        } else {
          setState(() {
            _totalRevenue = 0.0;
            _totalTransactions = 0;
            _errorMessage = 'No analytics data available.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load summary (${res.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading summary: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
        });
      }
    }
  }

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
              // ─────────── Merchant Header Card ───────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(.9),
                      accentColor.withOpacity(.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          child: const Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Merchant dashboard",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                merchantName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // You can route to merchant settings or analytics detail
                          },
                          icon: const Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(
                          backgroundColor: Colors.white.withOpacity(0.16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          label: Text(
                            'Period: ${_periodLabel.isNotEmpty ? _periodLabel : _selectedPeriod}',
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Chip(
                          backgroundColor: Colors.white.withOpacity(0.16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          label: Text(
                            _selectedOutletId == null
                                ? 'All outlets'
                                : _selectedOutletLabel,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ─────────── Filters Card (Period + Outlet) ───────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownContainer(
                            label: 'Period',
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedPeriod = value;
                                });
                                _loadSummary();
                              },
                              items: const ['Day', 'Month', 'Year']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownContainer(
                            label: 'Outlet',
                            child: _isLoadingOutlets
                                ? const SizedBox(
                                    height: 24,
                                    child: Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : DropdownButton<int?>(
                                    value: _selectedOutletId,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                    ),
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedOutletId = value;
                                        _selectedOutletLabel = _outletOptions
                                            .firstWhere(
                                              (o) => o.id == value,
                                              orElse: () =>
                                                  const _OutletOption(
                                                      id: null,
                                                      label: 'All outlets'),
                                            )
                                            .label;
                                      });
                                      _loadSummary();
                                    },
                                    items: _outletOptions
                                        .map(
                                          (o) => DropdownMenuItem<int?>(
                                            value: o.id,
                                            child: Text(o.label),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ─────────── Summary Cards ───────────
              if (_isLoadingSummary)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              else
                Row(
                  children: [
                    _summaryCard(
                      title: _selectedOutletId == null
                          ? "Total revenue\n(all outlets)"
                          : "Revenue\n(${_selectedOutletLabel})",
                      value: "RM ${_totalRevenue.toStringAsFixed(2)}",
                      icon: Icons.paid_rounded,
                      color: accentColor,
                    ),
                    const SizedBox(width: 16),
                    _summaryCard(
                      title: "Transactions",
                      value: "$_totalTransactions",
                      icon: Icons.swap_horiz_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),

              const SizedBox(height: 26),

              // ─────────── Chart Section ───────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Transaction statistics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  Icon(
                    Icons.show_chart_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                height: 250,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData[_selectedPeriod] ??
                            chartData['Day']!, // fallback
                        isCurved: true,
                        color: accentColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: accentColor.withOpacity(0.18),
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

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              radius: 20,
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.left,
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

class _OutletOption {
  final int? id;
  final String label;

  const _OutletOption({required this.id, required this.label});
}