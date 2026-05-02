// lib/presentation/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../common/providers/providers.dart';

// ── Settings State ─────────────────────────────────────────
class SettingsState {
  final bool matchReminders;
  final bool resultNotifications;
  final bool leaderboardUpdates;
  final bool soundEffects;
  final bool autoProcessImages;
  final bool showKillPoints;
  final bool showSlotNumbers;
  final bool confirmBeforeSave;
  final String defaultPointSystem; // 'bgmi' or 'custom'

  const SettingsState({
    this.matchReminders        = true,
    this.resultNotifications   = true,
    this.leaderboardUpdates    = true,
    this.soundEffects          = false,
    this.autoProcessImages     = true,
    this.showKillPoints        = true,
    this.showSlotNumbers       = true,
    this.confirmBeforeSave     = true,
    this.defaultPointSystem    = 'bgmi',
  });

  SettingsState copyWith({
    bool?   matchReminders,
    bool?   resultNotifications,
    bool?   leaderboardUpdates,
    bool?   soundEffects,
    bool?   autoProcessImages,
    bool?   showKillPoints,
    bool?   showSlotNumbers,
    bool?   confirmBeforeSave,
    String? defaultPointSystem,
  }) =>
      SettingsState(
        matchReminders:      matchReminders      ?? this.matchReminders,
        resultNotifications: resultNotifications ?? this.resultNotifications,
        leaderboardUpdates:  leaderboardUpdates  ?? this.leaderboardUpdates,
        soundEffects:        soundEffects        ?? this.soundEffects,
        autoProcessImages:   autoProcessImages   ?? this.autoProcessImages,
        showKillPoints:      showKillPoints      ?? this.showKillPoints,
        showSlotNumbers:     showSlotNumbers     ?? this.showSlotNumbers,
        confirmBeforeSave:   confirmBeforeSave   ?? this.confirmBeforeSave,
        defaultPointSystem:  defaultPointSystem  ?? this.defaultPointSystem,
      );
}

