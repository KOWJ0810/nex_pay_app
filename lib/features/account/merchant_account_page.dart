import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchMerchantData();
  }

  Future<void> _fetchMerchantData() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        setState(() => errorMessage = 'Session expired. Please login again.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/merchants/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final jsonRes = jsonDecode(res.body);
      if (res.statusCode == 200 && jsonRes['success'] == true) {
        setState(() => merchantData = jsonRes['data']);
      } else if (res.statusCode == 404 && jsonRes['success'] == false) {
        context.goNamed(RouteNames.merchantRegisterLanding);
      } else {
        setState(() => errorMessage = jsonRes['message'] ?? 'Failed to load merchant data.');
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onEditMerchantProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit merchant profile (coming soon)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NexMerchantScaffold(
      currentIndex: 2,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ─────────── Header ───────────
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      expandedHeight: 220,
                      elevation: 0,
                      pinned: false,
                      backgroundColor: primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(.85),
                                accentColor.withOpacity(.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Text(
                                        'Merchant',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _GlassCard(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundImage: NetworkImage(
                                              merchantData?['ssmImageUpload'] ?? ''),
                                          backgroundColor: Colors.white.withOpacity(.18),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                merchantData?['merchantName'] ??
                                                    'Unknown Merchant',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                merchantData?['merchantType'] ?? '-',
                                                style: TextStyle(
                                                    color: Colors.white.withOpacity(.92)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _onEditMerchantProfile,
                                          child: const Text(
                                            'Edit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ─────────── Content ───────────
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F6FA),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionHeader('Merchant Details'),
                              _CardSection(children: [
                                _InfoTile(
                                    icon: Icons.business_rounded,
                                    title: 'Business Code',
                                    value: merchantData?['businessRegistrationCode'] ?? '-'),
                                _InfoTile(
                                    icon: Icons.account_balance_rounded,
                                    title: 'Bank Account',
                                    value: merchantData?['bankAccountNum'] ?? '-'),
                                _InfoTile(
                                    icon: Icons.account_balance_wallet_rounded,
                                    title: 'Wallet Balance',
                                    value:
                                        'RM ${merchantData?['totalWalletBalance']?.toStringAsFixed(2) ?? '0.00'}'),
                                _InfoTile(
                                    icon: Icons.verified_rounded,
                                    title: 'Status',
                                    value: merchantData?['status'] ?? '-'),
                              ]),

                              const SizedBox(height: 16),
                              const _SectionHeader('Navigation'),
                              _CardSection(children: [
                                _NavTile(
                                  icon: Icons.store_rounded,
                                  title: 'Outlets',
                                  onTap: () => context.pushNamed(RouteNames.merchantOutletList),
                                ),
                                _NavTile(
                                  icon: Icons.link_rounded,
                                  title: 'Generate Payment Link',
                                  onTap: () => context.pushNamed(RouteNames.outletListPaymentLink),
                                ),
                                _NavTile(
                                  icon: Icons.qr_code_rounded,
                                  title: 'Generate Business QR',
                                  onTap: () => context.pushNamed(RouteNames.outletListQrCode),
                                ),
                              ]),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─────────── UI Components ───────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}

class _CardSection extends StatelessWidget {
  final List<Widget> children;
  const _CardSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: children.divide(const Divider(height: 1)).toList()),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          radius: 20,
          backgroundColor: accentColor.withOpacity(.16),
          child: Icon(icon, color: primaryColor)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
          radius: 20,
          backgroundColor: accentColor.withOpacity(.16),
          child: Icon(icon, color: primaryColor)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}

extension on List<Widget> {
  Iterable<Widget> divide(Widget divider) sync* {
    for (var i = 0; i < length; i++) {
      yield this[i];
      if (i != length - 1) yield divider;
    }
  }
}