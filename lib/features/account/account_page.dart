// lib/pages/account_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../widgets/nex_scaffold.dart';
import '../../router.dart' show RouteNames;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final String fullName = 'Kenneph Lee';
  final String phone = '+60 12-345 6789';
  final String email = 'kenneph@example.com';
  final String userId = 'UID-9F2A-88C1';

  bool _pushNoti = true;
  bool _marketingNoti = false;
  bool _biometrics = true;

  static const double _extraFabClearance = 76;
  static const double _reservedBottomSpace =
      kBottomNavigationBarHeight + _extraFabClearance;

  void _onDevices(BuildContext context) {
    context.pushNamed(RouteNames.trustedDevices);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return NexScaffold(
      currentIndex: 3,
      body: CustomScrollView(
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
                          children: [
                            const Text(
                              'Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const Spacer(),
                            _glassIconButton(Icons.settings_rounded,
                                onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _GlassCard(
                          child: Row(
                            children: [
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(.28)),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fullName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(.92)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _onEditProfile,
                                child: const Text('Edit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader('Basic Information'),
                    _CardSection(children: [
                      _InfoTile(
                          icon: Icons.badge_rounded,
                          title: 'Full name',
                          value: fullName,
                          onTap: _onEditProfile),
                      _InfoTile(
                          icon: Icons.phone_rounded,
                          title: 'Phone',
                          value: phone,
                          onTap: _onEditPhone),
                      _InfoTile(
                          icon: Icons.mail_rounded,
                          title: 'Email',
                          value: email,
                          onTap: _onEditEmail),
                      _InfoTile(
                        icon: Icons.fingerprint_rounded,
                        title: 'User ID',
                        value: userId,
                        trailing: const Icon(Icons.copy_rounded, size: 18),
                        onTap: _copyUserId,
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _SectionHeader('Security & Devices'),
                    _CardSection(children: [
                      _SwitchTile(
                        icon: Icons.face_rounded,
                        title: 'Biometrics (Face/Touch ID)',
                        value: _biometrics,
                        onChanged: (v) => setState(() => _biometrics = v),
                      ),
                      _NavTile(
                        icon: Icons.shield_rounded,
                        title: 'Change PIN / Password',
                        onTap: _onChangePin,
                      ),
                      _NavTile(
                        icon: Icons.devices_other_rounded,
                        title: 'Trusted devices',
                        subtitle: 'Manage signed-in phones & browsers',
                        onTap: () => _onDevices(context),
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _SectionHeader('Notifications'),
                    _CardSection(children: [
                      _SwitchTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Push notifications',
                        value: _pushNoti,
                        onChanged: (v) => setState(() => _pushNoti = v),
                      ),
                      _SwitchTile(
                        icon: Icons.campaign_rounded,
                        title: 'Promotions & updates',
                        value: _marketingNoti,
                        onChanged: (v) => setState(() => _marketingNoti = v),
                      ),
                    ]),

                    const SizedBox(height: 16),
                    _SectionHeader('Privacy'),
                    _CardSection(children: [
                      _NavTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy policy',
                          onTap: () =>
                              _openWeb('https://example.com/privacy')),
                      _NavTile(
                          icon: Icons.description_rounded,
                          title: 'Terms of service',
                          onTap: () =>
                              _openWeb('https://example.com/terms')),
                    ]),

                    const SizedBox(height: 16),
                    _SectionHeader('Support'),
                    _CardSection(children: [
                      _NavTile(
                          icon: Icons.help_center_rounded,
                          title: 'Help center',
                          onTap: _onHelp),
                      _NavTile(
                          icon: Icons.bug_report_rounded,
                          title: 'Report a problem',
                          onTap: _onReport),
                    ]),

                    const SizedBox(height: 28),

                    // ─────────── Logout button ───────────
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _confirmLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Log out',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: _reservedBottomSpace + bottomPad),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Logout logic ───────────
  Future<void> _confirmLogout() async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You’ll need to sign in again to access your account.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (ok == true && mounted) {
    final prefs = await SharedPreferences.getInstance();

    final deviceId = prefs.getString('device_id');
    await prefs.clear();
    if (deviceId != null) {
      await prefs.setString('device_id', deviceId);
    }

    const secure = FlutterSecureStorage();
    await secure.deleteAll();

    _toast('Signed out');

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    context.goNamed(RouteNames.login);
  }
}

  // ─────────── Helper methods ───────────
  void _onEditProfile() => _toast('Edit profile (coming soon)');
  void _onEditPhone() => _toast('Change phone (coming soon)');
  void _onEditEmail() => _toast('Change email (coming soon)');
  void _onChangePin() => _toast('Change PIN / Password (coming soon)');
  void _onHelp() => _toast('Help center (coming soon)');
  void _onReport() => _toast('Report a problem (coming soon)');
  void _openWeb(String url) => _toast('Open: $url');

  void _copyUserId() {
    _toast('User ID copied');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
      child: Column(
          children: children.divide(const Divider(height: 1)).toList()),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile(
      {required this.icon,
      required this.title,
      required this.value,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
          radius: 20,
          backgroundColor: accentColor.withOpacity(.16),
          child: Icon(icon, color: primaryColor)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
          radius: 20,
          backgroundColor: accentColor.withOpacity(.16),
          child: Icon(icon, color: primaryColor)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile(
      {required this.icon,
      required this.title,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
          radius: 20,
          backgroundColor: accentColor.withOpacity(.16),
          child: Icon(icon, color: primaryColor)),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Switch.adaptive(
          value: value, onChanged: onChanged, activeColor: primaryColor),
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

Widget _glassIconButton(IconData icon, {required VoidCallback onTap}) {
  return InkResponse(
    onTap: onTap,
    radius: 28,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}