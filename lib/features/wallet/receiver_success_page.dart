

import 'package:flutter/material.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class ReceiverSuccessPage extends StatelessWidget {
  final int pairingId;
  final String status;
  final double maxTotalLimit;
  final double perTxnCap;
  final double dailyCap;

  const ReceiverSuccessPage({
    super.key,
    required this.pairingId,
    required this.status,
    required this.maxTotalLimit,
    required this.perTxnCap,
    required this.dailyCap,
  });

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
            const Icon(Icons.check_circle_rounded, color: accentColor, size: 100),
            const SizedBox(height: 30),
            const Text(
              "Emergency Wallet Link Successful!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _infoCard("Status", status),
            _infoCard("Max Total Limit (RM)", maxTotalLimit.toStringAsFixed(2)),
            _infoCard("Per Transaction Cap (RM)", perTxnCap.toStringAsFixed(2)),
            _infoCard("Daily Cap (RM)", dailyCap.toStringAsFixed(2)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.home),
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
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}