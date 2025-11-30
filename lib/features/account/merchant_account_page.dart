import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Import intl for currency formatting
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:nex_pay_app/widgets/nex_merchant_scaffold.dart';

class MerchantAccountPage extends StatefulWidget {
  const MerchantAccountPage({super.key});

  @override
  State<MerchantAccountPage> createState() => _MerchantAccountPageState();
}

class _MerchantAccountPageState extends State<MerchantAccountPage> {
  final storage = secureStorage;
  Map<String, dynamic>? merchantData;
  bool isLoading = true;
  String? errorMessage;

  // Formatter
  final currencyFormat = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _fetchMerchantData();
  }

  Future<void> _fetchMerchantData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        if(mounted) setState(() => errorMessage = 'Session expired.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/merchants/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final jsonRes = jsonDecode(res.body);
      if (res.statusCode == 200 && jsonRes['success'] == true) {
        if(mounted) setState(() => merchantData = jsonRes['data']);
      } else if (res.statusCode == 404 && jsonRes['success'] == false) {
        if(mounted) context.goNamed(RouteNames.merchantRegisterLanding);
      } else {
        if(mounted) setState(() => errorMessage = jsonRes['message']);
      }
    } catch (e) {
      if(mounted) setState(() => errorMessage = 'Error: $e');
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate width for 3 items per row with spacing
    // Screen width - padding (40) - spacing (24 for 2 gaps) / 3 items
    final double itemWidth = (MediaQuery.of(context).size.width - 40 - 24) / 3;

    return NexMerchantScaffold(
      currentIndex: 2,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              // WRAPPER CONTAINER: Fixes the "White gap" issue at the bottom
              : Container(
                  color: const Color(0xFFF4F6F8),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ─────────── 1. Modern Header ───────────
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        expandedHeight: 300,
                        pinned: true,
                        backgroundColor: primaryColor,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            children: [
                              // Gradient BG
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, const Color(0xFF0D201C)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              // Decorative Circle
                              Positioned(
                                top: -50, right: -50,
                                child: Container(
                                  width: 200, height: 200,
                                  decoration: BoxDecoration(color: accentColor.withOpacity(0.05), shape: BoxShape.circle),
                                ),
                              ),
                              
                              // Content
                              SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('My Business', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.verified, color: accentColor, size: 14),
                                                const SizedBox(width: 6),
                                                Text(merchantData?['status'] ?? 'Active', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Glass Card (Profile + Balance)
                                      _GlassCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Profile Row
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor: Colors.white.withOpacity(0.1),
                                                  backgroundImage: merchantData?['ssmImageUpload'] != null 
                                                      ? NetworkImage(merchantData!['ssmImageUpload']) 
                                                      : null,
                                                  child: merchantData?['ssmImageUpload'] == null 
                                                      ? const Icon(Icons.store, color: Colors.white70) 
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(merchantData?['merchantName'] ?? 'Merchant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                      Text(merchantData?['merchantType'] ?? 'Business', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {}, // Edit Profile
                                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Divider(color: Colors.white.withOpacity(0.1), height: 1),
                                            const SizedBox(height: 16),
                                            // Balance Row (Hero)
                                            Text("Wallet Balance", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                                            const SizedBox(height: 4),
                                            Text(
                                              currencyFormat.format(merchantData?['totalWalletBalance'] ?? 0),
                                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─────────── 2. Body Content ───────────
                      SliverToBoxAdapter(
                        child: Container(
                          transform: Matrix4.translationValues(0, -20, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F6F8),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Spacing
                              const SizedBox(height: 12),

                              // Action Grid
                              const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                              const SizedBox(height: 16),
                              
                              // NEW: WRAP LAYOUT for Multi-line Actions
                              Wrap(
                                spacing: 12, // Horizontal gap
                                runSpacing: 16, // Vertical gap
                                alignment: WrapAlignment.start,
                                children: [
                                  _ActionItem(
                                    width: itemWidth,
                                    icon: Icons.storefront_rounded, 
                                    label: "Outlets", 
                                    color: Colors.orange,
                                    onTap: () => context.pushNamed(RouteNames.merchantOutletList),
                                  ),
                                  _ActionItem(
                                    width: itemWidth,
                                    icon: Icons.qr_code_2_rounded, 
                                    label: "Get QR", 
                                    color: accentColor,
                                    onTap: () => context.pushNamed(RouteNames.outletListQrCode),
                                  ),
                                  _ActionItem(
                                    width: itemWidth,
                                    icon: Icons.link_rounded, 
                                    label: "Pay Link", 
                                    color: Colors.blueAccent,
                                    onTap: () => context.pushNamed(RouteNames.outletListPaymentLink),
                                  ),
                                  
                                  // NEW WITHDRAW BUTTON
                                  _ActionItem(
                                    width: itemWidth,
                                    icon: Icons.download_rounded, 
                                    label: "Withdraw", 
                                    color: Colors.purpleAccent,
                                    onTap: () => context.pushNamed(RouteNames.withdrawList),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Business Details Card
                              const Text("Business Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                child: Column(
                                  children: [
                                    _DetailRow(label: "Registration Code", value: merchantData?['businessRegistrationCode'] ?? '-'),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                    _DetailRow(
                                      label: "Bank Account", 
                                      value: merchantData?['bankAccountNum'] ?? '-',
                                      canCopy: true,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Spacer
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ─────────── Components ───────────

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double width; // Added width control

  const _ActionItem({
    required this.icon, 
    required this.label, 
    required this.color, 
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, // Use dynamic width
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color == accentColor ? const Color(0xFF4A7A00) : color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor)
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _DetailRow({required this.label, required this.value, this.canCopy = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(value, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
            if (canCopy)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey[400]),
                ),
              )
          ],
        )
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}