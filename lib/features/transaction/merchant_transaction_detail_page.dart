import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';

class MerchantTransactionDetailPage extends StatefulWidget {
  final int transactionId;

  const MerchantTransactionDetailPage({Key? key, required this.transactionId})
      : super(key: key);

  @override
  State<MerchantTransactionDetailPage> createState() =>
      _MerchantTransactionDetailPageState();
}

class _MerchantTransactionDetailPageState
    extends State<MerchantTransactionDetailPage> {
  final FlutterSecureStorage _secureStorage = secureStorage;

  bool isLoading = true;
  Map<String, dynamic>? transaction;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
  }

  Future<void> _loadTransactionDetail() async {
    try {
      final token = await _secureStorage.read(key: 'token');

      if (token == null) {
        setState(() {
          errorMessage = "Session expired. Please log in again.";
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
          "${ApiConfig.baseUrl}/merchants/transactions/${widget.transactionId}");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        setState(() {
          transaction = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Unable to load transaction details";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Widget _detailTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.arrow_back_ios,
                                  color: primaryColor),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Transaction Detail",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Transaction Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
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
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "RM",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ((transaction?["amount"] ?? 0) as num).toDouble().toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (transaction?["transactionRefNum"] ?? "").toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Show Details
                        _detailTile("Status", (transaction?["status"] ?? "").toString()),
                        _detailTile("Category", (transaction?["category"] ?? "").toString()),
                        _detailTile("Payment Type", (transaction?["paymentType"] ?? "").toString()),
                        _detailTile("Date & Time", (transaction?["transactionDateTime"] ?? "").toString()),

                        const SizedBox(height: 10),
                        const Text(
                          "Merchant Info",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _detailTile("Merchant", (transaction?["merchantName"] ?? "").toString()),
                        _detailTile("Outlet", (transaction?["outletName"] ?? "").toString()),

                        const SizedBox(height: 10),
                        const Text(
                          "Staff Info",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _detailTile("Staff Name", (transaction?["staffName"] ?? "").toString()),
                        _detailTile("Staff User ID", (transaction?["staffUserId"] ?? "").toString()),

                        const SizedBox(height: 10),
                        const Text(
                          "Payer Info",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        _detailTile("Payer Name", (transaction?["payerName"] ?? "").toString()),
                        _detailTile("Payer Phone", (transaction?["payerPhone"] ?? "").toString()),
                      ],
                    ),
                  ),
      ),
    );
  }
}