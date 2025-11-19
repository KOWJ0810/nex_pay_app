
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class EmergTransactionLimitPage extends StatefulWidget {
  final String phone;
  final int userId;
  final String userName;
  final int pairingId;

  const EmergTransactionLimitPage({
    super.key,
    required this.phone,
    required this.userId,
    required this.userName,
    required this.pairingId,
  });

  @override
  State<EmergTransactionLimitPage> createState() => _EmergTransactionLimitPageState();
}

class _EmergTransactionLimitPageState extends State<EmergTransactionLimitPage> {
  final TextEditingController _monthlyLimitController = TextEditingController();
  final TextEditingController _perTransactionController = TextEditingController();
  final TextEditingController _dailyLimitController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  static const Color primaryColor = Color(0xFF102520);
  static const Color accentColor = Color(0xFFB2DD62);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Set Transaction Limits',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set your transaction limits below",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _monthlyLimitController,
                label: "Maximum Monthly Transaction Limit (RM)",
                hint: "e.g. 5000.00",
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _dailyLimitController,
                label: "Maximum Daily Transaction Limit (RM)",
                hint: "e.g. 1000.00",
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _perTransactionController,
                label: "Maximum Limit per Transaction (RM)",
                hint: "e.g. 200.00",
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveLimits,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Save Limit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: 'RM ',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a value';
        }
        final num? parsed = num.tryParse(value);
        if (parsed == null || parsed <= 0) {
          return 'Enter a valid amount greater than 0';
        }
        return null;
      },
    );
  }

  void _saveLimits() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final monthlyLimit = double.parse(_monthlyLimitController.text);
    final dailyLimit = double.parse(_dailyLimitController.text);
    final perTransaction = double.parse(_perTransactionController.text);

    const storage = secureStorage;
    final token = await storage.read(key: 'token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authorization token missing. Please log in again.')),
      );
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/limits'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "pairingId": widget.pairingId,
          "maxTotalLimit": monthlyLimit,
          "perTxnCap": perTransaction,
          "dailyCap": dailyLimit,
        }),
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Limits saved successfully!')),
          );

          // ignore: use_build_context_synchronously
          context.goNamed(
            RouteNames.senderSuccess,
            extra: {
              'pairingId': widget.pairingId,
              'maxTotalLimit': monthlyLimit,
              'perTxnCap': perTransaction,
              'dailyCap': dailyLimit,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Failed to save limits.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _monthlyLimitController.dispose();
    _perTransactionController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }
}