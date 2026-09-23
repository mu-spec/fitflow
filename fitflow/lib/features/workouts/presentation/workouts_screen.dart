import 'package:fitflow/core/widgets/placeholder_section.dart';
import 'package:flutter/material.dart';

/// Workouts tab: catalog of workouts (placeholder content only).
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your workouts', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            const PlaceholderSection(
              title: 'Recommended',
              subtitle: 'Workouts picked for your level and history.',
            ),
            const PlaceholderSection(
              title: 'Programs',
              subtitle: 'Structured multi-week training plans.',
            ),
            const PlaceholderSection(
              title: 'Custom Workouts',
              subtitle: 'Build and save your own workouts.',
            ),
          ],
        ),
      ),
    );
  }
}
