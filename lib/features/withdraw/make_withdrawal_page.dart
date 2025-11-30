import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';

class MakeWithdrawalPage extends StatefulWidget {
  const MakeWithdrawalPage({super.key});

  @override
  State<MakeWithdrawalPage> createState() => _MakeWithdrawalPageState();
}

class _MakeWithdrawalPageState extends State<MakeWithdrawalPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accNumController = TextEditingController();

  // State
  String _claimType = 'BANK_TRANSFER'; // Default
  bool _isSubmitting = false;

  Future<void> _submitClaim() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;
    
    // Hide Keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    try {
      final storage = secureStorage;
      final token = await storage.read(key: 'token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Session expired. Please login again.")),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // 2. Prepare Data
      final double amount = double.parse(_amountController.text);
      
      final Map<String, dynamic> body = {
        "amount": amount,
        "claimType": _claimType,
        "bankName": _claimType == 'BANK_TRANSFER' ? _bankNameController.text.trim() : null,
        "bankAccountNum": _claimType == 'BANK_TRANSFER' ? _accNumController.text.trim() : null,
      };

      // 3. API Call
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/merchants/claims/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final jsonRes = jsonDecode(res.body);

      if (res.statusCode == 200 && jsonRes['success'] == true) {
        final data = jsonRes['data']; // The response object from your API example
        
        if (mounted) {
          if (_claimType == 'BANK_TRANSFER') {
            // Navigate to Bank Success Page (Pending state)
            context.pushNamed(
              RouteNames.withdrawBankSuccess, 
              extra: data, // Pass the full data object
            );
          } else {
            // Navigate to Wallet Success Page (Instant state)
            context.pushNamed(
              RouteNames.withdrawWalletSuccess, 
              extra: data,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? "Submission failed"), backgroundColor: Colors.red),
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
      backgroundColor: primaryColor,
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Request Withdrawal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // FIX: Use CustomScrollView with SliverFillRemaining to handle keyboard overflow
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false, // Allows content to scroll only if it overflows screen height
            child: Column(
              children: [
                // ─── Top Section: Amount Input ───
                // Spacer pushes content to center when keyboard is closed
                const Spacer(), 
                
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Enter Amount",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                      ),
                      const SizedBox(height: 10),
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
                            hintText: "0.00",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // ─── Bottom Section: Form Sheet ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Withdrawal Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                        const SizedBox(height: 16),
                        
                        // Toggle Buttons
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _MethodTab(
                                label: "Bank Transfer",
                                icon: Icons.account_balance_rounded,
                                isSelected: _claimType == 'BANK_TRANSFER',
                                onTap: () => setState(() => _claimType = 'BANK_TRANSFER'),
                              ),
                              _MethodTab(
                                label: "Wallet",
                                icon: Icons.account_balance_wallet_rounded,
                                isSelected: _claimType == 'WALLET_TRANSFER',
                                onTap: () => setState(() => _claimType = 'WALLET_TRANSFER'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CONDITIONAL BANK FIELDS
                        if (_claimType == 'BANK_TRANSFER') ...[
                          const Text("Bank Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _bankNameController,
                            decoration: _inputDecoration(hint: "Bank Name (e.g. Maybank)", icon: Icons.business),
                            validator: (value) {
                              if (_claimType == 'BANK_TRANSFER' && (value == null || value.isEmpty)) {
                                return "Bank name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _accNumController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(hint: "Account Number", icon: Icons.numbers),
                            validator: (value) {
                              if (_claimType == 'BANK_TRANSFER' && (value == null || value.isEmpty)) {
                                return "Account number is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text("Ensure details are correct. Processing may take 1-3 days.", style: TextStyle(color: Colors.orange[900], fontSize: 12))),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Info for Wallet Transfer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: const [
                                Icon(Icons.flash_on_rounded, color: primaryColor),
                                SizedBox(width: 12),
                                Expanded(child: Text("Funds will be transferred to your linked personal wallet instantly.", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitClaim,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    "Submit Request",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                        
                        // Extra bottom padding for safety
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Styling Helpers ───

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      prefixIcon: Icon(icon, color: Colors.grey[500]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade200)),
    );
  }
}

// ─── Custom Widgets ───

class _MethodTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodTab({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? primaryColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}