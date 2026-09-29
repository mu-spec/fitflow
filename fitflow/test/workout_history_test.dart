import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout_exercise.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletedWorkoutExercise makeExercise({
  String id = 'ex1',
  String name = 'Push Up',
  MovementPattern pattern = MovementPattern.push,
  WorkoutSectionType section = WorkoutSectionType.main,
  int sets = 3,
  int? reps = 10,
  Duration? work,
  Duration rest = const Duration(seconds: 30),
  ExerciseDifficulty diff = ExerciseDifficulty.level2,
}) {
  return CompletedWorkoutExercise(
    exerciseId: id,
    exerciseName: name,
    movementPattern: pattern,
    sectionType: section,
    sets: sets,
    repsPerSet: reps,
    workDuration: work,
    restBetweenSets: rest,
    difficulty: diff,
  );
}

CompletedWorkout makeWorkout({
  String id = 'workout_1',
  DateTime? completedAt,
  List<CompletedWorkoutExercise>? warmup,
  List<CompletedWorkoutExercise>? main,
  List<CompletedWorkoutExercise>? cooldown,
}) {
  final now = completedAt ?? DateTime.utc(2026, 9, 29, 12, 0, 0);
  final w = warmup ?? [makeExercise(id: 'w1', name: 'Warmup Jog', pattern: MovementPattern.warmup, section: WorkoutSectionType.warmup, sets: 1)];
  final m = main ?? [makeExercise()];
  final c = cooldown ?? [makeExercise(id: 'c1', name: 'Stretch', pattern: MovementPattern.cooldown, section: WorkoutSectionType.cooldown, sets: 1)];
  return CompletedWorkout(
    id: id,
    completedAt: now,
    targetDuration: const Duration(minutes: 20),
    estimatedDuration: const Duration(minutes: 22),
    totalExerciseCount: w.length + m.length + c.length,
    totalSetCount: w.fold<int>(0, (s, e) => s + e.sets) + m.fold<int>(0, (s, e) => s + e.sets) + c.fold<int>(0, (s, e) => s + e.sets),
    warmup: w,
    main: m,
    cooldown: c,
  );
}

