import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_result.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Truthful movement-level fit for one exercise node.
///
/// These values describe difficulty compatibility only. They do not represent
/// exercise-specific completion, mastery, or an unlock state.
enum ExerciseSkillTreeNodeStatus {
  fitsCurrentLevel,
  aboveCurrentLevel,
  movementLevelUnavailable,
}

/// Setup compatibility is independent from movement-level fit.
enum ExerciseSkillTreeSetupStatus {
  fitsSetup,
  needsSetupChange,
  setupDetailsUnavailable,
}

/// Integrity issues found while reading catalog progression metadata.
enum ExerciseSkillTreeDiagnosticCode {
  emptyFamilyId,
  duplicateExerciseId,
  invalidExercise,
  nonPositiveProgressionRank,
  missingMovementPattern,
  nonTrainableMovementPattern,
  duplicateProgressionRank,
  mixedMovementPatterns,
  insufficientValidExercises,
  missingEasierVariationTarget,
  missingHarderVariationTarget,
  unavailableEasierVariationTarget,
  unavailableHarderVariationTarget,
  easierVariationFromAnotherFamily,
  harderVariationFromAnotherFamily,
  selfReferenceEasierVariation,
  selfReferenceHarderVariation,
  inconsistentEasierNeighborLink,
  inconsistentHarderNeighborLink,
}

/// One deterministic, non-fatal issue in existing progression metadata.
@immutable
class ExerciseSkillTreeDiagnostic {
  const ExerciseSkillTreeDiagnostic({
    required this.code,
    this.familyId,
    this.exerciseId,
    this.relatedExerciseId,
    this.detail,
  });

  final ExerciseSkillTreeDiagnosticCode code;
  final String? familyId;
  final String? exerciseId;
  final String? relatedExerciseId;
  final String? detail;

  /// Human-readable diagnostic copy. It is intended for diagnostics, not as a
  /// substitute for the canonical exercise eligibility explanation.
  String get message {
    switch (code) {
      case ExerciseSkillTreeDiagnosticCode.emptyFamilyId:
        return 'A progression family ID is empty.';
      case ExerciseSkillTreeDiagnosticCode.duplicateExerciseId:
        return 'Exercise ID is duplicated${detail == null ? '' : ': $detail'}.';
      case ExerciseSkillTreeDiagnosticCode.invalidExercise:
        return 'Exercise data is invalid${detail == null ? '' : ': $detail'}.';
      case ExerciseSkillTreeDiagnosticCode.nonPositiveProgressionRank:
        return 'Progression rank must be greater than zero.';
      case ExerciseSkillTreeDiagnosticCode.missingMovementPattern:
        return 'A trainable movement pattern is missing.';
      case ExerciseSkillTreeDiagnosticCode.nonTrainableMovementPattern:
        return 'The movement pattern is not trainable.';
      case ExerciseSkillTreeDiagnosticCode.duplicateProgressionRank:
        return 'Progression rank is shared by multiple exercises${detail == null ? '' : ': $detail'}.';
      case ExerciseSkillTreeDiagnosticCode.mixedMovementPatterns:
        return 'This family contains conflicting movement patterns${detail == null ? '' : ': $detail'}.';
      case ExerciseSkillTreeDiagnosticCode.insufficientValidExercises:
        return 'At least two valid active exercises are required to show a tree.';
      case ExerciseSkillTreeDiagnosticCode.missingEasierVariationTarget:
        return 'The easier-variation target could not be found.';
      case ExerciseSkillTreeDiagnosticCode.missingHarderVariationTarget:
        return 'The harder-variation target could not be found.';
      case ExerciseSkillTreeDiagnosticCode.unavailableEasierVariationTarget:
        return 'The easier-variation target is not an available tree node.';
      case ExerciseSkillTreeDiagnosticCode.unavailableHarderVariationTarget:
        return 'The harder-variation target is not an available tree node.';
      case ExerciseSkillTreeDiagnosticCode.easierVariationFromAnotherFamily:
        return 'The easier-variation target belongs to another family.';
      case ExerciseSkillTreeDiagnosticCode.harderVariationFromAnotherFamily:
        return 'The harder-variation target belongs to another family.';
      case ExerciseSkillTreeDiagnosticCode.selfReferenceEasierVariation:
        return 'The easier-variation link refers to the same exercise.';
      case ExerciseSkillTreeDiagnosticCode.selfReferenceHarderVariation:
        return 'The harder-variation link refers to the same exercise.';
      case ExerciseSkillTreeDiagnosticCode.inconsistentEasierNeighborLink:
        return 'The easier-variation link does not match the adjacent family step.';
      case ExerciseSkillTreeDiagnosticCode.inconsistentHarderNeighborLink:
        return 'The harder-variation link does not match the adjacent family step.';
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExerciseSkillTreeDiagnostic &&
            code == other.code &&
            familyId == other.familyId &&
            exerciseId == other.exerciseId &&
            relatedExerciseId == other.relatedExerciseId &&
            detail == other.detail;
  }

  @override
  int get hashCode => Object.hash(
        code,
        familyId,
        exerciseId,
        relatedExerciseId,
        detail,
      );
}

/// Immutable node derived from one valid catalog exercise.
@immutable
class ExerciseSkillTreeNode {
  ExerciseSkillTreeNode({
    required this.exercise,
    required this.progressionRank,
    required this.position,
    required this.fitsCurrentLevel,
    required this.canonicalEligibilityResult,
    required this.setupStatus,
    Set<ExerciseExclusionReason>? setupExclusionReasons,
    List<String>? setupIssueLabels,
  })  : setupExclusionReasons = Set.unmodifiable(
          setupExclusionReasons ?? const <ExerciseExclusionReason>{},
        ),
        setupIssueLabels = List.unmodifiable(setupIssueLabels ?? const []);

