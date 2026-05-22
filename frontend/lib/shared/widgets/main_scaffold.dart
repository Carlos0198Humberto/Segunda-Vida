import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_strings.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabDefs = [
    (path: '/dashboard', icon: Icons.grid_view_outlined,             activeIcon: Icons.grid_view_rounded,          key: 'nav_home'),
    (path: '/finance',   icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, key: 'nav_finance'),
    (path: '/savings',   icon: Icons.savings_outlined,               activeIcon: Icons.savings_rounded,            key: 'nav_savings'),
    (path: '/habits',    icon: Icons.radio_button_unchecked,         activeIcon: Icons.check_circle_rounded,       key: 'nav_habits'),
    (path: '/health',    icon: Icons.favorite_border_rounded,        activeIcon: Icons.favorite_rounded,           key: 'nav_health'),
    (path: '/skills',    icon: Icons.trending_up_outlined,           activeIcon: Icons.trending_up_rounded,        key: 'nav_skills'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabDefs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabDefs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.grid_view_outlined, size: 22),    selectedIcon: const Icon(Icons.grid_view_rounded, size: 22),                  label: s.navHome),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined, size: 22), selectedIcon: const Icon(Icons.account_balance_wallet_rounded, size: 22), label: s.navFinance),
          NavigationDestination(icon: const Icon(Icons.savings_outlined, size: 22),      selectedIcon: const Icon(Icons.savings_rounded, size: 22),                    label: s.navSavings),
          NavigationDestination(icon: const Icon(Icons.radio_button_unchecked, size: 22),selectedIcon: const Icon(Icons.check_circle_rounded, size: 22),               label: s.navHabits),
          NavigationDestination(icon: const Icon(Icons.favorite_border_rounded, size: 22),selectedIcon: const Icon(Icons.favorite_rounded, size: 22),                  label: s.navHealth),
          NavigationDestination(icon: const Icon(Icons.trending_up_outlined, size: 22),  selectedIcon: const Icon(Icons.trending_up_rounded, size: 22),                label: s.navSkills),
        ],
      ),
    );
  }
}
