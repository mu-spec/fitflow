import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Compact setup values, wrapping vertically at enlarged text sizes.
class HomeDetailRow extends StatelessWidget {
  const HomeDetailRow({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: LayoutBuilder(builder: (context, constraints) {
        final labelWidget = Text(label,
            style: text.bodySmall
                ?.copyWith(color: FitFlowTheme.of(context).textSecondary));
        final valueWidget = Text(value, style: text.bodyMedium);
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 22) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: FitFlowSpace.xxs),
                valueWidget,
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 104, child: labelWidget),
          const SizedBox(width: FitFlowSpace.sm),
          Expanded(child: valueWidget),
        ]);
      }),
    );
  }
}
