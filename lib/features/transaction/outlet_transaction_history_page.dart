import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';

class OutletTransactionHistoryPage extends StatefulWidget {
  final int outletId;

  const OutletTransactionHistoryPage({super.key, required this.outletId});

  @override
  State<OutletTransactionHistoryPage> createState() =>
      _OutletTransactionHistoryPageState();
}

class _OutletTransactionHistoryPageState
    extends State<OutletTransactionHistoryPage> {
  final storage = secureStorage;

  bool isLoading = true;
  bool hasError = false;
  List<dynamic> transactions = [];

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  @override
  void initState() {
    super.initState();
    _fetchOutletTransactions();
  }

  Future<void> _fetchOutletTransactions() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final token = await storage.read(key: 'token');

      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/merchants/transactions/outlets/${widget.outletId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes['success'] == true) {
          setState(() {
            transactions = jsonRes['items'] ?? [];
          });
        } else {
          setState(() => hasError = true);
        }
      } else {
        setState(() => hasError = true);
      }
    } catch (e) {
      setState(() => hasError = true);
    }

    setState(() => isLoading = false);
  }

  String formatDate(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Outlet Transactions",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // BODY
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : hasError
              ? const Center(child: Text("Failed to load transactions"))
              : transactions.isEmpty
                  ? const Center(
                      child: Text(
                        "No transactions found",
                        style:
                            TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOutletTransactions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final t = transactions[index];

                          return GestureDetector(
                            onTap: () {
                               context.pushNamed(
                                  RouteNames.outletTransactionDetail,
                                  extra: {
                                    'transactionId': t['transactionId'],
                                  },
                                );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // REF NUMBER & AMOUNT
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        t['transactionRefNum'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        "RM ${t['amount']?.toStringAsFixed(2) ?? '0.00'}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // Staff name
                                  Text(
                                    "Staff: ${t['staffUserName'] ?? 'Unknown'}",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),

                                  const SizedBox(height: 4),

                                  // Payer name
                                  Text(
                                    "Customer: ${t['payerUserName'] ?? ''} (${t['payerPhone'] ?? ''})",
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                  ),

                                  const SizedBox(height: 6),

                                  // Date
                                  Text(
                                    formatDate(t['transactionDateTime']),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}