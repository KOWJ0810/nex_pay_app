
import '../../router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class P2PTransferSuccessPage extends StatelessWidget {
  final int? transactionId;
  final String? transactionRefNum;
  final double? amount;
  final int? fromUserId;
  final int? toUserId;
  final double? fromBalanceAfter;
  final double? toBalanceAfter;
  final String? at;
  final String? receiverName;
  final String? receiverPhone;

  const P2PTransferSuccessPage({
    super.key,
    this.transactionId,
    this.transactionRefNum,
    this.amount,
    this.fromUserId,
    this.toUserId,
    this.fromBalanceAfter,
    this.toBalanceAfter,
    this.at,
    this.receiverName,
    this.receiverPhone,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    final amount = this.amount ?? 0.0;
    final receiverName = this.receiverName ?? "Unknown";
    final receiverPhone = this.receiverPhone ?? "-";
    final refNum = this.transactionRefNum ?? "";
    final at = this.at ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          "Transfer Successful",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.4),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: primaryColor,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              "RM ${amount.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 34,
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Sent to $receiverName",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              receiverPhone,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),

            const SizedBox(height: 32),

            _detailTile("Reference Number", refNum),
            const SizedBox(height: 12),
            _detailTile("Date & Time", at),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.goNamed(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 17,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    const primaryColor = Color(0xFF102520);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}