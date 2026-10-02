import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_section_classifier.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Severity of a coverage diagnostic.
enum CoverageSeverity {
  /// Release-blocking gap: generation or assessment cannot work truthfully.
  releaseBlocking,

  /// Informational: structurally acceptable, reported for visibility.
  informational,
}

/// One structured coverage diagnostic.
class CoverageDiagnostic {
  const CoverageDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.pattern,
  });

  /// Stable rule identifier, e.g. `pattern.no_exercises`.
  final String code;

  /// Concise explanation.
  final String message;

  final CoverageSeverity severity;

  /// Trainable pattern involved, when applicable.
  final MovementPattern? pattern;

  bool get isReleaseBlocking => severity == CoverageSeverity.releaseBlocking;

  @override
  String toString() =>
      '[${isReleaseBlocking ? 'BLOCKER' : 'INFO'}] '
      '${pattern?.name ?? '<catalog>'} :: $code :: $message';
}

/// Coverage summary for one trainable movement pattern.
class PatternCoverageSummary {
  const PatternCoverageSummary({
    required this.pattern,
    required this.activeCount,
    required this.difficultyDistribution,
    required this.capabilityDistribution,
    required this.noEquipmentCount,
    required this.familyIds,
  });

  final MovementPattern pattern;

  /// Active exercises with this movement pattern.
  final int activeCount;

  /// Active exercise count per ExerciseDifficulty.
  final Map<ExerciseDifficulty, int> difficultyDistribution;

  /// Active exercise count per capability level, mapped through
  /// `CapabilityLevel.fromExerciseDifficulty` (never progressionRank).
  final Map<CapabilityLevel, int> capabilityDistribution;

  /// Active exercises requiring no portable equipment.
  final int noEquipmentCount;

  /// Progression families represented in this pattern.
  final Set<String> familyIds;

  int get familyCount => familyIds.length;

  bool hasLevel(CapabilityLevel level) =>
      (capabilityDistribution[level] ?? 0) > 0;
}

