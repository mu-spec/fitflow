import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveProgramCatalog', () {
    test('contains exactly five programs in deterministic order', () {
      expect(AdaptiveProgramCatalog.all.length, 5);
      expect(AdaptiveProgramCatalog.allIds, [
        'balanced_foundations',
        'strength_foundations',
        'endurance_builder',
        'mobility_movement',
        'stay_active_starter',
      ]);
      // Deterministic across reads.
      expect(AdaptiveProgramCatalog.allIds,
          AdaptiveProgramCatalog.all.map((p) => p.id).toList());
    });

    test('catalog validates', () {
      expect(AdaptiveProgramCatalog.validate(), isEmpty);
      expect(AdaptiveProgramCatalog.isValid, isTrue);
      for (final p in AdaptiveProgramCatalog.all) {
        expect(p.validate(), isEmpty, reason: p.id);
      }
    });

    test('Balanced Foundations exact structure', () {
      final p = AdaptiveProgramCatalog.byId('balanced_foundations')!;
      expect(p.name, 'Balanced Foundations');
      expect(p.weekCount, 4);
      expect(p.sessionsPerWeek, 3);
      expect(p.totalSessionCount, 12);
      expect(p.weeklyGoals, [
        FitnessGoal.generalFitness,
        FitnessGoal.buildStrength,
        FitnessGoal.improveEndurance,
      ]);
      expect(p.recommendedFor, {FitnessGoal.generalFitness});
    });

    test('Strength Foundations exact structure', () {
      final p = AdaptiveProgramCatalog.byId('strength_foundations')!;
      expect(p.name, 'Strength Foundations');
      expect(p.weekCount, 6);
      expect(p.sessionsPerWeek, 3);
      expect(p.totalSessionCount, 18);
      expect(p.weeklyGoals, [
        FitnessGoal.buildStrength,
        FitnessGoal.buildMuscle,
        FitnessGoal.buildStrength,
      ]);
      expect(p.recommendedFor,
          {FitnessGoal.buildStrength, FitnessGoal.buildMuscle});
    });

    test('Endurance Builder exact structure and no weight-loss claim', () {
      final p = AdaptiveProgramCatalog.byId('endurance_builder')!;
      expect(p.name, 'Endurance Builder');
      expect(p.weekCount, 4);
      expect(p.sessionsPerWeek, 4);
      expect(p.totalSessionCount, 16);
      expect(p.weeklyGoals, [
        FitnessGoal.improveEndurance,
        FitnessGoal.generalFitness,
        FitnessGoal.improveEndurance,
        FitnessGoal.stayActive,
      ]);
      expect(p.recommendedFor,
          {FitnessGoal.improveEndurance, FitnessGoal.loseWeight});
      final text = '${p.name} ${p.description} ${p.focus}'.toLowerCase();
      expect(text.contains('weight'), isFalse);
      expect(text.contains('fat'), isFalse);
      expect(text.contains('burn'), isFalse);
    });

    test('Mobility & Movement exact structure', () {
      final p = AdaptiveProgramCatalog.byId('mobility_movement')!;
      expect(p.name, 'Mobility & Movement');
      expect(p.weekCount, 4);
      expect(p.sessionsPerWeek, 3);
      expect(p.totalSessionCount, 12);
      expect(p.weeklyGoals, [
        FitnessGoal.improveMobility,
        FitnessGoal.generalFitness,
        FitnessGoal.improveMobility,
      ]);
      expect(p.recommendedFor, {FitnessGoal.improveMobility});
    });

    test('Stay Active Starter exact structure', () {
      final p = AdaptiveProgramCatalog.byId('stay_active_starter')!;
      expect(p.name, 'Stay Active Starter');
      expect(p.weekCount, 4);
      expect(p.sessionsPerWeek, 3);
      expect(p.totalSessionCount, 12);
      expect(p.weeklyGoals, [
        FitnessGoal.stayActive,
        FitnessGoal.generalFitness,
        FitnessGoal.stayActive,
      ]);
      expect(p.recommendedFor, {FitnessGoal.stayActive});
    });

    test('total sessions across catalog', () {
      final total = AdaptiveProgramCatalog.all
          .fold<int>(0, (sum, p) => sum + p.totalSessionCount);
      expect(total, 12 + 18 + 16 + 12 + 12);
    });

    test('session IDs are deterministic and globally unique', () {
      final all = <String>[];
      for (final p in AdaptiveProgramCatalog.all) {
        for (final w in p.weeks) {
          for (final s in w.sessions) {
            expect(s.id, '${p.id}_w${w.number}_s${s.session}');
            expect(s.programId, p.id);
            expect(s.week, w.number);
            all.add(s.id);
          }
        }
      }
      expect(all.toSet().length, all.length);
      expect(all, contains('balanced_foundations_w1_s1'));
      expect(all, contains('balanced_foundations_w1_s2'));
      expect(all, contains('balanced_foundations_w2_s1'));
      expect(all, contains('strength_foundations_w6_s3'));
      expect(all, contains('endurance_builder_w4_s4'));
    });

    test('weeks and sessions are numbered sequentially from 1', () {
      for (final p in AdaptiveProgramCatalog.all) {
        for (var i = 0; i < p.weeks.length; i++) {
          expect(p.weeks[i].number, i + 1);
          for (var j = 0; j < p.weeks[i].sessions.length; j++) {
            expect(p.weeks[i].sessions[j].session, j + 1);
          }
        }
        // flattened order is week-major
        final flat = p.weeks.expand((w) => w.sessions).toList();
        expect(p.sessions, flat);
      }
    });

    test('exposed collections are unmodifiable', () {
      expect(() => AdaptiveProgramCatalog.all.clear(), throwsUnsupportedError);
      expect(
          () => AdaptiveProgramCatalog.allIds.add('x'), throwsUnsupportedError);
      final p = AdaptiveProgramCatalog.all.first;
      expect(() => p.weeks.clear(), throwsUnsupportedError);
      expect(() => p.sessions.clear(), throwsUnsupportedError);
      expect(() => p.weeks.first.sessions.clear(), throwsUnsupportedError);
      expect(() => p.recommendedFor.add(FitnessGoal.stayActive),
          throwsUnsupportedError);
      expect(() => p.weeklyTemplate.clear(), throwsUnsupportedError);
      expect(() => p.weeklyGoals.clear(), throwsUnsupportedError);
    });

    test('definitions store no exercise IDs', () {
      // The session model has no exercise/plan fields; verify JSON-ish shape
      // via toString and that only structural data is present.
      for (final p in AdaptiveProgramCatalog.all) {
        for (final s in p.sessions) {
          expect(s.toString().contains('exercise'), isFalse);
        }
      }
    });

    test('all generation goals are valid FitnessGoal values', () {
      for (final p in AdaptiveProgramCatalog.all) {
        for (final s in p.sessions) {
          expect(FitnessGoal.values, contains(s.generationGoal));
          expect(s.focus.trim(), isNotEmpty);
        }
      }
    });

    test('lookup helpers', () {
      expect(AdaptiveProgramCatalog.byId('unknown'), isNull);
      expect(AdaptiveProgramCatalog.byId(null), isNull);
      expect(AdaptiveProgramCatalog.contains('balanced_foundations'), isTrue);
      final s = AdaptiveProgramCatalog.sessionById('mobility_movement_w2_s3');
      expect(s, isNotNull);
      expect(s!.programId, 'mobility_movement');
      expect(s.generationGoal, FitnessGoal.improveMobility);
      expect(AdaptiveProgramCatalog.sessionById('nope_w1_s1'), isNull);

      final p = AdaptiveProgramCatalog.balancedFoundations;
      expect(p.indexOfSession('balanced_foundations_w2_s1'), 3);
      expect(p.indexOfSession('strength_foundations_w1_s1'), -1);
      expect(p.containsSession('balanced_foundations_w4_s3'), isTrue);
      expect(p.sessionById('balanced_foundations_w1_s1')!.title,
          'Week 1 • Session 1');
    });

    test('build() rejects invalid structure', () {
      expect(
        () => AdaptiveProgramDefinition.build(
          id: 'x',
          name: 'x',
          description: 'x',
          focus: 'x',
          weekCount: 0,
          weeklyTemplate: const [
            AdaptiveProgramSessionTemplate(
                focus: 'a', generationGoal: FitnessGoal.generalFitness),
          ],
          recommendedFor: const {FitnessGoal.generalFitness},
        ),
        throwsArgumentError,
      );
      expect(
        () => AdaptiveProgramDefinition.build(
          id: 'x',
          name: 'x',
          description: 'x',
          focus: 'x',
          weekCount: 2,
          weeklyTemplate: const [],
          recommendedFor: const {FitnessGoal.generalFitness},
        ),
        throwsArgumentError,
      );
    });

    test('no fabricated effectiveness or outcome claims in copy', () {
      const banned = [
        'best',
        'optimal',
        'guaranteed',
        'lose weight',
        'burn fat',
        'proven',
        'medical',
        'ai ',
      ];
      for (final p in AdaptiveProgramCatalog.all) {
        final text = '${p.name} ${p.description} ${p.focus}'.toLowerCase();
        for (final b in banned) {
          expect(text.contains(b), isFalse, reason: '${p.id} contains "$b"');
        }
      }
    });
  });
}
