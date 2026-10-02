import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:flutter/material.dart';

/// Compact card displaying real profile facts.
class HomePersonalizationCard extends StatelessWidget {
  const HomePersonalizationCard({super.key, required this.userProfile});

  final UserFitnessProfile userProfile;

  String _equipmentDisplay() {
    final equipment = userProfile.equipment;
    if (equipment.isEmpty) {
      return 'No equipment';
    }
    // If only none or contains none and nothing else meaningful
    final meaningful = equipment.where((e) => e != WorkoutEquipment.none).toList();
    if (meaningful.isEmpty) {
      return 'No equipment';
    }
    return meaningful.map((e) => e.label).join(', ');
  }

  String _preferencesDisplay() {
    final prefs = userProfile.preferences;
    if (prefs.isEmpty) {
      return 'No special restrictions';
    }
    return prefs.map((p) => p.label).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Built for you',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRow(context, 'Goal', userProfile.goal.label),
            const SizedBox(height: 12),
            _buildRow(context, 'Duration', userProfile.workoutDuration.label),
            const SizedBox(height: 12),
            _buildRow(context, 'Environment', userProfile.environment.label),
            const SizedBox(height: 12),
            _buildRow(context, 'Equipment', _equipmentDisplay()),
            const SizedBox(height: 12),
            _buildRow(context, 'Preferences', _preferencesDisplay()),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w500,
    );
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          Text(value, style: valueStyle),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: valueStyle)),
      ],
    );
  }
}
