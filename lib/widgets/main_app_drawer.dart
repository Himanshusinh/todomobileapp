import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/screens/profile_screen.dart';

/// Left drawer: profile header, theme, shortcuts, logout.
class MainAppDrawer extends StatelessWidget {
  const MainAppDrawer({
    super.key,
    required this.onCalendar,
    required this.onNotifications,
    required this.onSettings,
    this.notificationCount = 0,
  });

  final VoidCallback onCalendar;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final int notificationCount;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Account';
    final email = user?.email ?? '';

    return Drawer(
      width: math.min(
        288.0,
        MediaQuery.sizeOf(context).width * 0.86,
      ),
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — Profile (replaces app title) —
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(
                                _avatarInitial(
                                  displayName: user?.displayName,
                                  email: email,
                                ),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            // — Theme (outside Settings) —
            Consumer<ThemeProvider>(
              builder: (context, tp, _) {
                return SwitchListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  secondary: Icon(
                    tp.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 22,
                    color: cs.onSurfaceVariant,
                  ),
                  title: Text(
                    'Dark mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: tp.isDarkMode,
                  onChanged: (v) => tp.setDarkMode(v),
                );
              },
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            // — Shortcuts —
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Calendar',
                    onTap: onCalendar,
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: onNotifications,
                    badge: notificationCount > 0 ? notificationCount : null,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: onSettings,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            // — Logout —
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: cs.error,
                ),
                title: Text(
                  'Log out',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.error,
                  ),
                ),
                onTap: () async {
                  await _logout(context);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _avatarInitial({
  required String? displayName,
  required String email,
}) {
  final n = displayName?.trim();
  if (n != null && n.isNotEmpty) {
    return n[0].toUpperCase();
  }
  if (email.isNotEmpty) {
    return email[0].toUpperCase();
  }
  return '?';
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Icon(icon, size: 22, color: cs.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: cs.outline,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
