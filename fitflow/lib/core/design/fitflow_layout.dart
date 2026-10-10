import 'package:flutter/material.dart';

/// Width classes from the available constraints, never from a device model.
enum FitFlowWindowSize { compact, medium, expanded }

class FitFlowLayout {
  const FitFlowLayout._();

  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 840;

  /// Readable column for later screens. Not applied globally yet.
  static const double maxContentWidth = 760;
  static const double maxReadableWidth = 640;

  static FitFlowWindowSize of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  static FitFlowWindowSize fromWidth(double width) {
    if (width >= expandedBreakpoint) return FitFlowWindowSize.expanded;
    if (width >= compactBreakpoint) return FitFlowWindowSize.medium;
    return FitFlowWindowSize.compact;
  }

  static bool isExpanded(BuildContext context) =>
      of(context) == FitFlowWindowSize.expanded;
}

/// Centers content and stops it stretching on large windows.
class FitFlowMaxWidth extends StatelessWidget {
  const FitFlowMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = FitFlowLayout.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
