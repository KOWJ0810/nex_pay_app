import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl for DateFormat & NumberFormat
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class TopUpSuccessPage extends StatefulWidget {
  final String amount;
  final String paymentIntentId;

  const TopUpSuccessPage({
    super.key,
    required this.amount,
    required this.paymentIntentId,
  });

  @override
  State<TopUpSuccessPage> createState() => _TopUpSuccessPageState();
}

class _TopUpSuccessPageState extends State<TopUpSuccessPage> {
  Map<String, dynamic>? transactionData;
  bool isLoading = true;

  // Brand Colors
  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  Future<void> fetchTransactionDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/by-intent/${widget.paymentIntentId}'),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            transactionData = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatters
    final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: accentColor))
            : transactionData == null
                ? _buildErrorState()
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ─── 1. ANIMATED SUCCESS ICON ──────────────────────
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.4),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.check_rounded, color: primaryColor, size: 48, weight: 800),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          const Text(
                            "Top Up Successful!",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          
                          const SizedBox(height: 32),

                          // ─── 2. RECEIPT CARD ───────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Amount Added",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(double.tryParse(transactionData!['amount'].toString()) ?? 0),
                                  style: const TextStyle(color: primaryColor, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
                                ),
                                
                                const SizedBox(height: 24),
                                Divider(color: Colors.grey[200], thickness: 1.5),
                                const SizedBox(height: 24),

                                // Details
                                _ReceiptRow(
                                  label: "Date", 
                                  value: dateFormat.format(DateTime.parse(transactionData!['transactionDateTime']))
                                ),
                                const SizedBox(height: 16),
                                _ReceiptRow(
                                  label: "Status", 
                                  value: "Success", 
                                  textColor: Colors.green[700]
                                ),
                                const SizedBox(height: 16),
                                const _ReceiptRow(
                                  label: "Payment Method", 
                                  value: "Online Banking / Card"
                                ),
                                const SizedBox(height: 16),
                                _ReceiptRow(
                                  label: "Reference No.", 
                                  value: transactionData!['transactionRefNum'] ?? "-",
                                  isMono: true, // Monospace font for tech IDs
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ─── 3. ACTION BUTTON ──────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => context.goNamed(RouteNames.home),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          const Text("Could not load receipt details.", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.goNamed(RouteNames.home),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: accentColor), foregroundColor: accentColor),
            child: const Text("Return Home"),
          )
        ],
      ),
    );
  }
}

// ─── Helper Widget for Rows ──────────────────────────────────────────────────
class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final Color? textColor;

  const _ReceiptRow({
    required this.label, 
    required this.value,
    this.isMono = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided primaryColor or default black
    const valueColor = Color(0xFF102520); 

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor ?? valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: isMono ? 'monospace' : null, // Adds tech feel to Ref ID
            ),
          ),
        ),
      ],
    );
  }
}