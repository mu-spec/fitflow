import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_surfaces.dart';
import 'package:flutter/material.dart';

/// A titled card used as a placeholder section on feature screens.
class PlaceholderSection extends StatelessWidget {
  const PlaceholderSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return FitFlowSurface(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitFlowSectionHeader(title: title),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: theme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