  final Exercise exercise;

  /// Catalog ladder rank; it is separate from [difficulty] and capability.
  final int progressionRank;

  /// One-based visible position after deterministic family sorting.
  final int position;

  /// `null` means the movement capability is unavailable, not that the
  /// exercise fits by default.
  final bool? fitsCurrentLevel;

  /// The canonical eligibility result, when setup profile data is available.
  final ExerciseEligibilityResult? canonicalEligibilityResult;

  final ExerciseSkillTreeSetupStatus setupStatus;

  /// Canonical non-capability exclusions used to determine setup fit.
  final Set<ExerciseExclusionReason> setupExclusionReasons;

  /// Concise factual copy for setup exclusions; internal enum names are not
  /// intended for presentation.
  final List<String> setupIssueLabels;

  ExerciseDifficulty get difficulty => exercise.difficulty;

  int get positionInFamily => position;

  ExerciseSkillTreeNodeStatus get status {
    final fit = fitsCurrentLevel;
    if (fit == null) {
      return ExerciseSkillTreeNodeStatus.movementLevelUnavailable;
    }
    return fit
        ? ExerciseSkillTreeNodeStatus.fitsCurrentLevel
        : ExerciseSkillTreeNodeStatus.aboveCurrentLevel;
  }

  bool get aboveCurrentLevel => fitsCurrentLevel == false;

  bool? get fitsSetup {
    switch (setupStatus) {
      case ExerciseSkillTreeSetupStatus.fitsSetup:
        return true;
      case ExerciseSkillTreeSetupStatus.needsSetupChange:
        return false;
      case ExerciseSkillTreeSetupStatus.setupDetailsUnavailable:
        return null;
    }
  }
}

/// One valid, dynamically discovered exercise progression family.
@immutable
class ExerciseSkillTree {
  ExerciseSkillTree({
    required this.familyId,
    required this.movementPattern,
    required List<ExerciseSkillTreeNode> nodes,
    required this.currentMovementLevel,
    List<ExerciseSkillTreeDiagnostic>? diagnostics,
  })  : nodes = List.unmodifiable(nodes),
        diagnostics = List.unmodifiable(diagnostics ?? const []);

  final String familyId;
  final MovementPattern movementPattern;
  final List<ExerciseSkillTreeNode> nodes;
  final CapabilityLevel? currentMovementLevel;
  final List<ExerciseSkillTreeDiagnostic> diagnostics;

  String get displayName => formatExerciseSkillTreeFamilyName(familyId);

  String get movementName => movementPattern.label;

  int get nodeCount => nodes.length;

  ExerciseSkillTreeNode get easiest => nodes.first;

  ExerciseSkillTreeNode get hardest => nodes.last;

  int get fitsCurrentLevelCount =>
      nodes.where((node) => node.fitsCurrentLevel == true).length;

  int get aboveCurrentLevelCount =>
      nodes.where((node) => node.fitsCurrentLevel == false).length;
}

/// Immutable result of dynamic progression-family discovery.
@immutable
class ExerciseSkillTreeCatalog {
  ExerciseSkillTreeCatalog({
    required List<ExerciseSkillTree> trees,
    List<ExerciseSkillTreeDiagnostic>? diagnostics,
  })  : trees = List.unmodifiable(trees),
        diagnostics = List.unmodifiable(diagnostics ?? const []);

  final List<ExerciseSkillTree> trees;
  final List<ExerciseSkillTreeDiagnostic> diagnostics;

  /// Alias useful to callers thinking of trees as families.
  List<ExerciseSkillTree> get families => trees;

  ExerciseSkillTree? treeForFamilyId(String? familyId) {
    if (familyId == null) return null;
    for (final tree in trees) {
      if (tree.familyId == familyId) return tree;
    }
    return null;
  }
}

/// Generic title-case fallback for catalog family IDs. No family-name catalog
/// is maintained here; any future family ID receives a readable label.
String formatExerciseSkillTreeFamilyName(String familyId) {
  final spaced = familyId
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim();

  if (spaced.toLowerCase() == 'pushup') {
    return 'Push-Up';
  }

  final words =
      spaced.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).map((word) {
    final lower = word.toLowerCase();
    return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
  });
  return words.join(' ');
}
