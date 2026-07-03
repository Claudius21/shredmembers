import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    route: AppRoutes.home,
  ),
  _NavItem(
    label: 'Plans',
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center_rounded,
    route: AppRoutes.plans,
  ),
  _NavItem(
    label: 'Progress',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart_rounded,
    route: AppRoutes.progress,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    route: AppRoutes.profile,
  ),
];

String _localizedNavLabel(BuildContext context, String route) {
  final l10n = AppLocalizations.of(context)!;
  switch (route) {
    case AppRoutes.home:
      return l10n.homeTitle;
    case AppRoutes.plans:
      return l10n.plansTitle;
    case AppRoutes.progress:
      return l10n.progressTitle;
    case AppRoutes.profile:
      return l10n.profileTitle;
    default:
      return '';
  }
}

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.plans)) return 1;
    if (location.startsWith(AppRoutes.progress)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _locationToIndex(location);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _SideNav(selectedIndex: selectedIndex),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _BottomNav(selectedIndex: selectedIndex),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;

  const _BottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => context.go(_navItems[i].route),
      destinations: _navItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: _localizedNavLabel(context, item.route),
            ),
          )
          .toList(),
    );
  }
}

class _SideNav extends StatelessWidget {
  final int selectedIndex;

  const _SideNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'shredMembers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = i == selectedIndex;
              return _SideNavItem(item: item, isSelected: isSelected, index: i);
            }),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final int index;

  const _SideNavItem({
    required this.item,
    required this.isSelected,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color:
                      isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  _localizedNavLabel(context, item.route),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
