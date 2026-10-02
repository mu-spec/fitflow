import 'package:flutter/material.dart';

/// Keeps a two-action row at normal text scale and stacks it when text or
/// width would clip the labels. Visual order matches focus order.
class FitFlowActionPair extends StatelessWidget {
  const FitFlowActionPair({
    super.key,
    required this.leading,
    required this.trailing,
    this.expand = false,
  });

  final Widget leading;
  final Widget trailing;

  /// When true, both actions share the row equally at normal scale.
  final bool expand;

  static bool shouldStack(BuildContext context, double maxWidth) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return scale >= 1.35 || maxWidth < 360;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (shouldStack(context, constraints.maxWidth)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leading,
              const SizedBox(height: 8),
              trailing,
            ],
          );
        }
        if (expand) {
          return Row(
            children: [
              Expanded(child: leading),
              const SizedBox(width: 12),
              Expanded(child: trailing),
            ],
          );
        }
        return Row(
          children: [
            leading,
            const Spacer(),
            trailing,
          ],
        );
      },
    );
  }
}
