import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:flutter/material.dart';

/// Collection of empty/failure states for Home.
class HomeEmptyStates {
  HomeEmptyStates._();

  static Widget missingUserProfile(BuildContext context, {VoidCallback? onAction}) {
    return _baseScaffold(
      context,
      icon: Icons.person_off_outlined,
      title: 'Your fitness profile is incomplete.',
      subtitle: 'Complete your profile to generate your adaptive workout.',
      actionLabel: onAction != null ? 'Complete profile' : null,
      onAction: onAction,
    );
  }

  static Widget missingCapabilityProfile(BuildContext context, {VoidCallback? onAction}) {
    return _baseScaffold(
      context,
      icon: Icons.accessibility_new_outlined,
      title: 'Your movement assessment is incomplete.',
      subtitle: 'Complete the movement check to tailor workouts to your current ability.',
      actionLabel: onAction != null ? 'Start assessment' : null,
      onAction: onAction,
    );
  }

  static Widget noWorkoutAvailable(BuildContext context, {required UserFitnessProfile userProfile}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No complete workout available',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your current environment, equipment, or workout preferences leave too few compatible exercises for a complete session.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Try adjusting your equipment or preferences in your profile.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _baseScaffold(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: onAction,
                          child: Text(actionLabel),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
