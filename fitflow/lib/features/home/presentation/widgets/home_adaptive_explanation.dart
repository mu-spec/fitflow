import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class HomeAdaptiveExplanation extends StatelessWidget {
  const HomeAdaptiveExplanation({super.key});
  @override
  Widget build(BuildContext context) => Text(context.l10n.homeAdaptationDetail,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: FitFlowTheme.of(context).textSecondary));
}
