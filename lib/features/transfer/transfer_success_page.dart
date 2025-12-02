import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';

class TransferSuccessPage extends StatefulWidget {
  final int transactionId;
  final String transactionRefNum;
  final double amount;
  final int? senderUserId;
  final int? receiverUserId;
  final String? type;
  final String? status;
  final int? merchantId;
  final int? outletId;

  const TransferSuccessPage({
    super.key,
    required this.transactionId,
    required this.transactionRefNum,
    required this.amount,
    this.senderUserId,
    this.receiverUserId,
    this.type,
    this.status,
    this.merchantId,
    this.outletId,
  });

  @override
  State<TransferSuccessPage> createState() => _TransferSuccessPageState();
}

class _TransferSuccessPageState extends State<TransferSuccessPage> {
  // Controller to capture the widget
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  Future<void> _downloadReceipt() async {
    setState(() => _isSaving = true);

    try {
      // 1. Request Permission (Gal handles this automatically on most modern versions, 
      // but good to check if you want specific handling)
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Capture the widget as bytes
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        // 3. Save to Gallery
        await Gal.putImageBytes(imageBytes, name: "NexPay_Receipt_${widget.transactionRefNum}");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt saved to Gallery!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Dark background for the app screen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Transfer Success',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Container(), // Hide back button to force "Done"
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ─── CAPTURE AREA START ─────────────────────────────
              // We wrap the receipt part in Screenshot. 
              // We add a Container with color: Colors.white to ensure the 
              // saved image has a white background, even if the app bg is dark.
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: accentColor, size: 80),
                      const SizedBox(height: 16),
                      const Text(
                        'Transfer Successful',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.transactionRefNum,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Amount Hero
                      Text(
                        'Amount Paid',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Details
                      _buildRow('Transaction ID', widget.transactionId.toString()),
                      
                      // P2P Logic
                      if (widget.type == "P2P" && widget.receiverUserId != null)
                        _buildRow('Receiver ID', widget.receiverUserId.toString()),

                      // Merchant Logic
                      if (widget.type == "MERCHANT_OUTLET") ...[
                        if (widget.merchantId != null)
                          _buildRow('Merchant ID', widget.merchantId.toString()),
                        if (widget.outletId != null)
                          _buildRow('Outlet ID', widget.outletId.toString()),
                      ],

                      if (widget.type != null) 
                        _buildRow('Payment Type', widget.type!),
                      
                      if (widget.status != null) 
                        _buildRow('Status', widget.status!),
                        
                      const SizedBox(height: 20),
                      // Footer for the receipt image
                      const Text(
                        "NexPay Digital Receipt",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      )
                    ],
                  ),
                ),
              ),
              // ─── CAPTURE AREA END ───────────────────────────────

              const SizedBox(height: 30),

              // Download Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _downloadReceipt,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accentColor, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: accentColor),
                  label: Text(
                    _isSaving ? "Saving..." : "Download Receipt",
                    style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Done Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.goNamed(RouteNames.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF102520),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}