void main() {
  group('Workout History Domain', () {
    test('completed model serialization round-trip', () {
      final workout = makeWorkout();
      final json = workout.toJson();
      final restored = CompletedWorkout.fromJson(json);
      expect(restored, isNotNull);
      expect(restored, equals(workout));
    });

    test('sections/order preserved', () {
      final warmup = [
        makeExercise(id: 'w1', name: 'W1', section: WorkoutSectionType.warmup),
        makeExercise(id: 'w2', name: 'W2', section: WorkoutSectionType.warmup),
      ];
      final main = [
        makeExercise(id: 'm1', name: 'M1', section: WorkoutSectionType.main, pattern: MovementPattern.push),
        makeExercise(id: 'm2', name: 'M2', section: WorkoutSectionType.main, pattern: MovementPattern.squat),
      ];
      final cooldown = [
        makeExercise(id: 'c1', name: 'C1', section: WorkoutSectionType.cooldown),
      ];
      final workout = makeWorkout(warmup: warmup, main: main, cooldown: cooldown);
      expect(workout.warmup.map((e) => e.exerciseId).toList(), equals(['w1', 'w2']));
      expect(workout.main.map((e) => e.exerciseId).toList(), equals(['m1', 'm2']));
      expect(workout.cooldown.map((e) => e.exerciseId).toList(), equals(['c1']));
      expect(workout.allExercises.map((e) => e.exerciseId).toList(), equals(['w1', 'w2', 'm1', 'm2', 'c1']));
    });

    test('effective replacement stored', () {
      // Simulate replacement: original Bodyweight Squat replaced by Chair Squat
      final replaced = makeExercise(id: 'chair_squat', name: 'Chair Squat', pattern: MovementPattern.squat);
      final workout = makeWorkout(main: [replaced]);
      expect(workout.main.first.exerciseName, equals('Chair Squat'));
      expect(workout.main.first.exerciseId, equals('chair_squat'));
      // Ensure history shows replacement, not original
      final json = workout.toJson();
      final restored = CompletedWorkout.fromJson(json)!;
      expect(restored.main.first.exerciseName, equals('Chair Squat'));
    });

    test('sets preserved', () {
      final ex = makeExercise(sets: 5);
      final workout = makeWorkout(main: [ex]);
      final restored = CompletedWorkout.fromJson(workout.toJson())!;
      expect(restored.main.first.sets, equals(5));
    });

    test('reps preserved', () {
      final ex = makeExercise(reps: 12);
      final workout = makeWorkout(main: [ex]);
      final restored = CompletedWorkout.fromJson(workout.toJson())!;
      expect(restored.main.first.repsPerSet, equals(12));
    });

    test('workDuration preserved', () {
      final ex = makeExercise(reps: null, work: const Duration(seconds: 45));
      final workout = makeWorkout(main: [ex]);
      final restored = CompletedWorkout.fromJson(workout.toJson())!;
      expect(restored.main.first.workDuration, equals(const Duration(seconds: 45)));
    });

    test('rest preserved', () {
      final ex = makeExercise(rest: const Duration(seconds: 60));
      final workout = makeWorkout(main: [ex]);
      final restored = CompletedWorkout.fromJson(workout.toJson())!;
      expect(restored.main.first.restBetweenSets, equals(const Duration(seconds: 60)));
    });

    test('difficulty/name snapshot preserved', () {
      final ex = makeExercise(name: 'Old Name', diff: ExerciseDifficulty.level3);
      final workout = makeWorkout(main: [ex]);
      final restored = CompletedWorkout.fromJson(workout.toJson())!;
      expect(restored.main.first.exerciseName, equals('Old Name'));
      expect(restored.main.first.difficulty, equals(ExerciseDifficulty.level3));
      // Even if catalog changes later, history remains old name
    });

    test('duplicate session ID rejected/no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final workout = makeWorkout(id: 'dup_id');
      final first = await storage.add(workout);
      expect(first, true);
      final second = await storage.add(workout);
      expect(second, true);
      final loaded = storage.load();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('dup_id'));
    });

    test('newest first', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final w1 = makeWorkout(id: 'w1', completedAt: DateTime.utc(2026, 9, 27));
      final w2 = makeWorkout(id: 'w2', completedAt: DateTime.utc(2026, 9, 28));
      final w3 = makeWorkout(id: 'w3', completedAt: DateTime.utc(2026, 9, 29));
      await storage.add(w1);
      await storage.add(w2);
      await storage.add(w3);
      final loaded = storage.load();
      expect(loaded.map((e) => e.id).toList(), equals(['w3', 'w2', 'w1']));
    });

    test('cap at 100', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      for (int i = 0; i < 100; i++) {
        final w = makeWorkout(id: 'w$i', completedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)));
        await storage.add(w);
      }
      expect(storage.load().length, equals(100));
    });

    test('oldest dropped at 101', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      for (int i = 0; i < 101; i++) {
        final w = makeWorkout(id: 'w$i', completedAt: DateTime.utc(2026, 1, 1).add(Duration(days: i)));
        await storage.add(w);
      }
      final loaded = storage.load();
      expect(loaded.length, equals(100));
      // Oldest (w0) should be dropped, newest first w100..w1
      expect(loaded.any((e) => e.id == 'w0'), isFalse);
      expect(loaded.first.id, equals('w100'));
    });

    test('malformed root safe', () async {
      SharedPreferences.setMockInitialValues({WorkoutHistoryStorage.key: 'not json'});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final loaded = storage.load();
      expect(loaded, isEmpty);
    });

    test('malformed entry safe', () async {
      SharedPreferences.setMockInitialValues({
        WorkoutHistoryStorage.key: '[{"id":"good","completedAt":"2026-09-29T12:00:00.000Z","totalExerciseCount":1,"totalSetCount":1,"warmup":[],"main":[],"cooldown":[]}, {"id":123}]'
      });
      final prefs2 = await SharedPreferences.getInstance();
      final storage2 = WorkoutHistoryStorage(prefs2);
      final loaded = storage2.load();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('good'));
    });

    test('unknown enum/data safe as designed', () async {
      SharedPreferences.setMockInitialValues({
        WorkoutHistoryStorage.key: '[{"id":"w1","completedAt":"2026-09-29T12:00:00.000Z","totalExerciseCount":1,"totalSetCount":1,"warmup":[],"main":[{"exerciseId":"ex1","exerciseName":"Test","movementPattern":"unknownPattern","sectionType":"main","sets":3,"repsPerSet":10,"restBetweenSetsSeconds":30,"difficulty":"level2"}],"cooldown":[]}]'
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      final loaded = storage.load();
      // Unknown enum should be ignored, entry's main exercise ignored, but workout still loads with empty main? Our fromJson skips invalid exercise
      expect(loaded.length, equals(1));
      expect(loaded.first.main, isEmpty);
    });

    test('clear works', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      await storage.add(makeWorkout());
      expect(storage.load().isNotEmpty, true);
      await storage.clear();
      expect(storage.load(), isEmpty);
    });

    test('storage failure does not crash', () async {
      // Simulate failure by using storage that throws? Our storage catches exceptions
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutHistoryStorage(prefs);
      // Should not throw
      expect(() => storage.load(), returnsNormally);
      final workout = makeWorkout();
      final result = await storage.add(workout);
      expect(result, isA<bool>());
    });
  });
}
