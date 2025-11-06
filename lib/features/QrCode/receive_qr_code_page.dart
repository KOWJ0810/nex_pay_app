

import 'package:flutter/material.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveQrCodePage extends StatelessWidget {
  final String payload;

  const ReceiveQrCodePage({super.key, required this.payload});

  // For GoRouter: extract payload from extra param
  static Widget fromGoRouter(BuildContext context, GoRouterState state) {
    final extra = state.extra;
    final payload = extra is String ? extra : '';
    return ReceiveQrCodePage(payload: payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Receive Money',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        color: Color(0xFFF5F5F5),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Show this code to the sender',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  payload,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}