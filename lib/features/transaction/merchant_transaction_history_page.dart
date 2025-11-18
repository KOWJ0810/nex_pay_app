import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../widgets/nex_merchant_scaffold.dart';

class MerchantTransactionHistoryPage extends StatefulWidget {
  const MerchantTransactionHistoryPage({super.key});

  @override
  State<MerchantTransactionHistoryPage> createState() =>
      _MerchantTransactionHistoryPageState();
}

class _MerchantTransactionHistoryPageState
    extends State<MerchantTransactionHistoryPage> {
  final storage = secureStorage;

  int? selectedOutletId;
  List<Map<String, dynamic>> outlets = [];
  List<Map<String, dynamic>> transactions = [];

  bool loadingOutlets = true;
  bool loadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadOutlets();
  }

  Future<void> _loadOutlets() async {
    setState(() => loadingOutlets = true);

    final token = await storage.read(key: "token");

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/merchants/outlets"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      outlets = (data["data"]["outlets"] as List)
          .map((o) => o as Map<String, dynamic>)
          .toList();
    }

    loadingOutlets = false;

    // load transaction for ALL outlets on first load
    await _loadTransactions();

    if (mounted) setState(() {});
  }

  Future<void> _loadTransactions() async {
    setState(() => loadingTransactions = true);

    final token = await storage.read(key: "token");
    late Uri endpoint;

    if (selectedOutletId == null) {
      endpoint = Uri.parse("${ApiConfig.baseUrl}/merchants/transactions");
    } else {
      endpoint = Uri.parse(
        "${ApiConfig.baseUrl}/merchants/transactions/outlets/$selectedOutletId",
      );
    }

    final res = await http.get(
      endpoint,
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final jsonRes = jsonDecode(res.body);
      transactions = (jsonRes["items"] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } else {
      transactions = [];
    }

    loadingTransactions = false;

    if (mounted) setState(() {});
  }

  String formatDate(String dateTimeString) {
    DateTime dt = DateTime.parse(dateTimeString);
    return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return NexMerchantScaffold(
      currentIndex: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildOutletDropdown(),
          const SizedBox(height: 8),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HEADER UI
  // ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: const Text(
        "Transaction History",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // OUTLET FILTER DROPDOWN
  // ──────────────────────────────────────────────
  Widget _buildOutletDropdown() {
    if (loadingOutlets) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            isExpanded: true,
            value: selectedOutletId,
            hint: const Text("All Outlets"),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text("All Outlets"),
              ),
              ...outlets.map(
                (o) => DropdownMenuItem(
                  value: o["outletId"],
                  child: Text(o["outletName"]),
                ),
              )
            ],
            onChanged: (value) {
              setState(() {
                selectedOutletId = value;
              });
              _loadTransactions();
            },
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // TRANSACTION LIST (NULL SAFE)
  // ──────────────────────────────────────────────
  Widget _buildTransactionList() {
    if (loadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          "No transactions found.",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];

        // Null-safe fields
        final refNum = (t["transactionRefNum"] ?? "-").toString();

        final amountValue = t["amount"];
        final amount = amountValue is num ? amountValue.toDouble() : 0.0;

        final dateString = t["transactionDateTime"] as String?;
        String dateLabel = "-";
        if (dateString != null) {
          try {
            dateLabel = formatDate(dateString);
          } catch (_) {}
        }

        final outletName = (t["outletName"] ?? "Unknown outlet").toString();
        final staffName = (t["staffUserName"] ?? "Unknown staff").toString();
        final payerName = (t["payerUserName"] ?? "Unknown user").toString();
        final payerPhone = (t["payerPhone"] ?? "-").toString();

        return GestureDetector(
          onTap: () {
            context.pushNamed(
              RouteNames.merchantTransactionDetail,
              extra: {"transactionId": t["transactionId"]},
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
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      refNum,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "RM ${amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                Text(dateLabel, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),

                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.store_rounded, size: 18, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        outletName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 18, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      staffName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.account_circle_rounded,
                        size: 18, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "$payerName ($payerPhone)",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}