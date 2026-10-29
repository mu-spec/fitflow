import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fitflow/core/design/media/exercise_animation.dart';
import 'package:fitflow/core/design/media/exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

const animatedIds = <String>[
  'jumping_jacks',
  'squat_bodyweight',
  'pushup_pike',
  'lunge_forward',
  'reverse_crunch',
];

const stillIds = <String>[
  'march_in_place',
  'arm_circles',
  'cat_cow',
  'pushup_wall',
  'pushup_knee',
  'pushup_standard',
  'row_doorway',
  'reverse_snow_angel',
  'squat_partial',
  'squat_chair',
  'calf_raise',
  'lunge_reverse',
  'hip_hinge',
  'bridge_glute',
  'dead_bug',
  'plank_forearm',
  'plank_knee',
  'bird_dog',
  'step_jack',
  'cobra_stretch',
];

const hiddenIds = <String>[
  'pushup_incline',
  'pushup_decline',
  'squat_tempo',
  'wall_sit',
  'hollow_hold',
  'bridge_single_leg',
  'high_knees',
  'lunge_curtsy',
  'squat_split_bulgarian',
  'bicycle_crunch',
  'mountain_climbers',
  'good_morning',
  'hip_hinge_single_leg',
  'donkey_kick',
  'fire_hydrant',
  'pushup_close_grip',
  'pushup_wide',
  'shoulder_tap',
  'plank_up_down',
  'butt_kicks',
  'skater_step',
  'shadow_boxing',
  'single_leg_stand',
  'standing_knee_raise',
  'ankle_circles',
  'world_greatest_stretch',
  'pushup_diamond',
  'pushup_down_dog',
  'wall_shoulder_press',
  'dip_chair',
  'squat_sumo',
  'squat_pulse',
  'lunge_lateral',
  'bridge_march',
  'frog_pump',
  'plank_reach',
  'plank_side_knee',
  'russian_twist',
  'leg_raise',
  'flutter_kicks',
  'burpee_low_impact',
  'fast_feet',
  'mountain_climber_standing',
  'figure_four_stretch',
  'pull_apart_resistance_band',
  'row_resistance_band',
  'squat_goblet_dumbbell',
  'row_bent_over_dumbbell',
  'deadlift_kettlebell',
  'squat_goblet_kettlebell',
  'dead_hang_pullup_bar',
  'scapular_pullup',
];

const gifIds = <String>['squat_bodyweight', 'pushup_pike'];
const lottieIds = <String>['jumping_jacks', 'lunge_forward', 'reverse_crunch'];

