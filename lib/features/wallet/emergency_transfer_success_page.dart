import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../router.dart';

class EmergencyTransferSuccessPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmergencyTransferSuccessPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ================================
    // 🔥 Extract ALL extras here
    // ================================
    final paymentId = data["paymentId"];
    final paymentStatus = data["paymentStatus"] ?? "SUCCESS";
    final transactionId = data["transactionId"];
    final transactionRefNum = data["transactionRefNum"] ?? "-";
    final amount = (data["amount"] ?? 0).toDouble();
    final senderUserId = data["senderUserId"];
    final receiverUserId = data["receiverUserId"];
    final merchantId = data["merchantId"];
    final outletId = data["outletId"];
    final merchantName = data["merchantName"] ?? "-";
    final outletName = data["outletName"] ?? "-";
    final transactionDateTime = data["transactionDateTime"] ?? "-";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),

      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          "Payment Successful",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      // ================================================
      // 🚀 FIXED: Scrollable body to avoid overflow
      // ================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // SUCCESS ICON
            Container(
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(32),
              child: const Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 90,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Emergency Wallet Payment Successful!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Your emergency sender has successfully covered this payment.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 32),

            // ================================================
            // 🔥 INFORMATION CARD
            // ================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow("Reference No.", transactionRefNum),
                  _divider(),

                  _infoRow("Amount", "RM ${amount.toStringAsFixed(2)}"),
                  _divider(),

                  _infoRow("Merchant", merchantName),
                  _divider(),

                  _infoRow("Outlet", outletName),
                  _divider(),

                  _infoRow("Sender User ID", senderUserId.toString()),
                  _divider(),

                  _infoRow("Receiver User ID", receiverUserId.toString()),
                  _divider(),

                  _infoRow("Transaction Time", transactionDateTime),
                  _divider(),

                  _infoRow("Payment Status", paymentStatus),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BACK TO HOME BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.goNamed(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================================================
  // UI HELPERS
  // ================================================
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLE
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // VALUE
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}