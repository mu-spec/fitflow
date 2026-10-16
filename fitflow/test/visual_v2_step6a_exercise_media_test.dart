import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_exercise_media.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _exercise({
  required String id,
  required String name,
  MovementPattern? movementPattern,
  ExercisePosition? bodyPosition,
  Set<WorkoutEquipment> requiredEquipment = const {WorkoutEquipment.none},
}) {
  return Exercise(
    id: id,
    name: name,
    movementPattern: movementPattern,
    difficulty: ExerciseDifficulty.level1,
    bodyPosition: bodyPosition,
    impactLevel: ImpactLevel.low,
    noiseLevel: NoiseLevel.quiet,
    spaceRequirement: SpaceRequirement.small,
    wristLoad: JointLoad.low,
    kneeLoad: JointLoad.low,
    requiredEquipment: requiredEquipment,
    exerciseType: ExerciseType.reps,
    defaultReps: 8,
  );
}

FitFlowV2ExerciseVisualDescriptor _descriptor({
  MovementPattern? movementPattern,
  ExercisePosition? bodyPosition,
  Iterable<WorkoutEquipment>? requiredEquipment,
}) {
  return FitFlowV2ExerciseVisualDescriptor.fromCanonicalMetadata(
    movementPattern: movementPattern,
    bodyPosition: bodyPosition,
    requiredEquipment: requiredEquipment,
  );
}

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  final fitFlowTheme =
      brightness == Brightness.dark ? FitFlowTheme.dark : FitFlowTheme.light;
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Theme(
      data: ThemeData(
        brightness: brightness,
        extensions: <ThemeExtension<dynamic>>[fitFlowTheme],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    ),
  );
}

CustomPainter _painter(WidgetTester tester) {
  return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!;
}

