import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';      
import 'package:nex_pay_app/main.dart';      

class ShowPaymentLinkPage extends StatefulWidget {
  final int outletId;

  const ShowPaymentLinkPage({super.key, required this.outletId});

  @override
  State<ShowPaymentLinkPage> createState() => _ShowPaymentLinkPageState();
}

class _ShowPaymentLinkPageState extends State<ShowPaymentLinkPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isLoading = false;
  String? generatedUrl;
  
  // Animation state for the "Copied" button
  bool isCopied = false;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  Future<void> createPaymentLink() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      generatedUrl = null; // Reset previous result
      isCopied = false;
    });

    try {
      const storage = secureStorage;
      final token = await storage.read(key: 'token');

      final url = "${ApiConfig.baseUrl}/payment-links/outlets/${widget.outletId}";

      final body = {
        "amount": double.parse(amountController.text),
        "note": noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        "expiresInMinutes": 60,
      };

      final res = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json["success"] == true) {
          setState(() {
            generatedUrl = json["data"]["url"];
          });
        } else {
          _showError(json["message"] ?? "Failed");
        }
      } else {
        _showError("Server error: ${res.statusCode}");
      }
    } catch (e) {
      _showError("Connection error: $e");
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _copyToClipboard() {
    if (generatedUrl == null) return;
    
    Clipboard.setData(ClipboardData(text: generatedUrl!));

    // Tell main.dart to ignore this link forever (prevents deep link loop)
    final appState = rootNavigatorKey.currentContext?.findAncestorStateOfType<NexPayAppState>();
    appState?.ignoreForever(generatedUrl!);

    setState(() => isCopied = true);
    
    // Reset copy status after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if(mounted) setState(() => isCopied = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Link copied to clipboard!"), backgroundColor: primaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Immersive background
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment Link",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ─── TOP SECTION: AMOUNT INPUT ──────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Enter Amount",
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    
                    // Big Money Input
                    IntrinsicWidth(
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 48, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                        cursorColor: accentColor,
                        decoration: InputDecoration(
                          prefixText: "RM ",
                          prefixStyle: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w600, 
                            color: Colors.white.withOpacity(0.5)
                          ),
                          border: InputBorder.none,
                          hintText: "0.00",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        ),
                        inputFormatters: [
                           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), 
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Note Input (Transparent style)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: noteController,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Add a note (e.g. Table 5)",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          icon: Icon(Icons.edit_note, color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── BOTTOM SECTION: ACTION / RESULT ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (generatedUrl == null) ...[
                  // 1. Initial State: Create Button
                  const Text(
                    "Link is valid for 60 minutes",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : createPaymentLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              "Generate Link",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ] else ...[
                  // 2. Success State: Result Card 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.link_rounded, color: primaryColor, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          "Payment Link Ready!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          generatedUrl!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Share/Copy Button
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: Icon(isCopied ? Icons.check_rounded : Icons.copy_rounded, color: primaryColor),
                            label: Text(
                              isCopied ? "Copied" : "Copy Link",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // New Link Button
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              amountController.clear();
                              noteController.clear();
                              generatedUrl = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.refresh_rounded, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Handle keyboard padding
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}