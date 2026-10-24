import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

class FitFlowNavDestination {
  const FitFlowNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Shared navigation chrome. Compact widths keep a bottom bar. Expanded
/// widths use a rail. Routes are unchanged; this only chooses the visual
/// treatment from the available width.
class FitFlowNavigationShell extends StatelessWidget {
  const FitFlowNavigationShell({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.bottomBarMinHeight,
  });

  final Widget body;
  final List<FitFlowNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? bottomBarMinHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final expanded = FitFlowLayout.fromWidth(constraints.maxWidth) ==
          FitFlowWindowSize.expanded;
      // Keep the body in the same element position across bar/rail reflow.
      // This preserves branch-local widget state when the window is resized.
      return Scaffold(
        body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (expanded)
            _FitFlowNavigationRail(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            ),
          Expanded(child: body),
        ]),
        bottomNavigationBar: expanded
            ? null
            : _FitFlowBottomBar(
                minHeight: bottomBarMinHeight,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
              ),
      );
    });
  }
}

class _FitFlowBottomBar extends StatelessWidget {
  const _FitFlowBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.minHeight,
  });

  final List<FitFlowNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.divider)),
      ),
      child: NavigationBar(
        animationDuration: SystemMotion.standard(context),
        height:
            MediaQuery.textScalerOf(context).scale(12) > 18 ? 96 : minHeight,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
              tooltip: destination.label,
            ),
        ],
      ),
    );
  }
}

class _FitFlowNavigationRail extends StatelessWidget {
  const _FitFlowNavigationRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FitFlowNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return SafeArea(
      right: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).navigationRailTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          border: Border(right: BorderSide(color: theme.divider)),
        ),
        child: SingleChildScrollView(
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -1,
              minWidth: SystemMotion.minTouchTarget + 32,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(
                      destination.label,
                      textAlign: TextAlign.center,
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