void main() {
  group('FitFlow V2 exercise visual descriptor', () {
    test('all 88 canonical catalog exercises resolve from metadata', () {
      final exercises = ExerciseCatalog.all;
      expect(exercises, hasLength(88));

      for (final exercise in exercises) {
        final descriptor = FitFlowV2ExerciseVisualDescriptor.fromExercise(
          exercise,
        );
        final expectedEquipment = exercise.requiredEquipment
            .where((item) => item != WorkoutEquipment.none)
            .toList()
          ..sort((left, right) => left.index.compareTo(right.index));

        expect(
          descriptor.movementPattern,
          exercise.movementPattern,
          reason: exercise.id,
        );
        expect(
          descriptor.bodyPosition,
          exercise.bodyPosition,
          reason: exercise.id,
        );
        expect(
          descriptor.equipmentHints,
          expectedEquipment,
          reason: exercise.id,
        );
      }
    });

    test('is repeatable and independent of display-name text', () {
      final exercise = _exercise(
        id: 'first-id',
        name: 'Words with no movement meaning',
        movementPattern: MovementPattern.push,
        bodyPosition: ExercisePosition.floor,
        requiredEquipment: const {WorkoutEquipment.bench},
      );
      final renamedExercise = _exercise(
        id: 'different-id',
        name: 'A totally unrelated localized display label',
        movementPattern: MovementPattern.push,
        bodyPosition: ExercisePosition.floor,
        requiredEquipment: const {WorkoutEquipment.bench},
      );

      final first = FitFlowV2ExerciseVisualDescriptor.fromExercise(exercise);
      for (var attempt = 0; attempt < 20; attempt++) {
        expect(FitFlowV2ExerciseVisualDescriptor.fromExercise(exercise), first);
      }
      expect(
        FitFlowV2ExerciseVisualDescriptor.fromExercise(renamedExercise),
        first,
      );
      expect(
        FitFlowV2ExerciseVisualDescriptor.fromExercise(renamedExercise)
            .hashCode,
        first.hashCode,
      );
    });

    test('movement patterns map to distinct visual cues', () {
      final push = _descriptor(movementPattern: MovementPattern.push);
      final pull = _descriptor(movementPattern: MovementPattern.pull);
      final squat = _descriptor(movementPattern: MovementPattern.squat);

      expect(push.movementPattern, MovementPattern.push);
      expect(pull.movementPattern, MovementPattern.pull);
      expect(squat.movementPattern, MovementPattern.squat);
      expect(push, isNot(equals(pull)));
      expect(pull, isNot(equals(squat)));
    });

    test('canonical positions map to distinct posture descriptors', () {
      final standing = _descriptor(bodyPosition: ExercisePosition.standing);
      final floor = _descriptor(bodyPosition: ExercisePosition.floor);
      final hanging = _descriptor(bodyPosition: ExercisePosition.hanging);

      expect(standing.bodyPosition, ExercisePosition.standing);
      expect(floor.bodyPosition, ExercisePosition.floor);
      expect(hanging.bodyPosition, ExercisePosition.hanging);
      expect(standing, isNot(equals(floor)));
      expect(floor, isNot(equals(hanging)));
    });

    test('equipment hints are normalized and deterministic', () {
      final first = _descriptor(
        requiredEquipment: const [
          WorkoutEquipment.bench,
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.none,
        ],
      );
      final reordered = _descriptor(
        requiredEquipment: const {
          WorkoutEquipment.none,
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.bench,
        },
      );

      expect(first.equipmentHints, [
        WorkoutEquipment.dumbbells,
        WorkoutEquipment.bench,
      ]);
      expect(reordered, first);
      expect(
        _descriptor(requiredEquipment: const [WorkoutEquipment.none])
            .equipmentHints,
        isEmpty,
      );
      expect(_descriptor().equipmentHints, isEmpty);
    });

    test('missing canonical metadata has a safe neutral fallback', () {
      final fallback = _descriptor();
      expect(fallback.movementPattern, isNull);
      expect(fallback.bodyPosition, isNull);
      expect(fallback.equipmentHints, isEmpty);
    });
  });

  group('FitFlowV2ExerciseMedia widget', () {
    testWidgets('movement, position, and equipment changes repaint', (
      tester,
    ) async {
      final pushStanding = _descriptor(
        movementPattern: MovementPattern.push,
        bodyPosition: ExercisePosition.standing,
      );
      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: pushStanding,
            width: 180,
            height: 132,
          ),
        ),
      );
      final pushPainter = _painter(tester);

      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: _descriptor(
              movementPattern: MovementPattern.pull,
              bodyPosition: ExercisePosition.standing,
            ),
            width: 180,
            height: 132,
          ),
        ),
      );
      final pullPainter = _painter(tester);
      expect(pullPainter.shouldRepaint(pushPainter), isTrue);

      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: _descriptor(
              movementPattern: MovementPattern.pull,
              bodyPosition: ExercisePosition.hanging,
            ),
            width: 180,
            height: 132,
          ),
        ),
      );
      final hangingPainter = _painter(tester);
      expect(hangingPainter.shouldRepaint(pullPainter), isTrue);

      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: _descriptor(
              movementPattern: MovementPattern.pull,
              bodyPosition: ExercisePosition.hanging,
              requiredEquipment: const {WorkoutEquipment.pullUpBar},
            ),
            width: 180,
            height: 132,
          ),
        ),
      );
      expect(_painter(tester).shouldRepaint(hangingPainter), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders safely in Light and Dark themes', (tester) async {
      final descriptor = FitFlowV2ExerciseVisualDescriptor.fromExercise(
        ExerciseCatalog.all.first,
      );
      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: descriptor,
          ),
          brightness: Brightness.light,
        ),
      );
      final lightPainter = _painter(tester);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: descriptor,
          ),
          brightness: Brightness.dark,
        ),
      );
      final darkPainter = _painter(tester);
      expect(darkPainter.shouldRepaint(lightPainter), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports compact thumbnails and larger hero constraints', (
      tester,
    ) async {
      final descriptor = _descriptor(
        movementPattern: MovementPattern.push,
        bodyPosition: ExercisePosition.standing,
      );
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FitFlowV2ExerciseMedia(
                key: const ValueKey('compact-media'),
                descriptor: descriptor,
                width: 52,
                height: 52,
              ),
              const SizedBox(height: 12),
              FitFlowV2ExerciseMedia(
                key: const ValueKey('hero-media'),
                descriptor: descriptor,
                width: 320,
                height: 220,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('compact-media'))),
        const Size(52, 52),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('hero-media'))),
        const Size(320, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown metadata renders a neutral safe fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            descriptor: _descriptor(),
            width: 64,
            height: 64,
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('art is decorative, static, and contains no network image', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia(
            key: const ValueKey('exercise-media'),
            descriptor: _descriptor(
              movementPattern: MovementPattern.squat,
              bodyPosition: ExercisePosition.seated,
              requiredEquipment: const {WorkoutEquipment.chair},
            ),
            width: 96,
            height: 72,
          ),
        ),
      );

      final media = find.byKey(const ValueKey('exercise-media'));
      expect(
        find.descendant(of: media, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: media, matching: find.byType(RepaintBoundary)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: media, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: media,
          matching: find.byWidgetPredicate(
            (widget) => widget is AnimatedWidget,
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: media, matching: find.byType(TickerMode)),
        findsNothing,
      );
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not throw in a 2x text-scaling environment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FitFlowV2ExerciseMedia.forExercise(
            exercise: ExerciseCatalog.all.first,
            width: 52,
            height: 52,
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
