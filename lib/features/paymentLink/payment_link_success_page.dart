

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class PaymentLinkSuccessPage extends StatelessWidget {
  final int? transactionId;
  final String? transactionRefNum;
  final double? amount;
  final String? status;
  final String? merchantName;
  final String? outletName;

  const PaymentLinkSuccessPage({
    super.key,
    required this.transactionId,
    required this.transactionRefNum,
    required this.amount,
    required this.status,
    required this.merchantName,
    required this.outletName,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Payment Successful",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.goNamed(RouteNames.home),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Success Icon
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 80, color: accentColor),
            ),

            const SizedBox(height: 20),

            const Text(
              "Payment Completed!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Transaction Ref: ${transactionRefNum ?? '-'}",
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 30),

            _detailTile("Amount Paid", "RM ${amount?.toStringAsFixed(2) ?? '0.00'}"),
            _detailTile("Status", status ?? "-"),
            _detailTile("Merchant", merchantName ?? "-"),
            _detailTile("Outlet", outletName ?? "-"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102520),
              )),
          Text(value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              )),
        ],
      ),
    );
  }
}