WorkoutPlan plan(String id) {
  final prescription =
      WorkoutExercisePrescription.fromExerciseDefaults(
              ExerciseCatalog.byId(id)!)!;
  return WorkoutPlan(
    warmup: WorkoutSection(
        type: WorkoutSectionType.warmup, exercises: [prescription]),
    main: WorkoutSection(
        type: WorkoutSectionType.main, exercises: [prescription]),
    cooldown: WorkoutSection(
        type: WorkoutSectionType.cooldown, exercises: [prescription]),
    timeBudget:
        WorkoutTimeBudget.fromWorkoutDuration(WorkoutDuration.twentyMinutes),
  );
}

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
    theme: ThemeData.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!),
    home: Scaffold(
        body: SafeArea(child: SingleChildScrollView(child: child))));

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('registry maps exactly the 5 animated launch movements', () {
    expect(ExerciseAnimationRegistry.assets.keys,
        unorderedEquals(animatedIds));
    for (final id in animatedIds) {
      expect(ExerciseCatalog.byId(id), isNotNull, reason: id);
      expect(ExerciseCatalog.byId(id)!.active, isTrue, reason: id);
    }
    for (final id in stillIds) {
      expect(ExerciseAnimationRegistry.assetFor(id), isNull, reason: id);
      expect(ExerciseCatalog.byId(id)!.active, isTrue, reason: id);
    }
    for (final id in hiddenIds) {
      expect(ExerciseAnimationRegistry.assetFor(id), isNull, reason: id);
      expect(ExerciseCatalog.byId(id)!.active, isFalse, reason: id);
    }
  });

  for (final id in gifIds) {
    testWidgets('$id bundled GIF loops and decodes', (tester) async {
      await tester.runAsync(() async {
        final bytes = (await rootBundle
            .load(ExerciseAnimationRegistry.assetFor(id)!))
            .buffer
            .asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          expect(codec.frameCount, greaterThan(1), reason: id);
          expect(codec.repetitionCount, -1, reason: id);
          final frame = await codec.getNextFrame();
          try {
            expect(frame.image.width, 360, reason: id);
            expect(frame.image.height, 360, reason: id);
            expect(frame.duration, greaterThan(Duration.zero), reason: id);
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      });

      await tester.pumpWidget(host(const SizedBox.shrink()));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final id in lottieIds) {
    testWidgets('$id bundled Lottie loads offline', (tester) async {
      final asset = ExerciseAnimationRegistry.assetFor(id)!;
      final composition =
          await tester.runAsync(() => AssetLottie(asset).load());
      expect(composition, isNotNull);
      expect(composition!.bounds.width, greaterThan(0), reason: id);
      expect(composition.bounds.height, greaterThan(0), reason: id);
      expect(composition.duration, greaterThan(Duration.zero), reason: id);
    });

    testWidgets('$id renders in hero and thumbnail', (tester) async {
      final asset = ExerciseAnimationRegistry.assetFor(id)!;
      await tester.pumpWidget(host(Column(children: [
        FitFlowExerciseImage.hero(
            exerciseId: id, width: 240, height: 180),
        FitFlowExerciseImage.thumbnail(
            exerciseId: id, width: 56, height: 56),
      ])));
      await settle(tester);
      expect(find.byType(ExerciseAnimation), findsNWidgets(2));
      expect(find.byKey(ValueKey(asset)), findsNWidgets(2));
      expect(find.byType(Lottie), findsNWidgets(2));
    });

    testWidgets('$id honors reduced motion with a still fallback',
        (tester) async {
      await tester.pumpWidget(host(
          FitFlowExerciseImage.hero(exerciseId: id, width: 240, height: 180),
          reduced: true));
      await settle(tester);
      expect(find.byType(FitFlowMediaImage), findsOneWidget);
      expect(find.byType(Lottie), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Player pauses lunge animation without touching the clock',
      (tester) async {
    await tester.runAsync(() => AssetLottie(
            ExerciseAnimationRegistry.assetFor('lunge_forward')!)
        .load());
    final controller = WorkoutPlayerController(
        plan: plan('lunge_forward'), autoStartTimer: false);
    addTearDown(controller.dispose);

    Future<void> show() async {
      await tester.pumpWidget(host(
          WorkoutPlayerExerciseCenter(state: controller.state)));
      await settle(tester);
    }

    await show();
    expect(controller.state.phase, WorkoutPlayerPhase.ready);
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    controller.beginWorkout();
    await show();
    controller.pause();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    final paused = controller.state;
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state, same(paused));
    controller.resume();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isTrue);
    controller.completeSet();
    await show();
    expect(tester.widget<Lottie>(find.byType(Lottie)).animate, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('still exercises render labeled photos, no animation',
      (tester) async {
    for (final id in ['plank_forearm', 'march_in_place']) {
      await tester.pumpWidget(host(
          FitFlowExerciseImage.hero(exerciseId: id, width: 240, height: 180)));
      await settle(tester);
      expect(find.byType(ExerciseAnimation), findsNothing);
      expect(find.byType(Lottie), findsNothing);
      expect(find.byType(FitFlowMediaImage), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(host(
        FitFlowExerciseImage.hero(
            exerciseId: 'pushup_standard', width: 240, height: 180)));
    await settle(tester);
    expect(find.byType(Lottie), findsNothing);
    expect(find.byType(FitFlowMediaImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
