// lib/widgets/nex_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';
import '../router.dart' show RouteNames;

class NexScaffold extends StatelessWidget {
  /// 0: Home, 1: Transactions, 2: PayChat, 3: Account
  final int currentIndex;
  final Widget body;

  const NexScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
  });

  void _go(BuildContext context, int i) {
    if (i == currentIndex) return;
    switch (i) {
      case 0:
        context.goNamed(RouteNames.home);      // ✅ by name
        break;
      case 1:
        // TODO: register a route first, e.g. RouteNames.transactions
        // context.goNamed(RouteNames.transactions);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions page coming soon')),
        );
        break;
      case 2:
        // TODO: register a route first, e.g. RouteNames.paychat
        // context.goNamed(RouteNames.paychat);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PayChat page coming soon')),
        );
        break;
      case 3:
        context.goNamed(RouteNames.account);   // ✅ by name (no leading slash)
        break;
    }
  }

  void _onScanTap(BuildContext context) {
    // Example: context.pushNamed(RouteNames.scan);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open scanner…')),
    );
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
          child: const Icon(Icons.crop_free_rounded, size: 28, color: Color(0xFF0E231B)),
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
                    _NavItem(icon: Icons.home_rounded, label: 'Home', selected: currentIndex == 0, onTap: () => onTap(0)),
                    _NavItem(icon: Icons.swap_horiz_rounded, label: 'Transaction', selected: currentIndex == 1, onTap: () => onTap(1)),
                  ],
                ),
              ),
              const SizedBox(width: 72),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(icon: Icons.chat_bubble_rounded, label: 'PayChat', selected: currentIndex == 2, onTap: () => onTap(2)),
                    _NavItem(icon: Icons.person_rounded, label: 'Account', selected: currentIndex == 3, onTap: () => onTap(3)),
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