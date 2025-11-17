import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';
import 'package:go_router/go_router.dart';

class PaymentLinkPreviewPage extends StatefulWidget {
  final String token;

  const PaymentLinkPreviewPage({super.key, required this.token});

  @override
  State<PaymentLinkPreviewPage> createState() => _PaymentLinkPreviewPageState();
}

class _PaymentLinkPreviewPageState extends State<PaymentLinkPreviewPage> {
  Map<String, dynamic>? previewData;
  bool isLoading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    fetchPreview();
  }

  Future<void> fetchPreview() async {
    try {
      const storage = FlutterSecureStorage();
      final authToken = await storage.read(key: "token");

      final url =
          "${ApiConfig.baseUrl}/payment-links/${widget.token}/preview";

      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
      );

      final json = jsonDecode(res.body);

      if (json["success"] == true && json["data"] != null) {
        setState(() {
          previewData = json["data"];
          isLoading = false;
        });
      } else {
        setState(() {
          error = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error || previewData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Invalid Link"),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: Text(
            "This payment link is invalid or has expired.",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final data = previewData!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Payment Request",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Merchant Name
                  Text(
                    data["merchantName"] ?? "Unknown Merchant",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  /// Outlet Name
                  Text(
                    data["outletName"] ?? "-",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// Merchant Type
                  if (data["merchantType"] != null)
                    Text(
                      "Type: ${data["merchantType"]}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                  const SizedBox(height: 4),

                  /// Payment Status
                  Text(
                    "Status: ${data["status"]}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// Expiry
                  if (data["expiresAt"] != null)
                    Text(
                      "Expires At: ${data["expiresAt"]}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// Amount Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Amount",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          "RM ${data['amount']}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Optional Note
                  if (data["note"] != null && data["note"].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Note",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data["note"],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            /// Pay Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    const storage = FlutterSecureStorage();
                    final authToken = await storage.read(key: "token");

                    final res = await http.post(
                      Uri.parse("${ApiConfig.baseUrl}/payment-links/${widget.token}/pay"),
                      headers: {
                        "Authorization": "Bearer $authToken",
                        "Content-Type": "application/json",
                      },
                    );

                    final json = jsonDecode(res.body);

                    if (json["success"] == true && json["data"] != null) {
                      final data = json["data"];

                      context.pushNamed(
                        RouteNames.paymentLinkSuccess,
                        extra: {
                          'transactionId': data['transactionId'],
                          'transactionRefNum': data['transactionRefNum'],
                          'amount': data['amount'],
                          'status': data['status'],
                          'merchantName': data['merchantName'],
                          'outletName': data['outletName'],
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Payment failed. Please try again.")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Pay Now",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}