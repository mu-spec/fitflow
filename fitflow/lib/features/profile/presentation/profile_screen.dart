import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/widgets/placeholder_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Profile tab: user and app entries (placeholder content only, no editing).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your profile', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            const PlaceholderRow(
              icon: Icons.person,
              title: 'Fitness Profile',
              subtitle: 'Your body and training goals.',
            ),
            const PlaceholderRow(
              icon: Icons.build,
              title: 'Equipment',
              subtitle: 'Choose the equipment you train with.',
            ),
            const PlaceholderRow(
              icon: Icons.tune,
              title: 'Workout Preferences',
              subtitle: 'Adjust how your workouts feel.',
            ),
            PlaceholderRow(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'Manage your app.',
              onTap: () => context.go(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}
