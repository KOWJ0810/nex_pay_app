import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({super.key});

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  final storage = secureStorage;
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Formatters
  final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final token = await storage.read(key: 'token');
      if (token == null) {
        setState(() => _errorMessage = "Session expired.");
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reports/list'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          setState(() {
            _reports = jsonRes['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to load reports.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server error: ${res.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Support Tickets",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.goNamed(RouteNames.account),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: primaryColor,
            child: Text(
              "Track your submitted issues and disputes.",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReports,
              color: accentColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _reports.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                return _buildReportCard(_reports[index]);
                              },
                            ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pushNamed(RouteNames.submitReport).then((val) {
                      if (val == true) _fetchReports(); 
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, color: accentColor),
                  label: const Text(
                    "New Report",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Builder 
  Widget _buildReportCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'PENDING';
    final title = item['title'] ?? 'No Title';
    final categoryRaw = item['category'] ?? 'General';
    final refNum = item['reportRefNum'] ?? '-';
    final dateStr = item['createdAt'];
    
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final category = _formatCategory(categoryRaw);

    // Status
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'RESOLVED':
        statusColor = Colors.green[700]!;
        statusBg = Colors.green[50]!;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = Colors.red[700]!;
        statusBg = Colors.red[50]!;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue[700]!;
        statusBg = Colors.blue[50]!;
        statusIcon = Icons.loop_rounded;
        break;
      default: // PENDING
        statusColor = Colors.orange[800]!;
        statusBg = Colors.orange[50]!;
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  refNum,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          
          const SizedBox(height: 6),

          // Category
          Row(
            children: [
              Icon(Icons.label_outline_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Date
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(date),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatCategory(String raw) {
    if (raw.isEmpty) return 'General';
    return raw.split('_')
        .map((word) => word[0] + word.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No reports found",
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Your submitted tickets will appear here.",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchReports, child: const Text("Try Again"))
        ],
      ),
    );
  }
}