import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
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
            _NavigationAppearance(
                child: _FitFlowNavigationRail(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected,
            )),
          Expanded(child: body),
        ]),
        bottomNavigationBar: expanded
            ? null
            : _NavigationAppearance(
                child: _FitFlowBottomBar(
                minHeight: bottomBarMinHeight,
                destinations: destinations,
                selectedIndex: selectedIndex,
                onSelected: onSelected,
              )),
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
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
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
    final theme = Theme.of(context);
    return SafeArea(
      right: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).navigationRailTheme.backgroundColor ??
              Theme.of(context).colorScheme.surface,
          border: Border(right: BorderSide(color: theme.dividerColor)),
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

/// Scope the chrome independently: unfinished branch screens retain their theme.
class _NavigationAppearance extends StatelessWidget {
  const _NavigationAppearance({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final surface = dark ? const Color(0xFF282D2F) : Colors.white;
    final selected = dark ? const Color(0xFFF6F7F4) : const Color(0xFF171918);
    final inactive = dark ? const Color(0xFFBDC3C6) : const Color(0xFF606467);
    return Theme(
      data: base.copyWith(
        dividerColor: dark ? const Color(0xFF454D50) : const Color(0xFFDFE2E4),
        navigationBarTheme: base.navigationBarTheme.copyWith(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
                color:
                    states.contains(WidgetState.selected) ? selected : inactive,
                size: 24,
              )),
          labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => base.textTheme.labelMedium!.copyWith(
                    color: states.contains(WidgetState.selected)
                        ? selected
                        : inactive,
                    fontWeight: states.contains(WidgetState.selected)
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
        ),
        navigationRailTheme: base.navigationRailTheme.copyWith(
          backgroundColor: surface,
          indicatorColor: Colors.transparent,
          selectedIconTheme: IconThemeData(color: selected, size: 24),
          unselectedIconTheme: IconThemeData(color: inactive, size: 24),
          selectedLabelTextStyle: base.textTheme.labelMedium
              ?.copyWith(color: selected, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle:
              base.textTheme.labelMedium?.copyWith(color: inactive),
        ),
      ),
      child: child,
    );
  }
}
