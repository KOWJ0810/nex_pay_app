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

class WithdrawListPage extends StatefulWidget {
  const WithdrawListPage({super.key});

  @override
  State<WithdrawListPage> createState() => _WithdrawListPageState();
}

class _WithdrawListPageState extends State<WithdrawListPage> {
  final storage = secureStorage;
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Formatters
  final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
  final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
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
        Uri.parse('${ApiConfig.baseUrl}/merchants/claims/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          setState(() {
            _history = jsonRes['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to load history.";
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
          "Withdrawals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
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
          // ─── Header Summary ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: primaryColor,
            child: Text(
              "Track your fund withdrawal requests and status.",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ),

          // ─── List Content ───
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchHistory,
              color: accentColor,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryColor))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _history.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                return _buildHistoryCard(_history[index]);
                              },
                            ),
            ),
          ),

          // ─── Bottom Button ───
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
                    context.pushNamed(RouteNames.makeWithdrawal).then((val) {
                      // Refresh if returned with success
                      if (val == true) _fetchHistory();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, color: accentColor),
                  label: const Text(
                    "Make Withdrawal",
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

  // ─── Card Builder ───
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'PENDING';
    final amount = double.tryParse(item['amount'].toString()) ?? 0.0;
    final dateStr = item['requestDate'];
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    
    // Check Claim Type
    final claimType = item['claimType'];
    final isWallet = claimType == 'WALLET_TRANSFER';

    // Dynamic Labels & Icons based on Claim Type
    final titleText = isWallet ? "Wallet Transfer" : "Bank Transfer";
    final titleIcon = isWallet ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded;
    final detailInfo = isWallet ? "Personal Wallet" : (item['bankDetails'] ?? 'Unknown Bank');

    // Status Styling
    Color statusColor;
    Color statusBg;
    IconData statusBadgeIcon;

    switch (status) {
      case 'APPROVED':
      case 'COMPLETED':
        statusColor = Colors.green[700]!;
        statusBg = Colors.green[50]!;
        statusBadgeIcon = Icons.check_circle_rounded;
        break;
      case 'REJECTED':
        statusColor = Colors.red[700]!;
        statusBg = Colors.red[50]!;
        statusBadgeIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange[800]!;
        statusBg = Colors.orange[50]!;
        statusBadgeIcon = Icons.access_time_filled_rounded;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(titleIcon, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                      ),
                      Text(
                        dateFormat.format(date),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusBadgeIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Details", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      detailInfo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),

              // Amount Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Amount", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No withdrawals yet",
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Your withdrawal history will appear here.",
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
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchHistory, child: const Text("Try Again"))
        ],
      ),
    );
  }
}