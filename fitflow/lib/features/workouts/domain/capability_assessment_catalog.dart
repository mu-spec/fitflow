import 'package:fitflow/features/workouts/domain/capability_assessment_item.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Canonical catalog of 10 assessment items, one per trainable movement.
///
/// Stable order matching CapabilityProfile.trainablePatterns.
abstract final class CapabilityAssessmentCatalog {
  static const List<CapabilityAssessmentItem> all = [
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.push,
      title: 'Pushing strength',
      prompt: 'How comfortable are you with pushing exercises such as push-ups?',
      examples: ['Wall Push-Up', 'Knee Push-Up', 'Standard Push-Up'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.pull,
      title: 'Pulling strength',
      prompt: 'How comfortable are you with pulling and upper-back exercises?',
      examples: ['Towel Row', 'Doorway Row', 'Reverse Snow Angel'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.squat,
      title: 'Squat strength',
      prompt: 'How comfortable are you with squat-based lower-body exercises?',
      examples: ['Chair Sit-to-Stand', 'Bodyweight Squat', 'Tempo Squat'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.lunge,
      title: 'Lunge strength',
      prompt: 'How comfortable are you with split-stance and lunge movements?',
      examples: ['Static Split Squat', 'Reverse Lunge', 'Bulgarian Split Squat'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.hinge,
      title: 'Hinge strength',
      prompt: 'How comfortable are you with hip-hinge movements?',
      examples: ['Hip Hinge', 'Good Morning', 'Single-Leg Hip Hinge'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.core,
      title: 'Core stability',
      prompt: 'How comfortable are you with core stability exercises?',
      examples: ['Dead Bug', 'Knee Plank', 'Forearm Plank'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.glute,
      title: 'Glute strength',
      prompt: 'How comfortable are you with glute-focused movements?',
      examples: ['Glute Bridge', 'Glute Bridge March', 'Single-Leg Glute Bridge'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.cardio,
      title: 'Cardio endurance',
      prompt: 'How comfortable are you with sustained home cardio movements?',
      examples: ['March in Place', 'Step Jack', 'High Knees'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.mobility,
      title: 'Mobility',
      prompt: 'How comfortable are you moving through controlled mobility exercises?',
      examples: ['Cat-Cow', 'Hip Flexor Stretch', 'World\'s Greatest Stretch'],
      availableLevels: CapabilityLevel.values,
    ),
    CapabilityAssessmentItem(
      movementPattern: MovementPattern.balance,
      title: 'Balance',
      prompt: 'How comfortable are you maintaining control in balance-focused movements?',
      examples: ['Single-Leg Stand', 'Standing Knee Raise', 'Single-Leg Hip Hinge'],
      availableLevels: CapabilityLevel.values,
    ),
  ];

  static void _assertValid() {
    // Runtime validation in debug, not throwing in production
    assert(all.length == 10, 'catalog must have exactly 10 items');
    assert(
      all.map((e) => e.movementPattern).toSet().length == 10,
      'catalog must have unique movement patterns',
    );
    assert(
      !all.any((e) =>
          e.movementPattern == MovementPattern.warmup ||
          e.movementPattern == MovementPattern.cooldown),
      'catalog must not contain warmup/cooldown',
    );
  }

  /// Validates catalog configuration, returns problems if any.
  static List<String> validate() {
    final problems = <String>[];
    if (all.length != 10) {
      problems.add('catalog must have exactly 10 items, found ${all.length}');
    }
    final patterns = all.map((e) => e.movementPattern).toList();
    if (patterns.toSet().length != 10) {
      problems.add('catalog must have unique movement patterns');
    }
    if (patterns.any((p) =>
        p == MovementPattern.warmup || p == MovementPattern.cooldown)) {
      problems.add('catalog must not contain warmup/cooldown');
    }
    for (final item in all) {
      problems.addAll(item.validate().map((p) => '${item.movementPattern.name}: $p'));
    }
    // Ensure validation runs in debug as well
    assert(() {
      _assertValid();
      return true;
    }());
    return problems;
  }
}
