import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/colors.dart'; 
import '../../core/constants/api_config.dart';
import 'package:go_router/go_router.dart';

class TransactionLimitPage extends StatefulWidget {
  const TransactionLimitPage({super.key});

  @override
  State<TransactionLimitPage> createState() => _TransactionLimitPageState();
}

class _TransactionLimitPageState extends State<TransactionLimitPage> {
  final storage = secureStorage;

  // User values
  double perTransferLimit = 0;
  double dailyLimit = 0;

  // Rules
  final double perTransferMin = 100;
  final double perTransferMax = 10000; 
  final double dailyMin = 100;
  final double dailyMax = 120000;

  bool isLoading = true;
  bool isSaving = false;

  double initialPerTransfer = 0;
  double initialDaily = 0;

  @override
  void initState() {
    super.initState();
    _loadSpendingLimit();
  }

  Future<void> _loadSpendingLimit() async {
    final token = await storage.read(key: "token");
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/account/spending-limit"),
        headers: {"Authorization": "Bearer $token"},
      );

      final json = jsonDecode(res.body);
      if (json["success"] == true) {
        double apiPer = (json["data"]["perTransactionLimit"] ?? 0).toDouble();
        double apiDaily = (json["data"]["dailyLimit"] ?? 0).toDouble();

        setState(() {
          initialPerTransfer = apiPer;
          initialDaily = apiDaily;
          perTransferLimit = apiPer;
          dailyLimit = apiDaily;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveLimit() async {
    setState(() => isSaving = true);

    final token = await storage.read(key: "token");
    if (token == null) return;

    try {
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
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Limits updated successfully"), backgroundColor: Colors.green),
          );
          context.pop();
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(json["message"] ?? "Failed to save"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
    }
  }

  bool get hasChanges =>
      dailyLimit != initialDaily || perTransferLimit != initialPerTransfer;

  String formatRM(double value) {
    final format = NumberFormat("#,###", "en_US");
    return "RM ${format.format(value)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFF0D201C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text(
                    "Transfer Limits",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48), 
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSliderCard(
                          title: "Per Transaction Limit",
                          subtitle: "Max amount for a single transfer",
                          icon: Icons.payments_outlined,
                          value: perTransferLimit,
                          min: perTransferMin,
                          max: perTransferMax,
                          onChanged: (val) {
                            if (val != perTransferLimit) HapticFeedback.selectionClick();
                            setState(() => perTransferLimit = val);
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSliderCard(
                          title: "Daily Limit",
                          subtitle: "Max cumulative amount per day",
                          icon: Icons.calendar_today_outlined,
                          value: dailyLimit,
                          min: dailyMin,
                          max: dailyMax,
                          onChanged: (val) {
                            if (val != dailyLimit) HapticFeedback.selectionClick();
                            setState(() => dailyLimit = val);
                          },
                        ),
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // Save Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: hasChanges && !isSaving ? _saveLimit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      hasChanges ? "Save Changes" : "No Changes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasChanges ? Colors.white : Colors.grey[500],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Slider
  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Amount Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                formatRM(value),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Custom Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: Colors.grey[200],
              thumbColor: primaryColor,
              overlayColor: accentColor.withOpacity(0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              // Calculate divisions to snap to nearest 100
              divisions: (max - min) ~/ 100, 
              onChanged: (val) {
                // Snap logic to nearest 100
                double stepped = (val / 100).round() * 100.0;
                if (stepped < min) stepped = min;
                if (stepped > max) stepped = max;
                onChanged(stepped);
              },
            ),
          ),

          // Min/Max Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatRM(min), style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                Text(formatRM(max), style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}