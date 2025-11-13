import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class MerchantPaymentSuccessPage extends StatelessWidget {
  final String transactionRefNum;
  final double amountCharged;
  final int payerUserId;

  const MerchantPaymentSuccessPage({
    Key? key,
    required this.transactionRefNum,
    required this.amountCharged,
    required this.payerUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Payment Success",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Success Icon
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(.25),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 80,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Payment Successful!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              "The payment has been successfully processed.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withOpacity(.65),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            _infoBox(
              "Transaction Ref",
              transactionRefNum,
            ),
            const SizedBox(height: 16),
            _infoBox(
              "Amount Charged",
              "RM ${amountCharged.toStringAsFixed(2)}",
            ),
            const SizedBox(height: 16),
            _infoBox(
              "Payer User ID",
              payerUserId.toString(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.merchantDashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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

  Widget _infoBox(String label, String value) {
    const primaryColor = Color(0xFF102520);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
