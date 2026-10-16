import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
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
    final visual = FitFlowVisualV2.of(context);
    final summary = _summaryTraits();

    return FitFlowV2InfoSurface(
      padding: const EdgeInsets.all(FitFlowSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Exercise Characteristics',
              style: theme.textTheme.titleMedium?.copyWith(
                color: visual.onTint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: FitFlowSpace.sm),
            // Constraint summary chips
            Wrap(
              spacing: FitFlowSpace.xs,
              runSpacing: FitFlowSpace.xs,
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
                  avatar: ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: 18,
                      color: FitFlowTheme.of(context).brand,
                    ),
                  ),
                  label: Text(trait),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: visual.tint,
                  side: BorderSide(color: visual.subtleBorder),
                );
              }).toList(),
            ),
            const SizedBox(height: FitFlowSpace.xs),
            // Concise summary line like "Quiet • Low impact • Small space"
            Text(
              summary.join(' • '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: FitFlowTheme.of(context).textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: FitFlowSpace.md),
          // Detailed rows, improved scanning
          _CharRow(
            label: 'Position',
            value: exercise.bodyPosition?.label ?? '—',
            icon: Icons.accessibility_new,
            highlight: isStanding,
          ),
          Divider(height: 20, color: visual.subtleBorder),
          _CharRow(
            label: 'Impact',
            value: exercise.impactLevel.label,
            icon: Icons.bolt_outlined,
            highlight: isLowImpact,
          ),
          Divider(height: 20, color: visual.subtleBorder),
          _CharRow(
            label: 'Noise',
            value: exercise.noiseLevel.label,
            icon: Icons.volume_up_outlined,
            highlight: isQuiet,
          ),
          Divider(height: 20, color: visual.subtleBorder),
          _CharRow(
            label: 'Space',
            value: exercise.spaceRequirement.label,
            icon: Icons.square_foot_outlined,
            highlight: isSmallSpace,
          ),
          Divider(height: 20, color: visual.subtleBorder),
          _CharRow(
            label: 'Wrist load',
            value: exercise.wristLoad.label,
            icon: Icons.front_hand_outlined,
          ),
          Divider(height: 20, color: visual.subtleBorder),
          _CharRow(
            label: 'Knee load',
            value: exercise.kneeLoad.label,
            icon: Icons.airline_seat_legroom_extra_outlined,
          ),
        ],
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
    final visual = FitFlowVisualV2.of(context);

    Widget valueLabel(TextAlign textAlign) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FitFlowSpace.xs,
            vertical: FitFlowSpace.xxs,
          ),
          decoration: BoxDecoration(
            color: highlight ? visual.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            textAlign: textAlign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight
                  ? FitFlowTheme.of(context).brand
                  : FitFlowTheme.of(context).textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    Widget leadingIcon() => Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight ? visual.tint : visual.support,
            borderRadius: BorderRadius.circular(6),
          ),
          child: ExcludeSemantics(
            child: Icon(
              icon,
              size: 18,
              color: highlight
                  ? FitFlowTheme.of(context).brand
                  : FitFlowTheme.of(context).textSecondary,
            ),
          ),
        );

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360 || textScale >= 1.4;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leadingIcon(),
                  const SizedBox(width: FitFlowSpace.xs),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: FitFlowTheme.of(context).textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  top: FitFlowSpace.xxs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: valueLabel(TextAlign.start),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            leadingIcon(),
            const SizedBox(width: FitFlowSpace.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: FitFlowTheme.of(context).textSecondary,
                ),
              ),
            ),
            const SizedBox(width: FitFlowSpace.xs),
            Flexible(child: valueLabel(TextAlign.end)),
          ],
        );
      },
    );
  }
}
