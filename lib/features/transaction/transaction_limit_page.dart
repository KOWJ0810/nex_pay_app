import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';

import '../../core/constants/api_config.dart';

class TransactionLimitPage extends StatefulWidget {
  const TransactionLimitPage({super.key});

  @override
  State<TransactionLimitPage> createState() => _TransactionLimitPageState();
}

class _TransactionLimitPageState extends State<TransactionLimitPage> {
  final storage = secureStorage;

  // User values loaded from API
  double perTransferLimit = 0;
  double dailyLimit = 0;

  // Min / Max rules
  double perTransferMin = 100;
  double perTransferMax = 9999;

  double dailyMin = 100;
  double dailyMax = 120000;

  bool isLoading = true;
  bool isSaving = false;

  double initialPerTransfer = 0;
  double initialDaily = 0;

  double currentPerLimit = 0;
  double currentDailyLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadSpendingLimit();
  }

  // =======================================================
  // LOAD USER LIMIT FROM API
  // =======================================================
  Future<void> _loadSpendingLimit() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/account/spending-limit"),
      headers: {"Authorization": "Bearer $token"},
    );

    final json = jsonDecode(res.body);
    if (json["success"] == true) {
      double apiPer = json["data"]["perTransactionLimit"] * 1.0;
      double apiDaily = json["data"]["dailyLimit"] * 1.0;

      setState(() {
        // Store original (for Save button enable check)
        initialPerTransfer = apiPer;
        initialDaily = apiDaily;

        // Current limit (for "Current:" label)
        currentPerLimit = apiPer;
        currentDailyLimit = apiDaily;

        // User-editable values
        perTransferLimit = apiPer;
        dailyLimit = apiDaily;

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // =======================================================
  // SAVE NEW LIMITS
  // =======================================================
  Future<void> _saveLimit() async {
    setState(() => isSaving = true);

    final token = await storage.read(key: "token");
    if (token == null) return;

    final body = {
      "dailyLimit": dailyLimit.round(),
      "perTransactionLimit": perTransferLimit.round(),
    };

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/account/spending-limit"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode(body),
    );

    final json = jsonDecode(res.body);

    setState(() => isSaving = false);

    if (json["success"] == true) {
      setState(() {
        initialDaily = dailyLimit;
        initialPerTransfer = perTransferLimit;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transfer limit updated successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to save limits."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get hasChanges =>
      dailyLimit != initialDaily || perTransferLimit != initialPerTransfer;

  String formatRM(double value) {
    final format = NumberFormat("#,###", "en_US");
    return "RM${format.format(value)}";
  }

  // =======================================================
  // PAGE UI
  // =======================================================
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const sliderColor = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Transfer Limit",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildLimitCard(
                          title: "Per transfer limit",
                          amount: perTransferLimit,
                          min: perTransferMin,
                          max: perTransferMax,
                          onChanged: (val) =>
                              setState(() => perTransferLimit = val),
                          sliderColor: sliderColor,
                          current: currentPerLimit,
                        ),

                        const SizedBox(height: 20),

                        _buildLimitCard(
                          title: "Daily transfer limit",
                          amount: dailyLimit,
                          min: dailyMin,
                          max: dailyMax,
                          onChanged: (val) =>
                              setState(() => dailyLimit = val),
                          sliderColor: sliderColor,
                          current: currentDailyLimit,
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: hasChanges && !isSaving ? _saveLimit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            hasChanges ? primaryColor : Colors.grey.shade300,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // =======================================================
  // LIMIT CARD UI
  // =======================================================
  Widget _buildLimitCard({
    required String title,
    required double amount,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color sliderColor,
    required double current,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Current value
          Text(
            "Current: ${formatRM(current)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 16),

          // Amount card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Amount",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRM(amount),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Min. RM${min.toInt()} to max. RM${NumberFormat("#,###").format(max)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: sliderColor,
              inactiveTrackColor: Colors.grey.shade400,
              thumbColor: sliderColor,
            ),
            child: Slider(
              value: amount,
              min: min,
              max: max,
              divisions: ((max - min) ~/ 100),
              onChanged: (val) {
                double stepped = (val / 100).round() * 100;
                if (stepped < min) stepped = min;
                if (stepped > max) stepped = max;
                onChanged(stepped.toDouble());
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RM ${min.toInt()}",
                  style: const TextStyle(color: Colors.black54)),
              Text("RM ${NumberFormat("#,###").format(max)}",
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}