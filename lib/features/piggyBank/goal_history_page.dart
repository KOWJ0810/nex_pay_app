import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';

class GoalHistoryPage extends StatefulWidget {
  final int piggyBankId;

  const GoalHistoryPage({super.key, required this.piggyBankId});

  @override
  State<GoalHistoryPage> createState() => _GoalHistoryPageState();
}

class _GoalHistoryPageState extends State<GoalHistoryPage> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> movements = [];

  @override
  void initState() {
    super.initState();
    _fetchMovements();
  }

  Future<void> _fetchMovements() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final token = await storage.read(key: 'token');
      if (token == null) {
        setState(() => errorMessage = 'Session expired. Please log in again.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/piggy-banks/${widget.piggyBankId}/movements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          setState(() => movements = jsonRes['data']);
        } else {
          setState(() => errorMessage = 'Failed to load movement history.');
        }
      } else {
        setState(() => errorMessage = 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('Saving History', style: TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)))
              : movements.isEmpty
                  ? const Center(
                      child: Text("No saving history found.",
                          style: TextStyle(color: Colors.black54, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: movements.length,
                      itemBuilder: (context, index) {
                        final move = movements[index];
                        final isDeposit = move['type'] == 'DEPOSIT';
                        final amountColor = isDeposit ? Colors.green : Colors.red;
                        final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(
                          DateTime.parse(move['createdAt']),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDeposit ? 'Deposit' : 'Withdraw',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    move['reason']?.toString() ?? '',
                                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                "${isDeposit ? '+' : '-'} RM ${move['amount'].toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
