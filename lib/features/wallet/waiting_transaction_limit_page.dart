

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class WaitingTransactionLimitPage extends StatefulWidget {
  final int pairingId;

  const WaitingTransactionLimitPage({super.key, required this.pairingId});

  @override
  State<WaitingTransactionLimitPage> createState() => _WaitingTransactionLimitPageState();
}

class _WaitingTransactionLimitPageState extends State<WaitingTransactionLimitPage> {
  static const Color primaryColor = Color(0xFF102520);
  static const Color accentColor = Color(0xFFB2DD62);
  bool _isLoading = false;

  Future<void> _checkLimitStatus() async {
    setState(() => _isLoading = true);
    const storage = secureStorage;
    final token = await storage.read(key: 'token');

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/${widget.pairingId}/limit-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (data['limitsSet'] == true) {
            if (!mounted) return;
            context.goNamed(RouteNames.receiverSuccess, extra: {
              'pairingId': data['pairingId'],
              'status': data['status'],
              'maxTotalLimit': data['maxTotalLimit'],
              'perTxnCap': data['perTxnCap'],
              'dailyCap': data['dailyCap'],
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sender has not set the limits yet. Please wait.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Failed to check limit status.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server Error: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Emergency Wallet',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.hourglass_bottom_rounded, size: 80, color: accentColor),
            const SizedBox(height: 30),
            const Text(
              "Waiting for Sender",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Waiting for the sender to set your transaction limits...",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkLimitStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: primaryColor)
                    : const Text('Done Setting Limit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}