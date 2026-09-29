import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_context.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_engine.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_eligibility_result.dart';
import 'package:fitflow/features/workouts/domain/eligibility/exercise_exclusion_reason.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression_order.dart';
import 'package:fitflow/features/workouts/domain/exercise_skill_tree.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Pure, deterministic projection of catalog progression metadata and the
/// user's current movement/setup profiles. This resolver performs no I/O,
/// persistence, provider access, clock reads, or input mutation.
abstract final class ExerciseSkillTreeResolver {
  static const List<ExerciseExclusionReason> _setupReasonOrder = [
    ExerciseExclusionReason.missingEquipment,
    ExerciseExclusionReason.insufficientSpace,
    ExerciseExclusionReason.tooNoisy,
    ExerciseExclusionReason.lowImpactRequired,
    ExerciseExclusionReason.floorRestricted,
    ExerciseExclusionReason.standingOnlyRequired,
    ExerciseExclusionReason.wristLoadRestricted,
    ExerciseExclusionReason.kneeLoadRestricted,
    ExerciseExclusionReason.jumpingRestricted,
    ExerciseExclusionReason.inactiveExercise,
    ExerciseExclusionReason.missingMovementPattern,
  ];

  static ExerciseSkillTreeCatalog resolve({
    required Iterable<Exercise> exercises,
    required UserFitnessProfile? userProfile,
    required CapabilityProfile? capabilityProfile,
  }) {
    final catalog = List<Exercise>.unmodifiable(exercises);
    final byId = <String, List<Exercise>>{};
    for (final exercise in catalog) {
      byId.putIfAbsent(exercise.id, () => <Exercise>[]).add(exercise);
    }

    final diagnosticSet = <ExerciseSkillTreeDiagnostic>{};
    void addDiagnostic({
      required ExerciseSkillTreeDiagnosticCode code,
      String? familyId,
      String? exerciseId,
      String? relatedExerciseId,
      String? detail,
    }) {
      diagnosticSet.add(
        ExerciseSkillTreeDiagnostic(
          code: code,
          familyId: familyId,
          exerciseId: exerciseId,
          relatedExerciseId: relatedExerciseId,
          detail: detail,
        ),
      );
    }

    final duplicateIds = <String>{};
    final familiesWithDuplicateIds = <String>{};
    final sortedIds = byId.keys.toList()..sort();
    for (final id in sortedIds) {
      final matches = byId[id]!;
      if (matches.length < 2) continue;
      duplicateIds.add(id);
      addDiagnostic(
        code: ExerciseSkillTreeDiagnosticCode.duplicateExerciseId,
        exerciseId: id,
        detail: '${matches.length} catalog entries',
      );
      for (final exercise in matches) {
        final familyId = _familyId(exercise);
        if (exercise.active && familyId != null) {
          familiesWithDuplicateIds.add(familyId);
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.duplicateExerciseId,
            familyId: familyId,
            exerciseId: id,
            detail: '${matches.length} catalog entries',
          );
        }
      }
    }

    final familyMembers = <String, List<Exercise>>{};
    for (final exercise in catalog) {
      if (!exercise.active) continue;
      final rawFamilyId = exercise.progressionFamilyId;
      if (rawFamilyId == null) continue;
      final familyId = rawFamilyId.trim();
      if (familyId.isEmpty) {
        addDiagnostic(
          code: ExerciseSkillTreeDiagnosticCode.emptyFamilyId,
          exerciseId: exercise.id,
        );
        continue;
      }
      familyMembers.putIfAbsent(familyId, () => <Exercise>[]).add(exercise);
    }

    final effectiveCapabilities = _validCapabilityProfile(capabilityProfile);
    final eligibilityContext = userProfile == null
        ? null
        : ExerciseEligibilityContext.fromProfiles(
            userProfile: userProfile,
            capabilityProfile: effectiveCapabilities,
          );

    final familyIds = familyMembers.keys.toList()..sort();
    final trees = <ExerciseSkillTree>[];

    for (final familyId in familyIds) {
      final members = List<Exercise>.of(familyMembers[familyId]!)
        ..sort(_compareExerciseIdThenRank);
      final validMembers = <Exercise>[];

      for (final exercise in members) {
        final validationProblems = exercise.validate();
        if (validationProblems.isNotEmpty) {
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.invalidExercise,
            familyId: familyId,
            exerciseId: exercise.id,
            detail: validationProblems.join('; '),
          );
        }
        if (exercise.progressionRank <= 0) {
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.nonPositiveProgressionRank,
            familyId: familyId,
            exerciseId: exercise.id,
            detail: 'rank ${exercise.progressionRank}',
          );
        }

