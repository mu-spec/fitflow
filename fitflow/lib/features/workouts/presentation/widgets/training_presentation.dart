import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Presentation-only adapters. Never persist these labels or change level math.
String trainingLevelLabel(AppLocalizations l, CapabilityLevel level) =>
    switch (level) {
      CapabilityLevel.level1 => l.assessmentChoice1,
      CapabilityLevel.level2 => l.assessmentChoice2,
      CapabilityLevel.level3 => l.assessmentChoice3,
      CapabilityLevel.level4 => l.assessmentChoice4,
      CapabilityLevel.level5 => l.assessmentChoice5,
    };
String trainingDifficultyLabel(AppLocalizations l, ExerciseDifficulty level) =>
    trainingLevelLabel(l, CapabilityLevel.fromExerciseDifficulty(level));

class TrainingHeading extends StatelessWidget {
  const TrainingHeading(this.title, {super.key, this.large = false});
  final String title;
  final bool large;
  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(title,
            style: large
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.titleLarge),
      );
}

/// Native, focusable disclosure. No hidden child build until first expansion.
/// Large type wraps; reduced motion completes the same state change immediately.
class TrainingDisclosure extends StatelessWidget {
  const TrainingDisclosure(
      {super.key, required this.title, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!),
        expansionAnimationStyle: AnimationStyle(
          duration: SystemMotion.standard(context),
          reverseDuration: SystemMotion.standard(context),
          curve: FitFlowMotion.standardCurve,
        ),
        children: children,
      );
}

/// Wrapping, non-interactive fact, not a truncating Material Chip.
class TrainingFact extends StatelessWidget {
  const TrainingFact(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(FitFlowRadius.small),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(
              child:
                  Text(label, style: Theme.of(context).textTheme.labelMedium)),
        ]),
      );
}

/// Deliberately modest visual slot. Replace here when professional catalog
/// media is available; no placeholder promise, network request or fake anatomy.
class ExerciseArtwork extends StatelessWidget {
  const ExerciseArtwork({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
          child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(FitFlowRadius.small),
        ),
        child: Icon(Icons.fitness_center_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant, size: 24),
      ));
}
