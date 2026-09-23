import 'package:flutter/material.dart';

/// Compact "x of y" label with a determinate progress bar.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          '$step of $totalSteps',
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: step / totalSteps,
          minHeight: 6,
        ),
      ],
    );
  }
}