        final pattern = exercise.movementPattern;
        if (pattern == null) {
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.missingMovementPattern,
            familyId: familyId,
            exerciseId: exercise.id,
          );
        } else if (!CapabilityProfile.trainablePatterns.contains(pattern)) {
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.nonTrainableMovementPattern,
            familyId: familyId,
            exerciseId: exercise.id,
            detail: pattern.label,
          );
        }

        if (duplicateIds.contains(exercise.id) ||
            validationProblems.isNotEmpty ||
            exercise.progressionRank <= 0 ||
            pattern == null ||
            !CapabilityProfile.trainablePatterns.contains(pattern)) {
          continue;
        }
        validMembers.add(exercise);
      }

      final rankGroups = <int, List<Exercise>>{};
      for (final exercise in validMembers) {
        rankGroups
            .putIfAbsent(exercise.progressionRank, () => <Exercise>[])
            .add(exercise);
      }
      final ranks = rankGroups.keys.toList()..sort();
      var hasDuplicateRanks = false;
      for (final rank in ranks) {
        final tied = rankGroups[rank]!;
        if (tied.length < 2) continue;
        hasDuplicateRanks = true;
        tied.sort((a, b) => a.id.compareTo(b.id));
        for (final exercise in tied) {
          addDiagnostic(
            code: ExerciseSkillTreeDiagnosticCode.duplicateProgressionRank,
            familyId: familyId,
            exerciseId: exercise.id,
            detail: 'rank $rank',
          );
        }
      }

      final patterns = validMembers
          .map((exercise) => exercise.movementPattern!)
          .toSet()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final hasMixedPatterns = patterns.length > 1;
      if (hasMixedPatterns) {
        addDiagnostic(
          code: ExerciseSkillTreeDiagnosticCode.mixedMovementPatterns,
          familyId: familyId,
          detail: patterns.map((pattern) => pattern.name).join(', '),
        );
      }

      final orderedMembers = ExerciseProgressionOrder.sort(validMembers);
      final validIds = orderedMembers.map((exercise) => exercise.id).toSet();
      for (final exercise in orderedMembers) {
        _validateVariationLink(
          exercise: exercise,
          familyId: familyId,
          isEasier: true,
          referenceId: exercise.easierVariationId,
          catalogById: byId,
          validFamilyIds: validIds,
          addDiagnostic: addDiagnostic,
        );
        _validateVariationLink(
          exercise: exercise,
          familyId: familyId,
          isEasier: false,
          referenceId: exercise.harderVariationId,
          catalogById: byId,
          validFamilyIds: validIds,
          addDiagnostic: addDiagnostic,
        );
      }

      // Neighbor links are checked only when ranks uniquely define the family
      // order. Equal ranks remain viewable, with the shared ID tie-breaker,
      // but cannot prove a unique easier/harder neighbor relationship.
      if (!hasDuplicateRanks && orderedMembers.length >= 2) {
        for (var index = 0; index < orderedMembers.length; index++) {
          final exercise = orderedMembers[index];
          if (index > 0) {
            final expectedEasierId = orderedMembers[index - 1].id;
            if (exercise.easierVariationId != expectedEasierId) {
              addDiagnostic(
                code: ExerciseSkillTreeDiagnosticCode
                    .inconsistentEasierNeighborLink,
                familyId: familyId,
                exerciseId: exercise.id,
                relatedExerciseId: expectedEasierId,
              );
            }
          }
          if (index < orderedMembers.length - 1) {
            final expectedHarderId = orderedMembers[index + 1].id;
            if (exercise.harderVariationId != expectedHarderId) {
              addDiagnostic(
                code: ExerciseSkillTreeDiagnosticCode
                    .inconsistentHarderNeighborLink,
                familyId: familyId,
                exerciseId: exercise.id,
                relatedExerciseId: expectedHarderId,
              );
            }
          }
        }
      }

      if (orderedMembers.length < 2) {
        addDiagnostic(
          code: ExerciseSkillTreeDiagnosticCode.insufficientValidExercises,
          familyId: familyId,
          detail: '${orderedMembers.length} valid active exercises',
        );
        continue;
      }
      if (familiesWithDuplicateIds.contains(familyId) || hasMixedPatterns) {
        // Duplicate IDs make node identity/navigation ambiguous. Conflicting
        // movement patterns make one family-level capability unsafe to claim.
        continue;
      }

      final movementPattern = orderedMembers.first.movementPattern!;
      final currentCapability = effectiveCapabilities.capabilityFor(
        movementPattern,
      );
      final treeDiagnostics = _sortedDiagnostics(
        diagnosticSet.where((diagnostic) => diagnostic.familyId == familyId),
      );
      final nodes = <ExerciseSkillTreeNode>[];
      for (var index = 0; index < orderedMembers.length; index++) {
        final exercise = orderedMembers[index];
        final capability = currentCapability != null &&
                currentCapability.movementPattern == movementPattern &&
                currentCapability.isValid
            ? currentCapability
            : null;
        final fitsCurrentLevel = capability == null
            ? null
            : CapabilityLevel.fromExerciseDifficulty(exercise.difficulty)
                    .rank <=
                capability.level.rank;
        final eligibilityResult = eligibilityContext == null
            ? null
            : ExerciseEligibilityEngine.evaluate(exercise, eligibilityContext);
        final setupReasons = _setupExclusions(eligibilityResult);
        final setupLabels = _setupLabels(setupReasons);
        final setupStatus = eligibilityResult == null
            ? ExerciseSkillTreeSetupStatus.setupDetailsUnavailable
            : setupReasons.isEmpty
                ? ExerciseSkillTreeSetupStatus.fitsSetup
                : ExerciseSkillTreeSetupStatus.needsSetupChange;

        nodes.add(
          ExerciseSkillTreeNode(
            exercise: exercise,
            progressionRank: exercise.progressionRank,
            position: index + 1,
            fitsCurrentLevel: fitsCurrentLevel,
            canonicalEligibilityResult: eligibilityResult,
            setupStatus: setupStatus,
            setupExclusionReasons: setupReasons,
            setupIssueLabels: setupLabels,
          ),
        );
      }

      trees.add(
        ExerciseSkillTree(
          familyId: familyId,
          movementPattern: movementPattern,
          nodes: nodes,
          currentMovementLevel: currentCapability?.level,
          diagnostics: treeDiagnostics,
        ),
      );
    }

    trees.sort(_compareTrees);
    return ExerciseSkillTreeCatalog(
      trees: trees,
      diagnostics: _sortedDiagnostics(diagnosticSet),
    );
  }

  static String? _familyId(Exercise exercise) {
    final familyId = exercise.progressionFamilyId?.trim();
    if (familyId == null || familyId.isEmpty) return null;
    return familyId;
  }

  static int _compareExerciseIdThenRank(Exercise a, Exercise b) {
    final byId = a.id.compareTo(b.id);
    return byId != 0 ? byId : a.progressionRank.compareTo(b.progressionRank);
  }

  static CapabilityProfile _validCapabilityProfile(
    CapabilityProfile? profile,
  ) {
    final valid = <MovementPattern, MovementCapability>{};
    if (profile != null) {
      for (final pattern in CapabilityProfile.trainablePatterns) {
        final capability = profile.capabilityFor(pattern);
        if (capability != null &&
            capability.movementPattern == pattern &&
            capability.isValid) {
          valid[pattern] = capability;
        }
      }
    }
    return CapabilityProfile.fromMap(valid);
  }

  static void _validateVariationLink({
    required Exercise exercise,
    required String familyId,
    required bool isEasier,
    required String? referenceId,
    required Map<String, List<Exercise>> catalogById,
    required Set<String> validFamilyIds,
    required void Function({
      required ExerciseSkillTreeDiagnosticCode code,
      String? familyId,
      String? exerciseId,
      String? relatedExerciseId,
      String? detail,
    }) addDiagnostic,
  }) {
    if (referenceId == null) return;

    final selfReference = referenceId == exercise.id;
    if (selfReference) {
      addDiagnostic(
        code: isEasier
            ? ExerciseSkillTreeDiagnosticCode.selfReferenceEasierVariation
            : ExerciseSkillTreeDiagnosticCode.selfReferenceHarderVariation,
        familyId: familyId,
        exerciseId: exercise.id,
        relatedExerciseId: referenceId,
      );
      return;
    }

    final matches = catalogById[referenceId];
    if (matches == null || matches.isEmpty) {
      addDiagnostic(
        code: isEasier
            ? ExerciseSkillTreeDiagnosticCode.missingEasierVariationTarget
            : ExerciseSkillTreeDiagnosticCode.missingHarderVariationTarget,
        familyId: familyId,
        exerciseId: exercise.id,
        relatedExerciseId: referenceId,
      );
      return;
    }
    if (matches.length != 1) {
      addDiagnostic(
        code: isEasier
            ? ExerciseSkillTreeDiagnosticCode.unavailableEasierVariationTarget
            : ExerciseSkillTreeDiagnosticCode.unavailableHarderVariationTarget,
        familyId: familyId,
        exerciseId: exercise.id,
        relatedExerciseId: referenceId,
        detail: 'target ID is ambiguous',
      );
      return;
    }

    final target = matches.single;
    if (_familyId(target) != familyId) {
      addDiagnostic(
        code: isEasier
            ? ExerciseSkillTreeDiagnosticCode.easierVariationFromAnotherFamily
            : ExerciseSkillTreeDiagnosticCode.harderVariationFromAnotherFamily,
        familyId: familyId,
        exerciseId: exercise.id,
        relatedExerciseId: referenceId,
      );
      return;
    }
    if (!target.active ||
        !target.isValid ||
        target.progressionRank <= 0 ||
        target.movementPattern == null ||
        !CapabilityProfile.trainablePatterns.contains(target.movementPattern) ||
        !validFamilyIds.contains(target.id)) {
      addDiagnostic(
        code: isEasier
            ? ExerciseSkillTreeDiagnosticCode.unavailableEasierVariationTarget
            : ExerciseSkillTreeDiagnosticCode.unavailableHarderVariationTarget,
        familyId: familyId,
        exerciseId: exercise.id,
        relatedExerciseId: referenceId,
      );
    }
  }

  static Set<ExerciseExclusionReason> _setupExclusions(
    ExerciseEligibilityResult? result,
  ) {
    if (result == null) return const <ExerciseExclusionReason>{};
    return Set<ExerciseExclusionReason>.unmodifiable(
      result.reasons.where(
        (reason) =>
            reason != ExerciseExclusionReason.aboveCapability &&
            reason != ExerciseExclusionReason.missingCapability,
      ),
    );
  }

  static List<String> _setupLabels(Set<ExerciseExclusionReason> reasons) {
    final labels = <String>[];
    for (final reason in _setupReasonOrder) {
      if (!reasons.contains(reason)) continue;
      final label = _labelForReason(reason);
      if (label != null) labels.add(label);
    }
    return List<String>.unmodifiable(labels);
  }

  static String? _labelForReason(ExerciseExclusionReason reason) {
    switch (reason) {
      case ExerciseExclusionReason.inactiveExercise:
        return 'Exercise is not currently available';
      case ExerciseExclusionReason.missingCapability:
      case ExerciseExclusionReason.aboveCapability:
        return null;
      case ExerciseExclusionReason.missingEquipment:
        return 'Needs different equipment';
      case ExerciseExclusionReason.insufficientSpace:
        return 'Needs more space';
      case ExerciseExclusionReason.tooNoisy:
        return "Doesn't fit your current noise setting";
      case ExerciseExclusionReason.lowImpactRequired:
        return 'Conflicts with low-impact preference';
      case ExerciseExclusionReason.floorRestricted:
        return 'Conflicts with your floor preference';
      case ExerciseExclusionReason.standingOnlyRequired:
        return 'Conflicts with standing-only preference';
      case ExerciseExclusionReason.wristLoadRestricted:
        return 'Conflicts with wrist preference';
      case ExerciseExclusionReason.kneeLoadRestricted:
        return 'Conflicts with knee preference';
      case ExerciseExclusionReason.jumpingRestricted:
        return 'Conflicts with no-jumping preference';
      case ExerciseExclusionReason.missingMovementPattern:
        return 'Movement information is unavailable';
    }
  }

  static int _compareTrees(ExerciseSkillTree a, ExerciseSkillTree b) {
    final aMovementOrder =
        CapabilityProfile.trainablePatterns.indexOf(a.movementPattern);
    final bMovementOrder =
        CapabilityProfile.trainablePatterns.indexOf(b.movementPattern);
    final byMovement = aMovementOrder.compareTo(bMovementOrder);
    if (byMovement != 0) return byMovement;

    final byName = a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
    return byName != 0 ? byName : a.familyId.compareTo(b.familyId);
  }

  static List<ExerciseSkillTreeDiagnostic> _sortedDiagnostics(
    Iterable<ExerciseSkillTreeDiagnostic> diagnostics,
  ) {
    final sorted = diagnostics.toList()
      ..sort((a, b) {
        final byFamily = (a.familyId ?? '').compareTo(b.familyId ?? '');
        if (byFamily != 0) return byFamily;
        final byCode = a.code.name.compareTo(b.code.name);
        if (byCode != 0) return byCode;
        final byExercise = (a.exerciseId ?? '').compareTo(b.exerciseId ?? '');
        if (byExercise != 0) return byExercise;
        final byRelated = (a.relatedExerciseId ?? '').compareTo(
          b.relatedExerciseId ?? '',
        );
        if (byRelated != 0) return byRelated;
        return (a.detail ?? '').compareTo(b.detail ?? '');
      });
    return List<ExerciseSkillTreeDiagnostic>.unmodifiable(sorted);
  }
}
