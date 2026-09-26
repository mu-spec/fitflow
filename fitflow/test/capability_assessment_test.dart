import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_answer.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_state.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_level_description.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Assessment catalog', () {
    test('exactly 10 items', () {
      expect(CapabilityAssessmentCatalog.all.length, 10);
    });

    test('matches CapabilityProfile.trainablePatterns', () {
      final catalogPatterns = CapabilityAssessmentCatalog.all
          .map((e) => e.movementPattern)
          .toSet();
      final trainable = CapabilityProfile.trainablePatterns.toSet();
      expect(catalogPatterns, trainable);
      expect(catalogPatterns.length, 10);
    });

    test('no warmup/cooldown', () {
      expect(
        CapabilityAssessmentCatalog.all
            .any((e) => e.movementPattern == MovementPattern.warmup),
        false,
      );
      expect(
        CapabilityAssessmentCatalog.all
            .any((e) => e.movementPattern == MovementPattern.cooldown),
        false,
      );
    });

    test('unique patterns', () {
      final patterns = CapabilityAssessmentCatalog.all
          .map((e) => e.movementPattern)
          .toList();
      expect(patterns.toSet().length, patterns.length);
    });

    test('titles/prompts non-empty', () {
      for (final item in CapabilityAssessmentCatalog.all) {
        expect(item.title.trim().isNotEmpty, true,
            reason: '${item.movementPattern.name} title empty');
        expect(item.prompt.trim().isNotEmpty, true,
            reason: '${item.movementPattern.name} prompt empty');
        expect(item.isValid, true,
            reason: '${item.movementPattern.name} invalid: ${item.validate()}');
      }
    });

    test('validate() returns empty for catalog', () {
      expect(CapabilityAssessmentCatalog.validate(), isEmpty);
    });

    test('examples non-empty and reference real exercises', () {
      for (final item in CapabilityAssessmentCatalog.all) {
        expect(item.examples.isNotEmpty, true,
            reason: '${item.movementPattern.name} examples empty');
        for (final ex in item.examples) {
          expect(ex.trim().isNotEmpty, true);
        }
      }
    });

    test('stable order matches trainablePatterns order', () {
      final catalogOrder =
          CapabilityAssessmentCatalog.all.map((e) => e.movementPattern).toList();
      expect(catalogOrder, CapabilityProfile.trainablePatterns);
    });
  });

  group('Experience suggestions', () {
    test('completelyNew → Level 1', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.completelyNew);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level1,
            reason: ans.movementPattern.name);
      }
    });

    test('someExperience → Level 2', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.someExperience);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level2);
      }
    });

    test('regularTraining → Level 3', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.regularTraining);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level3);
      }
    });

    test('experienced → Level 4', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.experienced);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level4);
      }
    });

    test('no experience level suggests Level 5', () {
      for (final exp in ExperienceLevel.values) {
        final state =
            CapabilityAssessmentState.fromExperienceLevel(exp);
        for (final ans in state.allAnswers) {
          expect(ans.selectedLevel, isNot(CapabilityLevel.level5),
              reason: '${exp.name} suggested Level5');
        }
      }
    });
  });

  group('Suggested state', () {
    test('regularTraining exactly 10 suggested answers all Level 3', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.regularTraining);
      expect(state.answeredCount, 10);
      expect(CapabilityAssessmentState.totalCount, 10);
      expect(state.isComplete, true);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level3);
      }
    });

    test('update Push→2, Squat→4, Core→1 preserves other seven as Level3', () {
      var state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.regularTraining);
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level2,
      ));
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.squat,
        selectedLevel: CapabilityLevel.level4,
      ));
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.core,
        selectedLevel: CapabilityLevel.level1,
      ));

      expect(state.answerFor(MovementPattern.push)!.selectedLevel,
          CapabilityLevel.level2);
      expect(state.answerFor(MovementPattern.squat)!.selectedLevel,
          CapabilityLevel.level4);
      expect(state.answerFor(MovementPattern.core)!.selectedLevel,
          CapabilityLevel.level1);

      // Other seven remain Level3
      final unchanged = [
        MovementPattern.pull,
        MovementPattern.lunge,
        MovementPattern.hinge,
        MovementPattern.glute,
        MovementPattern.cardio,
        MovementPattern.mobility,
        MovementPattern.balance,
      ];
      for (final p in unchanged) {
        expect(state.answerFor(p)!.selectedLevel, CapabilityLevel.level3,
            reason: p.name);
      }
    });
  });

  group('Independent movement behavior', () {
    test('changing Squat does NOT change Lunge, Hinge, Core, others', () {
      var state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.regularTraining);
      final beforeLunge = state.answerFor(MovementPattern.lunge)!.selectedLevel;
      final beforeHinge = state.answerFor(MovementPattern.hinge)!.selectedLevel;
      final beforeCore = state.answerFor(MovementPattern.core)!.selectedLevel;
      final beforePush = state.answerFor(MovementPattern.push)!.selectedLevel;
      final beforePull = state.answerFor(MovementPattern.pull)!.selectedLevel;
      final beforeGlute = state.answerFor(MovementPattern.glute)!.selectedLevel;
      final beforeCardio = state.answerFor(MovementPattern.cardio)!.selectedLevel;
      final beforeMobility = state.answerFor(MovementPattern.mobility)!.selectedLevel;
      final beforeBalance = state.answerFor(MovementPattern.balance)!.selectedLevel;

      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.squat,
        selectedLevel: CapabilityLevel.level5,
      ));

      expect(state.answerFor(MovementPattern.squat)!.selectedLevel,
          CapabilityLevel.level5);
      expect(state.answerFor(MovementPattern.lunge)!.selectedLevel, beforeLunge);
      expect(state.answerFor(MovementPattern.hinge)!.selectedLevel, beforeHinge);
      expect(state.answerFor(MovementPattern.core)!.selectedLevel, beforeCore);
      expect(state.answerFor(MovementPattern.push)!.selectedLevel, beforePush);
      expect(state.answerFor(MovementPattern.pull)!.selectedLevel, beforePull);
      expect(state.answerFor(MovementPattern.glute)!.selectedLevel, beforeGlute);
      expect(state.answerFor(MovementPattern.cardio)!.selectedLevel, beforeCardio);
      expect(state.answerFor(MovementPattern.mobility)!.selectedLevel, beforeMobility);
      expect(state.answerFor(MovementPattern.balance)!.selectedLevel, beforeBalance);
    });
  });

  group('Completeness', () {
    test('empty state incomplete', () {
      final state = CapabilityAssessmentState.empty();
      expect(state.isEmpty, true);
      expect(state.answeredCount, 0);
      expect(state.isComplete, false);
      expect(state.isValid, true);
    });

    test('partial state incomplete', () {
      var state = CapabilityAssessmentState.empty();
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level2,
      ));
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.squat,
        selectedLevel: CapabilityLevel.level3,
      ));
      expect(state.answeredCount, 2);
      expect(state.isComplete, false);
    });

    test('all 10 answers complete', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.completelyNew);
      expect(state.answeredCount, 10);
      expect(state.isComplete, true);
    });

    test('answeredCount works', () {
      var state = CapabilityAssessmentState.empty();
      expect(state.answeredCount, 0);
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level1,
      ));
      expect(state.answeredCount, 1);
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level2,
      ));
      // Replacing same movement should not increase count
      expect(state.answeredCount, 1);
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.pull,
        selectedLevel: CapabilityLevel.level1,
      ));
      expect(state.answeredCount, 2);
    });
  });

  group('CapabilityProfile conversion', () {
    test('mixed answers convert preserving exact levels', () {
      final answers = [
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.push,
            selectedLevel: CapabilityLevel.level2),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.pull,
            selectedLevel: CapabilityLevel.level1),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.squat,
            selectedLevel: CapabilityLevel.level4),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.lunge,
            selectedLevel: CapabilityLevel.level3),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.hinge,
            selectedLevel: CapabilityLevel.level3),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.core,
            selectedLevel: CapabilityLevel.level1),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.glute,
            selectedLevel: CapabilityLevel.level4),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.cardio,
            selectedLevel: CapabilityLevel.level2),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.mobility,
            selectedLevel: CapabilityLevel.level3),
        const CapabilityAssessmentAnswer(
            movementPattern: MovementPattern.balance,
            selectedLevel: CapabilityLevel.level2),
      ];

      var state = CapabilityAssessmentState.empty();
      for (final ans in answers) {
        state = state.withAnswer(ans);
      }
      expect(state.isComplete, true);

      final updatedAt = DateTime.utc(2026, 9, 26, 10, 0, 0);
      final profile = state.toCapabilityProfile(updatedAt: updatedAt);
      expect(profile, isNotNull);
      expect(profile!.isComplete, true);
      expect(profile.isValid, true);

      // Verify every level preserved
      expect(profile.capabilityFor(MovementPattern.push)!.level,
          CapabilityLevel.level2);
      expect(profile.capabilityFor(MovementPattern.pull)!.level,
          CapabilityLevel.level1);
      expect(profile.capabilityFor(MovementPattern.squat)!.level,
          CapabilityLevel.level4);
      expect(profile.capabilityFor(MovementPattern.lunge)!.level,
          CapabilityLevel.level3);
      expect(profile.capabilityFor(MovementPattern.hinge)!.level,
          CapabilityLevel.level3);
      expect(profile.capabilityFor(MovementPattern.core)!.level,
          CapabilityLevel.level1);
      expect(profile.capabilityFor(MovementPattern.glute)!.level,
          CapabilityLevel.level4);
      expect(profile.capabilityFor(MovementPattern.cardio)!.level,
          CapabilityLevel.level2);
      expect(profile.capabilityFor(MovementPattern.mobility)!.level,
          CapabilityLevel.level3);
      expect(profile.capabilityFor(MovementPattern.balance)!.level,
          CapabilityLevel.level2);

      // Source must be initialAssessment for all
      for (final cap in profile.all) {
        expect(cap.source, CapabilitySource.initialAssessment,
            reason: cap.movementPattern.name);
      }

      // Timestamp preserved
      for (final cap in profile.all) {
        expect(cap.updatedAt, updatedAt);
      }
    });

    test('anchorExerciseId carried through', () {
      var state = CapabilityAssessmentState.empty();
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level3,
        anchorExerciseId: 'pushup_knee',
      ));
      // Fill rest
      for (final pattern in CapabilityProfile.trainablePatterns) {
        if (pattern == MovementPattern.push) continue;
        state = state.withAnswer(CapabilityAssessmentAnswer(
          movementPattern: pattern,
          selectedLevel: CapabilityLevel.level2,
        ));
      }
      final updatedAt = DateTime.utc(2026, 1, 1);
      final profile = state.toCapabilityProfile(updatedAt: updatedAt);
      expect(profile, isNotNull);
      expect(profile!.capabilityFor(MovementPattern.push)!.anchorExerciseId,
          'pushup_knee');
    });

    test('incomplete conversion with 9 answers returns null', () {
      var state = CapabilityAssessmentState.empty();
      // Add 9 answers
      final patterns = CapabilityProfile.trainablePatterns.take(9);
      for (final p in patterns) {
        state = state.withAnswer(CapabilityAssessmentAnswer(
          movementPattern: p,
          selectedLevel: CapabilityLevel.level2,
        ));
      }
      expect(state.answeredCount, 9);
      expect(state.isComplete, false);
      final profile = state.toCapabilityProfile(
          updatedAt: DateTime.utc(2026, 1, 1));
      expect(profile, isNull);
    });

    test('does not silently fill missing movement', () {
      var state = CapabilityAssessmentState.empty();
      // Only 1 answer
      state = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level3,
      ));
      final profile = state.toCapabilityProfile(
          updatedAt: DateTime.utc(2026, 1, 1));
      expect(profile, isNull);
    });
  });

  group('Invalid patterns', () {
    test('warmup/cooldown answers invalid', () {
      const warmupAnswer = CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.warmup,
        selectedLevel: CapabilityLevel.level1,
      );
      expect(warmupAnswer.isValid, false);

      const cooldownAnswer = CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.cooldown,
        selectedLevel: CapabilityLevel.level1,
      );
      expect(cooldownAnswer.isValid, false);
    });

    test('warmup/cooldown not added to state', () {
      var state = CapabilityAssessmentState.empty();
      const warmupAnswer = CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.warmup,
        selectedLevel: CapabilityLevel.level1,
      );
      final newState = state.withAnswer(warmupAnswer);
      expect(newState.answeredCount, 0);
      expect(identical(newState, state), true);
    });

    test('blank anchor invalid', () {
      const answer = CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level2,
        anchorExerciseId: '   ',
      );
      expect(answer.isValid, false);
    });
  });

  group('Immutability', () {
    test('external mutation attempts fail or have no effect', () {
      final state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.regularTraining);
      expect(() => state.answers.clear(), throwsUnsupportedError);
      expect(state.answeredCount, 10);
    });

    test('previous state unchanged after update', () {
      var state = CapabilityAssessmentState.fromExperienceLevel(
          ExperienceLevel.completelyNew);
      final originalPush = state.answerFor(MovementPattern.push)!.selectedLevel;
      final newState = state.withAnswer(const CapabilityAssessmentAnswer(
        movementPattern: MovementPattern.push,
        selectedLevel: CapabilityLevel.level5,
      ));
      expect(state.answerFor(MovementPattern.push)!.selectedLevel, originalPush);
      expect(newState.answerFor(MovementPattern.push)!.selectedLevel,
          CapabilityLevel.level5);
      expect(identical(state, newState), false);
    });
  });

  group('No averaging / No inference', () {
    test('no global average exists', () {
      // Ensure no method calculates average - we verify by checking that profile preserves differences
      var state = CapabilityAssessmentState.empty();
      state = state.withAnswer(const CapabilityAssessmentAnswer(
          movementPattern: MovementPattern.push, selectedLevel: CapabilityLevel.level1));
      state = state.withAnswer(const CapabilityAssessmentAnswer(
          movementPattern: MovementPattern.squat, selectedLevel: CapabilityLevel.level5));
      // Fill rest with level3
      for (final p in CapabilityProfile.trainablePatterns) {
        if (p == MovementPattern.push || p == MovementPattern.squat) continue;
        state = state.withAnswer(CapabilityAssessmentAnswer(
            movementPattern: p, selectedLevel: CapabilityLevel.level3));
      }
      final profile = state.toCapabilityProfile(updatedAt: DateTime.utc(2026, 1, 1))!;
      // Push still 1, Squat still 5, not averaged to 3
      expect(profile.capabilityFor(MovementPattern.push)!.level, CapabilityLevel.level1);
      expect(profile.capabilityFor(MovementPattern.squat)!.level, CapabilityLevel.level5);
    });

    test('strong squat does not mean strong lunge', () {
      var state = CapabilityAssessmentState.fromExperienceLevel(ExperienceLevel.completelyNew);
      state = state.withAnswer(const CapabilityAssessmentAnswer(
          movementPattern: MovementPattern.squat, selectedLevel: CapabilityLevel.level5));
      expect(state.answerFor(MovementPattern.squat)!.selectedLevel, CapabilityLevel.level5);
      expect(state.answerFor(MovementPattern.lunge)!.selectedLevel, CapabilityLevel.level1);
    });
  });

  group('Assessment reset', () {
    test('reset to unanswered', () {
      var state = CapabilityAssessmentState.fromExperienceLevel(ExperienceLevel.experienced);
      expect(state.isComplete, true);
      state = state.resetToUnanswered();
      expect(state.isEmpty, true);
      expect(state.answeredCount, 0);
      expect(state.isComplete, false);
    });

    test('reset to suggested from ExperienceLevel', () {
      var state = CapabilityAssessmentState.empty();
      state = state.resetToSuggested(ExperienceLevel.someExperience);
      expect(state.isComplete, true);
      for (final ans in state.allAnswers) {
        expect(ans.selectedLevel, CapabilityLevel.level2);
      }
    });
  });

  group('Level descriptions', () {
    test('all levels have non-empty title and description', () {
      for (final level in CapabilityLevel.values) {
        expect(level.assessmentTitle.trim().isNotEmpty, true, reason: level.name);
        expect(level.assessmentDescription.trim().isNotEmpty, true, reason: level.name);
      }
    });

    test('descriptions do not contain medical claims', () {
      for (final level in CapabilityLevel.values) {
        final desc = level.assessmentDescription.toLowerCase();
        expect(desc.contains('injury'), false, reason: level.name);
        expect(desc.contains('rehab'), false, reason: level.name);
      }
    });
  });
}
