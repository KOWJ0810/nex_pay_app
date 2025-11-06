import 'package:flutter/material.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart' show RouteNames;
import '../../core/constants/api_config.dart';

class ReceiverGenerateCodePage extends StatefulWidget {
  final String? phone;
  final int? userId;
  final String? userName;
  final int? pairingId;
  final String? status;
  final String? secondCode;

  const ReceiverGenerateCodePage({
    super.key,
    this.phone,
    this.userId,
    this.userName,
    this.pairingId,
    this.status,
    this.secondCode,
  });

  @override
  State<ReceiverGenerateCodePage> createState() => _ReceiverGenerateCodePageState();
}

class _ReceiverGenerateCodePageState extends State<ReceiverGenerateCodePage> {
  static const Color primaryColor = Color(0xFF102520);
  static const Color accentColor = Color(0xFFB2DD62);

  late final String _code;

  @override
  void initState() {
    super.initState();
    _code = widget.secondCode ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final codeChars = _code.split('');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Emergency Wallet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Verification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Show this code to your friend so they can confirm your approval.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  codeChars.length,
                  (i) => _buildCodeBox(codeChars[i]),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The verification code will show at the person who you want to setup with.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              const Text(
                'Once your friend approves, you can proceed to the next step.',
                style: TextStyle(
                  fontSize: 15,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _checkCodeStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Friend Already Approved'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkCodeStatus() async {
    final pairingId = widget.pairingId;
    if (pairingId == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/$pairingId/code-status');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final data = result['data'];
          if (data != null && data['senderEntered'] == true) {
            if (mounted) {
              context.goNamed(
                RouteNames.waitingTransactionLimit,
                extra: {'pairingId': pairingId},
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your friend has not approved yet.')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected response from server.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildCodeBox(String char) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
