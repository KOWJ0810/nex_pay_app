import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:screenshot/screenshot.dart'; // Import Screenshot
import 'package:gal/gal.dart'; // Import Gal
import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';

class UserTransactionDetailPage extends StatefulWidget {
  final int transactionId;

  const UserTransactionDetailPage({super.key, required this.transactionId});

  @override
  State<UserTransactionDetailPage> createState() => _UserTransactionDetailPageState();
}

class _UserTransactionDetailPageState extends State<UserTransactionDetailPage> {
  final storage = secureStorage;
  
  // Screenshot Controller
  final ScreenshotController _screenshotController = ScreenshotController();
  
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSaving = false; // For download loading state
  String? _errorMessage;

  // Formatters
  final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
  final dateFormat = DateFormat('dd MMM yyyy, h:mm a');

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        setState(() => _errorMessage = "Session expired.");
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/history/detail/${widget.transactionId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          setState(() {
            _data = jsonRes; 
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to load details.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server error: ${res.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  // ─── DOWNLOAD LOGIC ────────────────────────────────────────────────────────
  Future<void> _downloadReceipt() async {
    setState(() => _isSaving = true);

    try {
      // 1. Permission Check
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2. Capture Image
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        // 3. Save to Gallery
        await Gal.putImageBytes(
          imageBytes, 
          name: "NexPay_Txn_${widget.transactionId}"
        );
        
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
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Transaction Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Optional: Top right download icon as well
          if (!_isLoading && _data != null)
            IconButton(
              onPressed: _isSaving ? null : _downloadReceipt,
              icon: const Icon(Icons.download_rounded, color: Colors.white),
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                  child: Column(
                    children: [
                      // ─── START SCREENSHOT AREA ───
                      Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          // Add padding/color here to ensure the saved image looks like the app view
                          color: primaryColor, 
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: Column(
                            children: [
                              // Amount Hero
                              Text(
                                _data?['role'] == 'RECEIVER' ? "Received" : "Paid",
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(_data?['amount'] ?? 0),
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _data?['status'] ?? 'UNKNOWN',
                                  style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Receipt Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Party Info
                                    if (_data?['counterpartyName'] != null) ...[
                                      _InfoRow(
                                        label: _data?['role'] == 'SENDER' ? "To" : "From",
                                        value: _data!['counterpartyName'],
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    
                                    // 2. Merchant Info
                                    if (_data?['merchantName'] != null) ...[
                                      _InfoRow(
                                        label: "Merchant",
                                        value: _data!['merchantName'],
                                        subValue: _data?['outletName'],
                                        icon: Icons.storefront_rounded,
                                      ),
                                      const SizedBox(height: 20),
                                    ],

                                    Divider(color: Colors.grey[200], thickness: 1.5),
                                    const SizedBox(height: 20),

                                    // 3. Details
                                    _DetailRow(label: "Date", value: _formatDate(_data?['transactionDateTime'])),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: "Type", value: _data?['action'] ?? '-'),
                                    const SizedBox(height: 12),
                                    _DetailRow(label: "Method", value: _data?['paymentType'] ?? '-'),
                                    const SizedBox(height: 12),
                                    if (_data?['category'] != null)
                                      _DetailRow(label: "Category", value: _data!['category']),
                                    
                                    const SizedBox(height: 24),
                                    Divider(color: Colors.grey[200], thickness: 1.5),
                                    const SizedBox(height: 24),

                                    // 4. Reference
                                    Center(
                                      child: Column(
                                        children: [
                                          Text("Reference No.", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                          const SizedBox(height: 4),
                                          SelectableText(
                                            _data?['transactionRefNum'] ?? '-',
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Center(
                                      child: Text(
                                        "NexPay Digital Receipt",
                                        style: TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // ─── END SCREENSHOT AREA ───

                      const SizedBox(height: 30),

                      // Download Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _downloadReceipt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: const BorderSide(color: accentColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: _isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accentColor, strokeWidth: 2))
                            : const Icon(Icons.download_rounded),
                          label: Text(_isSaving ? "Saving..." : "Download Receipt", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      return dateFormat.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ─── Helpers ───

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;

  const _InfoRow({required this.label, required this.value, this.subValue, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              if (subValue != null)
                Text(subValue!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
      ],
    );
  }
}