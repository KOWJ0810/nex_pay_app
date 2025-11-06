import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class SenderGenerateCodePage extends StatefulWidget {
  final String phone;
  final int userId;
  final String userName;
  final int pairingId;
  final String status;
  final String firstCode;

  const SenderGenerateCodePage({
      super.key,
      required this.phone,
      required this.userId,
      required this.userName,
      required this.pairingId,
      required this.status,
      required this.firstCode,
  });

  @override
  State<SenderGenerateCodePage> createState() => _SenderGenerateCodePageState();
}

class _SenderGenerateCodePageState extends State<SenderGenerateCodePage> {
  static const Color primaryColor = Color(0xFF102520);
  static const Color accentColor = Color(0xFFB2DD62);

  late final String _code;

  @override
  void initState() {
    super.initState();
    _code = widget.firstCode;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                'Ask your friend to enter the code below',
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
                  onPressed: () async {
                    try {
                      final res = await http.get(
                        Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/${widget.pairingId}/code-status'),
                        headers: {'Content-Type': 'application/json'},
                      );

                      if (res.statusCode == 200) {
                        final jsonRes = jsonDecode(res.body);
                        if (jsonRes['success'] == true) {
                          final data = jsonRes['data'];
                          if (data['receiverEntered'] == true) {
                            context.goNamed(
                              RouteNames.senderVerification,
                              extra: {
                                'phone': widget.phone,
                                'userId': widget.userId,
                                'userName': widget.userName,
                                'pairingId': widget.pairingId,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receiver has not entered the code yet. Please wait.')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: ${jsonRes['message'] ?? 'Unknown error'}')),
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
                  },
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