/// Pure developer diagnostic over the exercise catalog.
///
/// No consumer UI, no persistence. Detects only meaningful release-blocking
/// gaps; it does not impose arbitrary quotas.
abstract final class ExerciseCatalogCoverageReport {
  /// Generates a coverage report for [catalog] (defaults to the production
  /// [ExerciseCatalog]) and validates capability-assessment anchor names
  /// against it.
  static ExerciseCatalogCoverageResult generate({List<Exercise>? catalog}) {
    final exercises = List<Exercise>.unmodifiable(
      catalog ?? ExerciseCatalog.all,
    );

    final active = exercises.where((e) => e.active).toList();

    final summaries = <PatternCoverageSummary>[];
    final diagnostics = <CoverageDiagnostic>[];

    for (final pattern in CapabilityProfile.trainablePatterns) {
      final members =
          active.where((e) => e.movementPattern == pattern).toList();

      final difficultyDistribution = <ExerciseDifficulty, int>{};
      final capabilityDistribution = <CapabilityLevel, int>{};
      var noEquipmentCount = 0;
      final familyIds = <String>{};

      for (final exercise in members) {
        difficultyDistribution.update(
          exercise.difficulty,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        final level =
            CapabilityLevel.fromExerciseDifficulty(exercise.difficulty);
        capabilityDistribution.update(
          level,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (exercise.requiredEquipment.contains(WorkoutEquipment.none)) {
          noEquipmentCount++;
        }
        final familyId = exercise.progressionFamilyId;
        if (familyId != null) {
          familyIds.add(familyId);
        }
      }

      summaries.add(PatternCoverageSummary(
        pattern: pattern,
        activeCount: members.length,
        difficultyDistribution:
            Map.unmodifiable(difficultyDistribution),
        capabilityDistribution:
            Map.unmodifiable(capabilityDistribution),
        noEquipmentCount: noEquipmentCount,
        familyIds: Set.unmodifiable(familyIds),
      ));

      if (members.isEmpty) {
        diagnostics.add(CoverageDiagnostic(
          code: 'pattern.no_exercises',
          pattern: pattern,
          message:
              'trainable pattern ${pattern.name} has no active exercises',
          severity: CoverageSeverity.releaseBlocking,
        ));
      } else if (members.length == 1) {
        diagnostics.add(CoverageDiagnostic(
          code: 'pattern.single_exercise',
          pattern: pattern,
          message:
              'trainable pattern ${pattern.name} has only one active '
              'exercise; generator diversity cannot work',
          severity: CoverageSeverity.releaseBlocking,
        ));
      }

      if (!capabilityDistribution.containsKey(CapabilityLevel.level1) &&
          members.isNotEmpty) {
        diagnostics.add(CoverageDiagnostic(
          code: 'capability.no_level1_entry',
          pattern: pattern,
          message:
              'pattern ${pattern.name} has no level-1 entry; level-1 users '
              'rely on adjacent patterns (structurally acceptable, review)',
          severity: CoverageSeverity.informational,
        ));
      }
    }

    // Section viability: warmup and cooldown candidates must exist.
    // Use the same canonical classifier the generator uses so the report
    // reflects real generation pools (warmup > cooldown > main precedence).
    final warmupCount =
        active.where(CustomWorkoutSectionClassifier.isWarmup).length;
    final cooldownCount =
        active.where(CustomWorkoutSectionClassifier.isCooldown).length;
    if (warmupCount == 0) {
      diagnostics.add(const CoverageDiagnostic(
        code: 'section.no_warmup',
        message: 'no active warmup exercise exists',
        severity: CoverageSeverity.releaseBlocking,
      ));
    }
    if (cooldownCount == 0) {
      diagnostics.add(const CoverageDiagnostic(
        code: 'section.no_cooldown',
        message: 'no active cooldown exercise exists',
        severity: CoverageSeverity.releaseBlocking,
      ));
    }

    // Home viability: a no-equipment setup must have trainable candidates.
    final noEquipmentTrainable = active
        .where((e) =>
            e.requiredEquipment.contains(WorkoutEquipment.none) &&
            CapabilityProfile.trainablePatterns
                .contains(e.movementPattern))
        .length;
    if (noEquipmentTrainable == 0) {
      diagnostics.add(const CoverageDiagnostic(
        code: 'setup.no_equipment_candidates',
        message: 'normal no-equipment/home setup has no viable trainable '
            'candidates',
        severity: CoverageSeverity.releaseBlocking,
      ));
    }

    // Capability-assessment anchor names must resolve to active exercises.
    final byName = <String, Exercise>{
      for (final e in active) e.name.toLowerCase(): e,
    };
    for (final item in CapabilityAssessmentCatalog.all) {
      for (final example in item.examples) {
        final resolved = byName[example.toLowerCase()];
        if (resolved == null) {
          diagnostics.add(CoverageDiagnostic(
            code: 'anchor.unresolved',
            pattern: item.movementPattern,
            message: 'assessment example "$example" does not resolve to an '
                'active exercise',
            severity: CoverageSeverity.releaseBlocking,
          ));
        } else if (resolved.movementPattern != item.movementPattern) {
          diagnostics.add(CoverageDiagnostic(
            code: 'anchor.pattern_mismatch',
            pattern: item.movementPattern,
            message: 'assessment example "$example" resolves to '
                '${resolved.movementPattern?.name ?? '<none>'} instead of '
                '${item.movementPattern.name}',
            severity: CoverageSeverity.informational,
          ));
        }
      }
    }

    return ExerciseCatalogCoverageResult._(
      patternSummaries: List.unmodifiable(summaries),
      warmupCount: warmupCount,
      cooldownCount: cooldownCount,
      noEquipmentTrainableCount: noEquipmentTrainable,
      diagnostics: List.unmodifiable(diagnostics),
      exerciseCount: active.length,
    );
  }
}

/// Result of a coverage pass.
class ExerciseCatalogCoverageResult {
  const ExerciseCatalogCoverageResult._({
    required this.patternSummaries,
    required this.warmupCount,
    required this.cooldownCount,
    required this.noEquipmentTrainableCount,
    required this.diagnostics,
    required this.exerciseCount,
  });

  /// Summaries in canonical trainable-pattern order.
  final List<PatternCoverageSummary> patternSummaries;

  final int warmupCount;
  final int cooldownCount;
  final int noEquipmentTrainableCount;
  final int exerciseCount;

  final List<CoverageDiagnostic> diagnostics;

  List<CoverageDiagnostic> get releaseBlockingGaps => diagnostics
      .where((d) => d.severity == CoverageSeverity.releaseBlocking)
      .toList(growable: false);

  List<CoverageDiagnostic> get informational => diagnostics
      .where((d) => d.severity == CoverageSeverity.informational)
      .toList(growable: false);

  bool get hasReleaseBlockingGaps => releaseBlockingGaps.isNotEmpty;

  PatternCoverageSummary? summaryFor(MovementPattern pattern) {
    for (final summary in patternSummaries) {
      if (summary.pattern == pattern) return summary;
    }
    return null;
  }

  /// Actionable multi-line description.
  String describe() {
    final buffer = StringBuffer()
      ..writeln('Coverage report ($exerciseCount active exercises):');
    for (final summary in patternSummaries) {
      final difficulties = summary.difficultyDistribution.entries
          .map((e) => '${e.key.name}:${e.value}')
          .join(' ');
      final levels = summary.capabilityDistribution.entries
          .map((e) => 'L${e.key.rank}:${e.value}')
          .join(' ');
      buffer.writeln(
        '  ${summary.pattern.name}: active=${summary.activeCount} '
        'noEquipment=${summary.noEquipmentCount} '
        'families=${summary.familyCount} [$difficulties] [$levels]',
      );
    }
    buffer.writeln(
      '  warmup=$warmupCount cooldown=$cooldownCount '
      'noEquipmentTrainable=$noEquipmentTrainableCount',
    );
    for (final diagnostic in diagnostics) {
      buffer.writeln('  $diagnostic');
    }
    return buffer.toString();
  }
}
