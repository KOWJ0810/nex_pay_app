import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';

class MerchantAddOutletPage extends StatefulWidget {
  const MerchantAddOutletPage({Key? key}) : super(key: key);

  @override
  State<MerchantAddOutletPage> createState() => _MerchantAddOutletPageState();
}

class _MerchantAddOutletPageState extends State<MerchantAddOutletPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    // Dimensions for layout
    final double headerHeight = 240;
    final double sheetTopMargin = 120;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // ─── 1. Immersive Header (FIXED) ─────────────────────────────
                Container(
                  height: headerHeight,
                  width: double.infinity,
                  // Replaced vertical padding with SafeArea to prevent overflow
                  padding: const EdgeInsets.symmetric(horizontal: 20), 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF0D201C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          alignment: Alignment.centerLeft,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Add New Outlet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Expand your business reach.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 2. Floating Form Sheet ──────────────────────────────────
                Container(
                  margin: EdgeInsets.only(top: sheetTopMargin, left: 20, right: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.store_mall_directory_rounded, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Outlet Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Name Field
                        _buildLabel("Outlet Name"),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: "e.g. Downtown Branch",
                            icon: Icons.edit_rounded,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                        ),
                        
                        const SizedBox(height: 20),

                        // Address Field
                        _buildLabel("Full Address"),
                        TextFormField(
                          controller: _addressController,
                          textInputAction: TextInputAction.done,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            hint: "No. 123, Jalan...",
                            icon: Icons.map_rounded,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Address is required' : null,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Create Outlet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Spacer
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade200, width: 1),
      ),
    );
  }

  // ─── Logic ─────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    try {
      const storage = secureStorage;
      final token = await storage.read(key: 'token');

      if (token == null) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session expired.")));
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final body = {
        "outletName": _nameController.text.trim(),
        "outletAddress": _addressController.text.trim(),
      };

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (mounted) {
            context.pushNamed(
              RouteNames.addOutletSuccess,
              extra: {
                "outletName": data["outletName"],
                "outletAddress": data["outletAddress"],
                "dateCreated": data["dateCreated"],
              },
            );
          }
          return;
        }
      }
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${res.statusCode}")));
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }
}