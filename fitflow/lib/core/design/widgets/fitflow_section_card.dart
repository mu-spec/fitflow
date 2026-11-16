import 'package:flutter/material.dart';

/// Shared content surface for profile, settings and report sections.
class FitFlowSectionCard extends StatelessWidget {
  const FitFlowSectionCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.margin = const EdgeInsets.only(bottom: 16)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      );
}
