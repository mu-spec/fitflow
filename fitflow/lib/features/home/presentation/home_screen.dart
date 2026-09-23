import 'package:fitflow/core/widgets/placeholder_card.dart';
import 'package:flutter/material.dart';

/// Home tab: adaptive workout entry point (placeholder content only).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your adaptive workout starts here',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 24),
            const PlaceholderCard(
              icon: Icons.today,
              title: "Today's Workout",
              subtitle: 'Your workout for today appears here.',
            ),
            const PlaceholderCard(
              icon: Icons.bolt,
              title: 'Quick Start',
              subtitle: 'Jump into a short session in one tap.',
            ),
            const PlaceholderCard(
              icon: Icons.show_chart,
              title: 'Your Progress',
              subtitle: 'A quick look at how your training is going.',
            ),
          ],
        ),
      ),
    );
  }
}
