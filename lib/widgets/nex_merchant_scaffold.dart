import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';
import '../router.dart' show RouteNames;

class NexMerchantScaffold extends StatelessWidget {
  /// 0: Dashboard, 1: Transactions, 2: Profile, 3: Back
  final int currentIndex;
  final Widget body;

  const NexMerchantScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
  });

  void _go(BuildContext context, int i) {
    if (i == currentIndex) return;
    switch (i) {
      case 0:
        context.goNamed(RouteNames.merchantDashboard);
        break;
      case 1:
        context.goNamed(RouteNames.merchantTransactionHistory);
        break;
      case 2:
        context.goNamed(RouteNames.merchantAccount);
        break;
      case 3:
        context.goNamed(RouteNames.account);
        break;
    }
  }

  void _onScanTap(BuildContext context) {
    context.pushNamed(RouteNames.scanOutletList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () => _onScanTap(context),
          elevation: 4,
          backgroundColor: accentColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 28, color: Color(0xFF0E231B)),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: currentIndex,
        onTap: (i) => _go(context, i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8FFE9);
    return BottomAppBar(
      elevation: 12,
      color: bg,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', selected: currentIndex == 0, onTap: () => onTap(0)),
                    _NavItem(icon: Icons.receipt_long_rounded, label: 'Transaction', selected: currentIndex == 1, onTap: () => onTap(1)),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: currentIndex == 2, onTap: () => onTap(2)),
                    _NavItem(icon: Icons.arrow_back_rounded, label: 'Back', selected: currentIndex == 3, onTap: () => onTap(3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const color = Colors.black87;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}