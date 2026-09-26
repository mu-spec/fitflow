import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter/material.dart';

/// Improved characteristics presentation with constraint summary.
///
/// Keeps factual metadata, adds quick-scan chips for Quiet, Low Impact, Standing, Small Space.
class ExerciseCharacteristicsSection extends StatelessWidget {
  const ExerciseCharacteristicsSection({super.key, required this.exercise});

  final Exercise exercise;

  bool get isQuiet => exercise.noiseLevel == NoiseLevel.quiet;
  bool get isLowImpact => exercise.impactLevel == ImpactLevel.low;
  bool get isStanding => exercise.bodyPosition == ExercisePosition.standing;
  bool get isSmallSpace =>
      exercise.spaceRequirement == SpaceRequirement.tiny ||
      exercise.spaceRequirement == SpaceRequirement.small;

  List<String> _summaryTraits() {
    final traits = <String>[];
    if (isQuiet) traits.add('Quiet');
    if (isLowImpact) traits.add('Low impact');
    if (isStanding) traits.add('Standing');
    if (isSmallSpace) traits.add('Small space');
    return traits;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = _summaryTraits();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Characteristics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Constraint summary chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.map((trait) {
                  IconData icon;
                  switch (trait) {
                    case 'Quiet':
                      icon = Icons.volume_down_outlined;
                      break;
                    case 'Low impact':
                      icon = Icons.self_improvement_outlined;
                      break;
                    case 'Standing':
                      icon = Icons.accessibility_new;
                      break;
                    case 'Small space':
                      icon = Icons.square_foot_outlined;
                      break;
                    default:
                      icon = Icons.check_circle_outline;
                  }
                  return Chip(
                    avatar: Icon(icon, size: 18),
                    label: Text(trait),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: colorScheme.secondaryContainer,
                    side: BorderSide(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Concise summary line like "Quiet • Low impact • Small space"
              Text(
                summary.join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Detailed rows, improved scanning
            _CharRow(
              label: 'Position',
              value: exercise.bodyPosition?.label ?? '—',
              icon: Icons.accessibility_new,
              highlight: isStanding,
            ),
            const Divider(height: 20),
            _CharRow(
              label: 'Impact',
              value: exercise.impactLevel.label,
              icon: Icons.bolt_outlined,
              highlight: isLowImpact,
            ),
            const Divider(height: 20),
            _CharRow(
              label: 'Noise',
              value: exercise.noiseLevel.label,
              icon: Icons.volume_up_outlined,
              highlight: isQuiet,
            ),
            const Divider(height: 20),
            _CharRow(
              label: 'Space',
              value: exercise.spaceRequirement.label,
              icon: Icons.square_foot_outlined,
              highlight: isSmallSpace,
            ),
            const Divider(height: 20),
            _CharRow(
              label: 'Wrist load',
              value: exercise.wristLoad.label,
              icon: Icons.front_hand_outlined,
            ),
            const Divider(height: 20),
            _CharRow(
              label: 'Knee load',
              value: exercise.kneeLoad.label,
              icon: Icons.airline_seat_legroom_extra_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _CharRow extends StatelessWidget {
  const _CharRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: highlight ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: highlight ? colorScheme.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? colorScheme.onSecondaryContainer : null,
            ),
          ),
        ),
      ],
    );
  }
}
