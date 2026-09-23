import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:flutter/material.dart';

/// A selectable card used for single-choice onboarding questions.
class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    super.key,
    required this.label,
    this.helperText,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String? helperText;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final helper = helperText;
    final radius = BorderRadius.circular(AppDimens.radiusMedium);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerLow,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurface,
                            ),
                      ),
                      if (helper != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            helper,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
