import 'package:fitflow/core/design/widgets/fitflow_navigation.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App shell shown after the splash: content area plus adaptive navigation.
///
/// Destinations and routes are unchanged. Compact widths use a bottom bar;
/// expanded widths use a rail.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final programsRoute =
        path == AppRoutes.programs || path.startsWith('${AppRoutes.programs}/');
    return FitFlowNavigationShell(
      // Programs uses the real shell, outside its scoped content theme.
      // Leave room for icon + wrapped labels above the system safe area.
      bottomBarMinHeight: programsRoute ? 80 : null,
      selectedIndex: navigationShell.currentIndex,
      onSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        FitFlowNavDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.navHome,
        ),
        FitFlowNavDestination(
          icon: Icons.fitness_center_outlined,
          selectedIcon: Icons.fitness_center,
          label: l10n.navWorkouts,
        ),
        FitFlowNavDestination(
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          label: l10n.navProgress,
        ),
        FitFlowNavDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.navProfile,
        ),
      ],
      body: navigationShell,
    );
  }
}
