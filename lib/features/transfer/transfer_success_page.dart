import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class TransferSuccessPage extends StatelessWidget {
  final int transactionId;
  final String transactionRefNum;
  final double amount;
  final int fromUserId;
  final int toUserId;
  final String timestamp;

  const TransferSuccessPage({
    super.key,
    required this.transactionId,
    required this.transactionRefNum,
    required this.amount,
    required this.fromUserId,
    required this.toUserId,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Transfer Success',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.check_circle, color: accentColor, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Transfer Successful!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow('Transaction ID', transactionId.toString()),
                    const SizedBox(height: 12),
                    _buildRow('Ref Number', transactionRefNum),
                    const SizedBox(height: 12),
                    _buildRow('Amount', 'RM ${amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildRow('From User ID', fromUserId.toString()),
                    const SizedBox(height: 12),
                    _buildRow('To User ID', toUserId.toString()),
                    const SizedBox(height: 12),
                    _buildRow('Timestamp', timestamp),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
                    fontSize: 18,
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

  Widget _buildRow(String label, String value) {
    const primaryColor = Color(0xFF102520);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}