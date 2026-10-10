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
  });

  final Widget body;
  final List<FitFlowNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final expanded = FitFlowLayout.fromWidth(constraints.maxWidth) ==
          FitFlowWindowSize.expanded;
      if (expanded) {
        return Scaffold(
          body: Row(
            children: [
              _FitFlowNavigationRail(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
              ),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(
        body: body,
        bottomNavigationBar: _FitFlowBottomBar(
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
  });

  final List<FitFlowNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.divider)),
      ),
      child: NavigationBar(
        animationDuration: SystemMotion.standard(context),
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
                      overflow: TextOverflow.ellipsis,
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
