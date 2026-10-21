import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.homeBrand,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: FitFlowTheme.of(context).textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .8)),
          const SizedBox(height: FitFlowSpace.xs),
          Semantics(
              header: true,
              child: Text(context.l10n.homeTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500))),
        ],
      );
}
