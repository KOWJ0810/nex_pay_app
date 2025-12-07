import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key});

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _txnRefController = TextEditingController();

  // State
  String _selectedCategory = 'DUPLICATE_CHARGE';
  bool _isSubmitting = false;

  // Dropdown Options
  final List<Map<String, String>> _categories = [
    {'value': 'DUPLICATE_CHARGE', 'label': 'Duplicate Charge'},
    {'value': 'UNAUTHORIZED_TRANSACTION', 'label': 'Unauthorized Transaction'},
    {'value': 'BILLING_ERROR', 'label': 'Billing Error'},
    {'value': 'SERVICE_ISSUE', 'label': 'Service Issue'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
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

      final txnRef = _txnRefController.text.trim();

      final Map<String, dynamic> body = {
        "category": _selectedCategory,
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "relatedTransactionRef": txnRef.isEmpty ? null : txnRef,
      };

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final jsonRes = jsonDecode(res.body);

      if (res.statusCode == 200 && jsonRes['success'] == true) {
        final data = jsonRes['data']; 
        
        if (mounted) {
          context.goNamed(
            RouteNames.reportSuccess,
            extra: data, 
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonRes['message'] ?? "Submission failed"),
              backgroundColor: Colors.red,
            ),
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
          "New Ticket",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              children: [
                // Top Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, size: 40, color: accentColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "How can we help?",
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Fill in the details below and our team will investigate.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Section
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
                        // Category Dropdown
                        const Text("Issue Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down_circle, color: primaryColor),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat['value'],
                                  child: Text(cat['label']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title Input
                        _buildLabel("Subject Title"),
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(hint: "e.g. Double deduction", icon: Icons.title_rounded),
                          validator: (v) => v!.isEmpty ? "Title is required" : null,
                        ),

                        const SizedBox(height: 20),

                        // Description Input
                        _buildLabel("Description"),
                        TextFormField(
                          controller: _descController,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(hint: "Describe what happened...", icon: Icons.description_outlined),
                          validator: (v) => v!.isEmpty ? "Description is required" : null,
                        ),

                        const SizedBox(height: 20),

                        // Transaction Ref
                        _buildLabel("Transaction ID (Optional)"),
                        TextFormField(
                          controller: _txnRefController,
                          decoration: _inputDecoration(hint: "e.g. TXN-12345", icon: Icons.receipt_long_rounded),
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text(
                                    "Submit Ticket",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                        
                        // Keyboard padding
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 40),
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


  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
    );
  }
}