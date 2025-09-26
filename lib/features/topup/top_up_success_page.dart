import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/features/dashboard/dashboard_page.dart';

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
        Uri.parse("http://localhost:8080/api/transactions/by-intent/${widget.paymentIntentId}"),
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
    return Scaffold(
      backgroundColor: const Color(0xFFEFF2F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2F24),
        elevation: 0,
        title: const Text('Top Up', style: TextStyle(color: Color(0xFFB8E986))),
        centerTitle: true,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : transactionData == null
                ? const Text("Failed to load transaction details")
                : Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 80),
                        const SizedBox(height: 20),
                        const Text(
                          'Top Up Successful',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("RM ${transactionData!['amount']}", style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 20),
                        Text("Transaction no: ${transactionData!['transactionRefNum']}"),
                        Text("Status: ${transactionData!['status']}"),
                        Text("Date: ${transactionData!['transactionDateTime'].toString().split('T')[0]}"),
                        Text("Time: ${transactionData!['transactionDateTime'].toString().split('T')[1]}"),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DashboardPage()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB8E986),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          ),
                          child: const Text('Continue', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}