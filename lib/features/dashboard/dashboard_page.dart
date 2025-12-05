// lib/pages/dashboard_page.dart
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../widgets/nex_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FlutterSecureStorage _secureStorage = secureStorage;

  String? userName;
  double? balance;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTx = true;

  bool _hideBalance = false;
  late final NumberFormat _rm = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadSecureData();
    _loadRecentTransactions();
  }
  Future<void> _loadRecentTransactions() async {
    try {
      final token = await _secureStorage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization token not found. Please sign in again.')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final items = List<Map<String, dynamic>>.from(data['items']);
          setState(() {
            _transactions = items.take(5).toList();
            _isLoadingTx = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to load transactions.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    }
  }
  Future<void> _loadSecureData() async {
  try {
    final token = await _secureStorage.read(key: 'token');
    final userId = await _secureStorage.read(key: 'user_id');

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.')),
      );
      return;
    }

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['success'] == true && data['user'] != null) {
        setState(() {
          userName = data['user']['username'];
          balance = (data['user']['wallet_balance'] ?? 0.0).toDouble();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load user profile.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${res.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading user data: $e')),
    );
  }
}

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _hideBalance = prefs.getBool('hide_balance') ?? false);
  }

  Future<void> _setHideBalance(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_balance', v);
    if (mounted) setState(() => _hideBalance = v);
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return NexScaffold(
      currentIndex: 0,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        displacement: 72,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Gradient header that scrolls naturally ───────────────────────────
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 250,
              pinned: false,
              elevation: 0,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, primaryColor.withOpacity(.85), accentColor.withOpacity(.9)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // top row
                          Row(
                            children: [
                              const Text('NexPay',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                              const Spacer(),
                              _glassIconButton(Icons.notifications_rounded, onTap: () {}),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hello, ${userName ?? '...'} 👋',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Available Balance',
                                          style: TextStyle(color: Colors.white.withOpacity(0.9))),
                                      const SizedBox(height: 6),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: _hideBalance || balance == null
                                            ? Container(
                                                key: const ValueKey('hidden'),
                                                height: 26,
                                                width: 150,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              )
                                            : Text(
                                                _rm.format(balance),
                                                key: const ValueKey('shown'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _pillButton(label: _hideBalance ? 'Show' : 'Hide', onTap: () => _setHideBalance(!_hideBalance)),
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

            // ── White content area (ALL in one place; no background gaps) ─────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      Row(
                        children: [
                          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Spacer(),
                          TextButton(onPressed: () {}, child: const Text('Manage')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _ActionTile(icon: Icons.send_rounded, label: 'Send', onTap: () => context.pushNamed(RouteNames.searchTransferUser),)),
                          Expanded(child: _ActionTile(icon: Icons.attach_money_rounded, label: 'Pay', onTap: () => context.pushNamed(RouteNames.payQrCode),)),
                          Expanded(child: _ActionTile(
                            icon: Icons.request_page_rounded,
                            label: 'Request',
                            onTap: () => _handleRequestQr(context),
                          )),
                          Expanded(child: _ActionTile(icon: Icons.add_card_rounded, label: 'Top Up', onTap: () => context.pushNamed(RouteNames.topUp),)),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Recent Transactions
                      const Text('Recent Transactions',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      if (_isLoadingTx)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_transactions.isEmpty)
                        _emptyTransactions(context)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final tx = _transactions[i];
                            final isReceiver = tx['role'] == 'RECEIVER';
                            final amountColor = isReceiver ? Colors.green[600] : Colors.red[600];
                            final prefix = isReceiver ? '+' : '-';
                            final amount = double.tryParse(tx['amount'].toString())?.toStringAsFixed(2) ?? '0.00';
                            final name = tx['counterpartyName'] ?? 'Unknown';
                            final dateTime = tx['transactionDateTime'] != null
                                ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx['transactionDateTime']))
                                : '';
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: isReceiver ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                child: Icon(
                                  isReceiver ? Icons.call_received_rounded : Icons.call_made_rounded,
                                  color: isReceiver ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(dateTime, style: TextStyle(color: Theme.of(context).hintColor)),
                              trailing: Text(
                                '$prefix RM$amount',
                                style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                        ),

                      // keep clear of bottom bar & fab
                      SizedBox(height: 90 + bottomPad),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small UI helpers ────────────────────────────────────────────────────────────
  static Widget _glassIconButton(IconData icon, {required VoidCallback onTap}) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  static Widget _pillButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.28)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  static IconData _txIcon(String title, bool isIncome) {
    final t = title.toLowerCase();
    if (t.contains('bill')) return Icons.receipt_long_rounded;
    if (t.contains('transfer')) return isIncome ? Icons.call_received_rounded : Icons.call_made_rounded;
    if (t.contains('top up')) return Icons.add_card_rounded;
    if (t.contains('coffee') || t.contains('food')) return Icons.fastfood_rounded;
    return isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
  }

  static Widget _emptyTransactions(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Icon(Icons.inbox_outlined, color: Theme.of(context).hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No transactions yet. Start by making a payment or top up your wallet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  Widget _txItem(BuildContext context,
      {required String title, required String date, required double amount, required Color tagColor}) {
    final theme = Theme.of(context);
    final isIncome = amount >= 0;
    final icon = _txIcon(title, isIncome);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: ListTile(
        leading: CircleAvatar(radius: 22, backgroundColor: tagColor.withOpacity(.12), child: Icon(icon, color: tagColor)),
        title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${_rm.format(amount.abs())}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: isIncome ? Colors.green[600] : Colors.red[600],
            fontWeight: FontWeight.w800,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

// model
class _Tx {
  final String title;
  final String date;
  final double amount;
  final Color tagColor;
  const _Tx({required this.title, required this.date, required this.amount, required this.tagColor});
}

// glass card
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
          padding: const EdgeInsets.all(18),
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

// quick action tile
class _ActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _pressed ? 0.97 : 1.0,
          child: Ink(
            height: 92,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: primaryColor, size: 24),
                const SizedBox(height: 8),
                Text(widget.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
  Future<void> _handleRequestQr(BuildContext context) async {
  try {
    final FlutterSecureStorage _secureStorage = secureStorage;
    final token = await _secureStorage.read(key: 'token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No token found. Please sign in again.')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/qr/user/receive'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    final data = json.decode(response.body);

    if (data['success'] == true && data['data']?['payload'] != null) {
      final payload = data['data']['payload'];
      context.pushNamed(
        RouteNames.receiveQrCode,
        extra: {'payload': payload},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to fetch QR code. Please try again.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}