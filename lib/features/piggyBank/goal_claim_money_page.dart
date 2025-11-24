import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../router.dart' show RouteNames;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For InputFormatter
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';

class GoalClaimMoneyPage extends StatefulWidget {
  final int piggyBankId;

  const GoalClaimMoneyPage({super.key, required this.piggyBankId});

  @override
  State<GoalClaimMoneyPage> createState() => _GoalClaimMoneyPageState();
}

class _GoalClaimMoneyPageState extends State<GoalClaimMoneyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    final storage = secureStorage;

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session expired. Please sign in again.")),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/piggy-banks/${widget.piggyBankId}/withdraw');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': double.parse(_amountController.text),
          'reason': _reasonController.text.isEmpty
              ? null
              : _reasonController.text,
        }),
      );

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        if (jsonRes['success'] == true) {
          if (mounted) {
            context.goNamed(
              RouteNames.claimMoneySuccess,
              extra: {
                'piggy_bank_id': widget.piggyBankId,
                'amount': double.parse(_amountController.text),
                'reason': _reasonController.text,
              },
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonRes['message'] ?? 'Failed to claim money')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Immersive Dark Background
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Withdraw Funds",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── TOP SECTION: AMOUNT INPUT ──────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Amount to withdraw",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  
                  // Big Money Input
                  IntrinsicWidth(
                    child: TextFormField(
                      controller: _amountController,
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
                        hintText: "0",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      ),
                      inputFormatters: [
                         FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Digits only
                      ],
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── BOTTOM SECTION: DETAILS & ACTION ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // 1. Reason Input
                  const Text("Reason (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: "E.g. Buying a new phone",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF4F6F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. Info Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: Colors.orange[800]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Funds will be returned to your main wallet immediately.",
                            style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // 3. Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || _amountController.text.isEmpty) ? null : _submitClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Confirm Withdrawal",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),
                  
                  // Handle keyboard overlapping
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}