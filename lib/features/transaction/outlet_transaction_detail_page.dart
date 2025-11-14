import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';

class OutletTransactionDetailPage extends StatefulWidget {
  final int transactionId;

  const OutletTransactionDetailPage({super.key, required this.transactionId});

  @override
  State<OutletTransactionDetailPage> createState() =>
      _OutletTransactionDetailPageState();
}

class _OutletTransactionDetailPageState
    extends State<OutletTransactionDetailPage> {
  final storage = const FlutterSecureStorage();

  bool isLoading = true;
  bool hasError = false;
  Map<String, dynamic>? transaction;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
  }

  Future<void> _loadTransactionDetail() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final token = await storage.read(key: "token");

      final res = await http.get(
        Uri.parse(
            "${ApiConfig.baseUrl}/merchants/transactions/${widget.transactionId}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes["success"] == true) {
          setState(() => transaction = jsonRes);
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

  Widget _detailTile(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Transaction Detail",
          style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : hasError || transaction == null
              ? const Center(
                  child: Text(
                    "Failed to load transaction.",
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // REF NUMBER + AMOUNT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transaction!["transactionRefNum"] ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              "RM ${(transaction!["amount"] ?? 0).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _detailTile("Status", transaction!["status"] ?? ""),
                        _detailTile("Payment Type", transaction!["paymentType"] ?? ""),
                        _detailTile(
                            "Date & Time",
                            formatDate(
                                transaction!["transactionDateTime"] ?? "")),

                        const SizedBox(height: 20),
                        const Divider(),

                        const SizedBox(height: 12),
                        const Text(
                          "Merchant Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _detailTile(
                            "Merchant Name", transaction!["merchantName"] ?? ""),
                        _detailTile(
                            "Outlet Name", transaction!["outletName"] ?? ""),

                        const SizedBox(height: 20),
                        const Divider(),

                        const SizedBox(height: 12),
                        const Text(
                          "Staff Involved",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _detailTile(
                            "Staff Name", transaction!["staffName"] ?? ""),
                        _detailTile("Staff User ID",
                            (transaction!["staffUserId"] ?? "").toString()),

                        const SizedBox(height: 20),
                        const Divider(),

                        const SizedBox(height: 12),
                        const Text(
                          "Customer",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _detailTile("Name", transaction!["payerName"] ?? ""),
                        _detailTile("Phone", transaction!["payerPhone"] ?? ""),
                      ],
                    ),
                  ),
                ),
    );
  }
}