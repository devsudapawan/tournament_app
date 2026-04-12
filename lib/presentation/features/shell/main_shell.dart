// lib/presentation/features/shell/main_shell.dart
//
// Bottom Navigation Bar wrapping all 4 main tabs.
// This is the persistent scaffold after login.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../home/home_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/profile/profile_screen.dart';
import '../tournament_list/tournament_list.dart';

// Tracks which tab is active
final _shellIndexProvider = StateProvider<int>((_) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required Widget child});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,        activeIcon: Icons.home,              label: 'Home'),
    _TabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events,      label: 'Tournaments'),
    _TabItem(icon: Icons.bar_chart_outlined,    activeIcon: Icons.bar_chart,         label: 'Dashboard'),
    _TabItem(icon: Icons.person_outline,        activeIcon: Icons.person,            label: 'Profile'),
  ];

  static const _screens = [
    HomeScreen(),
    TournamentListScreen(),
    DashboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_shellIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color:  AppColors.bg2,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab      = _tabs[i];
                final isActive = index == i;
                return GestureDetector(
                  onTap: () =>
                  ref.read(_shellIndexProvider.notifier).state = i,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width:  40, height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.yellow.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            color: isActive
                                ? AppColors.yellow
                                : AppColors.muted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: AppTextStyles.label(
                            color: isActive
                                ? AppColors.yellow
                                : AppColors.muted,
                            size: 10,
                            spacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}