final settingsProvider =
StateProvider<SettingsState>((_) => const SettingsState());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading(size: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [

          // ── Notifications ──────────────────────────────
          _SectionHeader('Notifications'),
          _ToggleTile(
            icon:     Icons.notifications_outlined,
            title:    'Match Reminders',
            subtitle: 'Remind before scheduled matches',
            value:    settings.matchReminders,
            onChanged: (v) =>
            notifier.state = settings.copyWith(matchReminders: v),
          ),
          _ToggleTile(
            icon:     Icons.emoji_events_outlined,
            title:    'Result Notifications',
            subtitle: 'Notify when match results are saved',
            value:    settings.resultNotifications,
            onChanged: (v) =>
            notifier.state = settings.copyWith(resultNotifications: v),
          ),
          _ToggleTile(
            icon:     Icons.leaderboard_outlined,
            title:    'Leaderboard Updates',
            subtitle: 'Notify when standings change',
            value:    settings.leaderboardUpdates,
            onChanged: (v) =>
            notifier.state = settings.copyWith(leaderboardUpdates: v),
          ),

          // ── AI Processing ──────────────────────────────
          _SectionHeader('AI & Image Processing'),
          _ToggleTile(
            icon:     Icons.auto_fix_high_outlined,
            title:    'Auto Process Images',
            subtitle: 'Automatically start AI after image selection',
            value:    settings.autoProcessImages,
            onChanged: (v) =>
            notifier.state = settings.copyWith(autoProcessImages: v),
          ),
          _ToggleTile(
            icon:     Icons.save_outlined,
            title:    'Confirm Before Save',
            subtitle: 'Always show preview before saving results',
            value:    settings.confirmBeforeSave,
            onChanged: (v) =>
            notifier.state = settings.copyWith(confirmBeforeSave: v),
          ),

          // ── Display ────────────────────────────────────
          _SectionHeader('Display'),
          _ToggleTile(
            icon:     Icons.sports_kabaddi_outlined,
            title:    'Show Kill Points',
            subtitle: 'Display kill points separately in leaderboard',
            value:    settings.showKillPoints,
            onChanged: (v) =>
            notifier.state = settings.copyWith(showKillPoints: v),
          ),
          _ToggleTile(
            icon:     Icons.tag_outlined,
            title:    'Show Slot Numbers',
            subtitle: 'Display slot badges next to team names',
            value:    settings.showSlotNumbers,
            onChanged: (v) =>
            notifier.state = settings.copyWith(showSlotNumbers: v),
          ),

          // ── Points System ──────────────────────────────
          _SectionHeader('Points System'),
          _PointSystemTile(
            current:   settings.defaultPointSystem,
            onChanged: (v) =>
            notifier.state = settings.copyWith(defaultPointSystem: v),
          ),

          // ── Sound ──────────────────────────────────────
          _SectionHeader('Sound'),
          _ToggleTile(
            icon:     Icons.volume_up_outlined,
            title:    'Sound Effects',
            subtitle: 'Play sounds on actions and confirmations',
            value:    settings.soundEffects,
            onChanged: (v) =>
            notifier.state = settings.copyWith(soundEffects: v),
          ),

          // ── Account ────────────────────────────────────
          _SectionHeader('Account'),
          _ActionTile(
            icon:    Icons.lock_outline,
            title:   'Change Password',
            onTap:   () => _showChangePassword(context),
          ),
          _ActionTile(
            icon:    Icons.download_outlined,
            title:   'Export My Data',
            subtitle: 'Download all your tournament data',
            onTap:   () => _showExportData(context),
          ),
          _ActionTile(
            icon:    Icons.support_outlined,
            title:   'Contact Support',
            onTap:   () => _showContactSupport(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Change Password',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'A password reset email will be sent to your registered email address.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTextStyles.label(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Send Email',
                style: AppTextStyles.label(color: AppColors.yellow)),
          ),
        ],
      ),
    );
  }

  void _showExportData(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Export Data',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'Your tournament data export will be prepared and sent to your email within 24 hours.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: AppTextStyles.label(color: AppColors.yellow)),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text('Contact Support',
            style: AppTextStyles.heading(size: 16)),
        content: Text(
          'Email us at:\nsupport@pointcalc.app\n\nWe typically respond within 24 hours.',
          style: AppTextStyles.body(color: AppColors.grey, size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: AppTextStyles.label(color: AppColors.yellow)),
          ),
        ],
      ),
    );
  }
}

// ── Points System Selector ─────────────────────────────────
class _PointSystemTile extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _PointSystemTile(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_outlined,
                color: AppColors.yellow, size: 20),
            const SizedBox(width: 10),
            Text('Default Points System',
                style: AppTextStyles.body(
                    color: AppColors.white, size: 14)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _PointOption(
              label: 'BGMI Standard',
              sublabel: 'Rank 1=15, Kill=1',
              selected: current == 'bgmi',
              onTap: () => onChanged('bgmi'),
            ),
            const SizedBox(width: 10),
            _PointOption(
              label: 'Custom',
              sublabel: 'Set per tournament',
              selected: current == 'custom',
              onTap: () => onChanged('custom'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PointOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _PointOption({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.yellow.withOpacity(0.1)
              : AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.yellow
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.label(
                  color: selected
                      ? AppColors.yellow
                      : AppColors.white,
                  size: 12,
                )),
            const SizedBox(height: 2),
            Text(sublabel,
                style: AppTextStyles.label(
                    color: AppColors.muted, size: 10)),
          ],
        ),
      ),
    ),
  );
}

// ── Reusable Widgets ───────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
    child: Text(
      title.toUpperCase(),
      style: AppTextStyles.label(
          color: AppColors.yellow, size: 10, spacing: 1.5),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: SwitchListTile(
      secondary: Icon(icon, color: AppColors.yellow, size: 20),
      title: Text(title,
          style: AppTextStyles.body(color: AppColors.white, size: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style:
          AppTextStyles.body(color: AppColors.muted, size: 11))
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.yellow,
      inactiveTrackColor: AppColors.bg2,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.bg3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.yellow, size: 20),
      title: Text(title,
          style: AppTextStyles.body(color: AppColors.white, size: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!,
          style:
          AppTextStyles.body(color: AppColors.muted, size: 11))
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.muted, size: 18),
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    ),
  );
}