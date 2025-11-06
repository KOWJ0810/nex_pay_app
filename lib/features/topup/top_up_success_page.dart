import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/features/dashboard/dashboard_page.dart';
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
        setState(() {
          transactionData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: accentColor)
              : transactionData == null
                  ? const Text("Failed to load transaction details", style: TextStyle(color: Colors.white))
                  : AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 800),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: accentColor, size: 90),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Top-Up Successful',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "RM ${transactionData!['amount']}",
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Divider(color: Colors.grey.shade300, thickness: 1),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _infoRow("Transaction No", transactionData!['transactionRefNum']),
                                  _infoRow("Status", transactionData!['status']),
                                  _infoRow("Date", transactionData!['transactionDateTime'].toString().split('T')[0]),
                                  _infoRow("Time", transactionData!['transactionDateTime'].toString().split('T')[1]),
                                ],
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => context.goNamed(RouteNames.home),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}