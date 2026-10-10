import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/core/design/widgets/fitflow_surfaces.dart';
import 'package:flutter/material.dart';

/// A list-style row used as a placeholder item on feature screens.
class PlaceholderRow extends StatelessWidget {
  const PlaceholderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FitFlowListRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
    );
  }
}
