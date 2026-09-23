import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Temporary box shown on onboarding steps that still need real content.
class OnboardingPlaceholder extends StatelessWidget {
  const OnboardingPlaceholder({
    super.key,
    this.hint = 'Real options for this step arrive in a later milestone.',
  });

  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        hint,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
