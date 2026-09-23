import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/core/widgets/placeholder_section.dart';
import 'package:flutter/material.dart';

/// Progress tab: training overview (placeholder content only, no stats yet).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your progress', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            const PlaceholderSection(
              title: 'Workouts Completed',
              subtitle: 'Your completed sessions show up here.',
            ),
            const PlaceholderSection(
              title: 'Training Time',
              subtitle: 'The time you spend training shows up here.',
            ),
            const PlaceholderSection(
              title: 'Movement Progress',
              subtitle: 'Improvements in the movements you train most.',
            ),
          ],
        ),
      ),
    );
  }
}
