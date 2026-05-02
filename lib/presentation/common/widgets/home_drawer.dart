// lib/presentation/features/home/home_drawer.dart
//
// Drawer for HomeScreen.
// Add this to your HomeScreen scaffold as the `drawer` parameter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../common/providers/providers.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/terms_and_policy/privacy_screen.dart';
import '../../features/terms_and_policy/terms_screens.dart';

// ── App version provider ───────────────────────────────────
final _versionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version} (${info.buildNumber})';
  } catch (_) {
    return 'v1.0.0';
  }
});

// ── Profile + stats provider ───────────────────────────────
final drawerProfileProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final profileRes = await ref.read(getProfileUseCaseProvider).call();
  final profile = profileRes.fold((_) => <String, dynamic>{}, (p) => p ?? {});

  final tournamentsRes = await ref.read(getMyTournamentsUseCaseProvider).call();
  final tournaments =
  tournamentsRes.fold((_) => [], (list) => list);

  // Count total completed matches across all tournaments
  int totalMatches = 0;
  for (final t in tournaments) {
    final matchRes = await ref.read(getMatchesUseCaseProvider).call(t.id);
    matchRes.fold((_) {}, (matches) {
      totalMatches +=
          matches.where((m) => m.status == 'completed').length;
    });
  }

  return {
    'name':            profile['display_name'] ?? 'Tournament Organizer',
    'email':           profile['email'] ?? '',
    'avatar_url':      profile['avatar_url'],
    'tournament_count': tournaments.length,
    'match_count':     totalMatches,
  };
});

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(drawerProfileProvider);
    final version = ref.watch(_versionProvider);

    return Drawer(
      backgroundColor: AppColors.bg2,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            profile.when(
              loading: () => const _HeaderShimmer(),
              error: (_, __) => const _HeaderFallback(),
              data: (data) => _Header(data: data),
            ),

            const Divider(color: AppColors.border, height: 1),

            // ── Menu Items ────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [

                  _DrawerItem(
                    icon:  Icons.leaderboard_outlined,
                    label: 'Leaderboard',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to most recent tournament leaderboard
                      // or tournament list to pick one
                      context.go(AppRoutes.tournamentDetail);
                    },
                  ),

                  const _DrawerDivider(),

                  _DrawerItem(
                    icon:  Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _DrawerItem(
                    icon:  Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  const _DrawerDivider(),

                  _DrawerItem(
                    icon:  Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsScreen(),
                        ),
                      );
                    },
                  ),

                  _DrawerItem(
                    icon:  Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),

                  const _DrawerDivider(),

                  _DrawerItem(
                    icon:  Icons.delete_outline,
                    label: 'Delete Account',
                    color: AppColors.danger,
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),

                  _DrawerItem(
                    icon:  Icons.logout,
                    label: 'Logout',
                    color: AppColors.danger,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),

            // ── Version ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: version.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (v) => Text(
                  'PointCalc $v',
                  style: AppTextStyles.label(
                      color: AppColors.muted, size: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Logout',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await ref.read(signOutUseCaseProvider).call();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Text('Logout',
                style: AppTextStyles.label(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Delete Account',
            style: AppTextStyles.heading(size: 16,
                color: AppColors.danger)),
        content: Text(
          'This will permanently delete your account and all tournament data. This action cannot be undone.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: implement delete account use case
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Account deletion requested. Contact support to complete.'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: Text('Delete',
                style: AppTextStyles.label(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Header({required this.data});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.yellow.withOpacity(0.15),
          backgroundImage: data['avatar_url'] != null
              ? NetworkImage(data['avatar_url'] as String)
              : null,
          child: data['avatar_url'] == null
              ? Text(
            ((data['name'] as String?) ?? 'U')
                .substring(0, 1)
                .toUpperCase(),
            style: AppTextStyles.heading(
                size: 24, color: AppColors.yellow),
          )
              : null,
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          data['name'] as String? ?? 'Organizer',
          style: AppTextStyles.heading(size: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),

        // Email
        Text(
          data['email'] as String? ?? '',
          style: AppTextStyles.body(color: AppColors.muted, size: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _StatChip(
              label: 'Tournaments',
              value: '${data['tournament_count'] ?? 0}',
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: 'Matches',
              value: '${data['match_count'] ?? 0}',
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.yellow.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: AppColors.yellow.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.heading(
                size: 16, color: AppColors.yellow)),
        Text(label,
            style: AppTextStyles.label(
                color: AppColors.muted, size: 9)),
      ],
    ),
  );
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: SizedBox(height: 120),
  );
}

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.yellow.withOpacity(0.15),
          child: const Icon(Icons.person,
              color: AppColors.yellow, size: 28),
        ),
        const SizedBox(width: 12),
        Text('Organizer',
            style: AppTextStyles.heading(size: 15)),
      ],
    ),
  );
}

// ── Drawer Item ────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon,
        color: color ?? AppColors.muted, size: 20),
    title: Text(label,
        style: AppTextStyles.body(
            color: color ?? AppColors.white, size: 14)),
    onTap: onTap,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    dense: true,
  );
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();
  @override
  Widget build(BuildContext context) => const Divider(
    color: AppColors.border,
    height: 16,
    indent: 20,
    endIndent: 20,
  );
}