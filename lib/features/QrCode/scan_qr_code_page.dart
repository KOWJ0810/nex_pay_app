import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

class ScanQrCodePage extends StatefulWidget {
  const ScanQrCodePage({super.key});

  @override
  State<ScanQrCodePage> createState() => _ScanQrCodePageState();
}

class _ScanQrCodePageState extends State<ScanQrCodePage> {
  final MobileScannerController _controller = MobileScannerController();
  final FlutterSecureStorage _secureStorage = secureStorage;
  bool _isProcessing = false;
  bool _hasScanned = false;

  Future<void> _handleQrScanned(String qrPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please sign in again.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/qr/preview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qrPayload': qrPayload}),
      );

      final resData = jsonDecode(response.body);
      if (response.statusCode == 200 && resData['success'] == true) {
        final data = resData['data'];
        _hasScanned = true;

        context.pushNamed(
          RouteNames.enterAmount,
          extra: {
            'type': data['type'],
            'userId': data['userId'],
            'userName': data['userName'],
            'userPhone': data['userPhone'],
            'merchantId': data['merchantId'],
            'merchantName': data['merchantName'],
            'merchantType': data['merchantType'],
            'outletId': data['outletId'],
            'outletName': data['outletName'],
            'qrPayload': qrPayload,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'Invalid QR Code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning QR: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_hasScanned) return; // prevent multiple scans
              final barcode = capture.barcodes.first;
              final qrValue = barcode.rawValue;
              if (qrValue != null) {
                await _handleQrScanned(qrValue);
              }
            },
          ),
          // Scanner overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isProcessing ? 'Processing QR...' : 'Align QR within frame',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        child: const Icon(Icons.cameraswitch_rounded, color: primaryColor),
        onPressed: () => _controller.switchCamera(),
      ),
    );
  }
}