// lib/pages/transaction_history_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/widgets/nex_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart'; 

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final Color _bg = const Color(0xFFF4F6F5);
  final TextEditingController _searchController = TextEditingController();
  
  // 0 = List View, 1 = Chart View
  bool _showChart = false;
  int _filterType = 0; // 0=All, 1=In, 2=Out

  // Date Filtering
  DateTime _selectedMonth = DateTime.now();

  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  
  // Chart Data
  List<FlSpot> _chartSpots = [];
  double _maxAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year, 
        _selectedMonth.month + monthsToAdd
      );
    });
    // Re-apply filters and chart data when month changes
    _applyFilters(); 
    _prepareChartData();
  }

  Future<void> _fetchTransactions() async {
    const storage = secureStorage;
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allTransactions = data['items'];
            _isLoading = false;
          });
          _applyFilters();
          _prepareChartData(); 
        }
      }
    } catch (e) {
      debugPrint('Error fetching tx: $e');
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        final name = (tx['counterpartyName'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(query);
        
        // 1. Role Filter
        bool matchesType = true;
        if (_filterType == 1) matchesType = tx['role'] == 'RECEIVER';
        if (_filterType == 2) matchesType = tx['role'] == 'SENDER';

        // 2. Month Filter (NEW)
        final txDate = DateTime.parse(tx['transactionDateTime']);
        bool matchesMonth = txDate.year == _selectedMonth.year && 
                            txDate.month == _selectedMonth.month;

        return matchesSearch && matchesType && matchesMonth;
      }).toList();
    });
  }

  // ─── Logic: Process Data for Chart (Updated for Monthly View) ───────────
  void _prepareChartData() {
    Map<int, double> dailyTotals = {};
    
    // Determine days in the selected month
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    
    // Initialize all days in month to 0
    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0.0;
    }

    // Loop through ALL transactions to find ones for this month
    for (var tx in _allTransactions) {
      if (tx['role'] == 'SENDER') { 
        final date = DateTime.parse(tx['transactionDateTime']);
        
        // Check if transaction belongs to selected month
        if (date.year == _selectedMonth.year && date.month == _selectedMonth.month) {
          final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
          dailyTotals[date.day] = (dailyTotals[date.day] ?? 0) + amount;
        }
      }
    }

    List<FlSpot> spots = [];
    double max = 0;
    
    // Convert map to spots
    dailyTotals.forEach((day, amount) {
      spots.add(FlSpot(day.toDouble(), amount));
      if (amount > max) max = amount;
    });

    setState(() {
      _chartSpots = spots;
      _maxAmount = max + (max * 0.2); // +20% buffer
    });
  }

  // ─── Helper to calculate total for the selected month ───────────────────
  String _calculateTotalForMonth(bool income) {
    double sum = 0;
    for (var tx in _filteredTransactions) {
      if (income && tx['role'] == 'RECEIVER') {
        sum += double.tryParse(tx['amount'].toString()) ?? 0;
      } else if (!income && tx['role'] == 'SENDER') {
        sum += double.tryParse(tx['amount'].toString()) ?? 0;
      }
    }
    return sum.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return NexScaffold(
      currentIndex: 1,
      body: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              
              // NEW: Month Selector
              _buildMonthSelector(),
              
              const SizedBox(height: 12),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _showChart 
                        ? _buildAnalyticsView() 
                        : _buildListView(),     
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            _showChart ? 'Analytics' : 'History',
            style: const TextStyle(
              color: primaryColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showChart = !_showChart),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _showChart ? accentColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
              ),
              child: Row(
                children: [
                  Icon(
                    _showChart ? Icons.list_rounded : Icons.bar_chart_rounded, 
                    color: _showChart ? primaryColor : Colors.grey[800],
                    size: 20
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showChart ? 'List' : 'Graph',
                    style: TextStyle(
                      color: _showChart ? primaryColor : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 13
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ─── NEW: Month Selector Widget ────────────────────────────────────────────
  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isFuture = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded, color: primaryColor),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isFuture ? null : () => _changeMonth(1),
              icon: Icon(
                Icons.chevron_right_rounded, 
                color: isFuture ? Colors.grey[300] : primaryColor
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Analytics View (Updated X-Axis) ──────────────────────────────────────
  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 320,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
            decoration: BoxDecoration(
              color: primaryColor, 
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spending in ${DateFormat('MMMM').format(_selectedMonth)}', 
                  style: const TextStyle(color: Colors.white54, fontSize: 14)
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Show generic days (1, 5, 10, 15...)
                              if (value % 5 == 0 && value > 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    value.toInt().toString(), 
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            interval: 1,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month).toDouble(),
                      minY: 0,
                      maxY: _maxAmount == 0 ? 100 : _maxAmount,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartSpots.isEmpty 
                            ? [const FlSpot(0, 0)] 
                            : _chartSpots,
                          isCurved: true,
                          color: accentColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [accentColor.withOpacity(0.3), accentColor.withOpacity(0.0)],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.white,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                'Day ${touchedSpot.x.toInt()}\nRM ${touchedSpot.y.toStringAsFixed(0)}',
                                const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Monthly Overview', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Spent', 'RM ${_calculateTotalForMonth(false)}', Icons.arrow_outward_rounded, Colors.orangeAccent),
              const SizedBox(width: 16),
              _statCard('Received', 'RM ${_calculateTotalForMonth(true)}', Icons.arrow_downward_rounded, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  // ─── List View ────────────────────────────────────────────────────────────
  Widget _buildListView() {
    return Column(
      children: [
        _buildFilterSegments(),
        const SizedBox(height: 12),
        _buildSearchBar(),
        const SizedBox(height: 10),
        Expanded(
          child: _filteredTransactions.isEmpty
              ? _buildEmptyState()
              : _buildGroupedList(),
        ),
      ],
    );
  }

  // ─── Helper Widgets (Segments, Search, List, Tile) ─────────────────────────
  
  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color == accentColor ? const Color(0xFF4A7A00) : Colors.orange[800], size: 20)),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSegments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]),
        child: Row(children: [_segmentButton('All', 0), _segmentButton('Incoming', 1), _segmentButton('Outgoing', 2)]),
      ),
    );
  }
  
  Widget _segmentButton(String label, int index) {
    final isSelected = _filterType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() { _filterType = index; _applyFilters(); }); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? accentColor : Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
            hintText: 'Search payments...',
            hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = _filteredTransactions[index];
        final currentDt = DateTime.parse(tx['transactionDateTime']);
        bool showHeader = false;
        if (index == 0) { showHeader = true; } else {
          final prevDt = DateTime.parse(_filteredTransactions[index - 1]['transactionDateTime']);
          if (currentDt.day != prevDt.day) showHeader = true;
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (showHeader) _buildDateHeader(currentDt), _buildTransactionTile(tx)]);
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String label = (date.year == now.year && date.month == now.month && date.day == now.day) 
        ? 'Today' : DateFormat('dd MMM yyyy').format(date);
    return Padding(padding: const EdgeInsets.only(top: 24, bottom: 12), child: Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)));
  }

  Widget _buildTransactionTile(dynamic tx) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final isReceiver = tx['role'] == 'RECEIVER';
    final name = tx['counterpartyName'] ?? 'Unknown';
    final date = DateTime.parse(tx['transactionDateTime']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: isReceiver ? accentColor.withOpacity(0.2) : Colors.red.withOpacity(0.08), shape: BoxShape.circle), child: Icon(isReceiver ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isReceiver ? const Color(0xFF4A7A00) : Colors.red[700], size: 22)),
        title: Text(name, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(DateFormat('h:mm a').format(date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: Text('${isReceiver ? '+' : '-'} RM${amount.toStringAsFixed(2)}', style: TextStyle(color: isReceiver ? const Color(0xFF4A7A00) : Colors.red[700], fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.calendar_today_rounded, size: 40, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('No transactions in ${DateFormat('MMMM').format(_selectedMonth)}', style: TextStyle(color: Colors.grey[400]))
    ]));
  }
}