import 'dart:ui' show Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_progression.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_progression_section.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_variation_card.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void _setView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  String exerciseId = 'pushup_standard',
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  _setView(tester, size);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Theme(
          data: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          child: ExerciseDetailScreen(exerciseId: exerciseId),
        ),
      ),
    ),
  );
  await tester.runAsync(() => AssetManifest.loadFromAssetBundle(rootBundle));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all eight pilot heroes decode their own bundled photography',
      (tester) async {
    addTearDown(tester.view.reset);
    const ids = [
      'arm_circles',
      'hip_flexor_stretch',
      'lunge_reverse',
      'plank_forearm',
      'pushup_standard',
      'pushup_wall',
      'row_bent_over_dumbbell',
      'squat_bodyweight',
    ];
    for (final id in ids) {
      await _pumpDetail(tester, exerciseId: id);
      final hero = find.byKey(const ValueKey('exercise_detail_media'));
      final imageFinder =
          find.descendant(of: hero, matching: find.byType(Image));
      final image = tester.widget<Image>(imageFinder);
      final provider = image.image as ResizeImage;
      expect((provider.imageProvider as AssetImage).assetName,
          'assets/images/exercises/hero/$id.webp');
      expect(image.fit, BoxFit.contain);
      await tester
          .runAsync(() => precacheImage(provider, tester.element(imageFinder)));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: hero,
              matching:
                  find.byKey(const ValueKey('fitflow_media_placeholder'))),
          findsNothing,
          reason: id);
      expect(tester.takeException(), isNull, reason: id);
    }
  });

  testWidgets('canonical detail preserves content and uses its production hero',
      (tester) async {
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      final exercise = ExerciseCatalog.byId('pushup_standard')!;
      final l10n = englishAppLocalizations();
      await _pumpDetail(tester, exerciseId: exercise.id);

      final title = find.byKey(const ValueKey('exercise_detail_title'));
      expect(
          find.descendant(
              of: find.byType(AppBar),
              matching: find.text(l10n.trainingDetails)),
          findsOneWidget);
      expect(find.text(exercise.name), findsWidgets);
      expect(find.text(exercise.shortDescription!, skipOffstage: false),
          findsOneWidget);
      expect(tester.widget<Text>(title).maxLines, isNull);
      final titleData = tester.getSemantics(title).getSemanticsData();
      expect(titleData.label, exercise.name);
      expect(titleData.flagsCollection.isHeader, isTrue);

      final heroMediaFinder =
          find.byKey(const ValueKey('exercise_detail_media'));
      final heroMedia = tester.widget<FitFlowExerciseImage>(heroMediaFinder);
      expect(
        heroMedia.exerciseId,
        exercise.id,
      );
      expect(heroMedia.decorative, isTrue);
      expect(heroMedia.width / heroMedia.height, closeTo(4 / 3, .001));
      expect(
        find.descendant(
          of: heroMediaFinder,
          matching: find.text(exercise.name),
        ),
        findsNothing,
      );

      expect(find.text(l10n.trainingHowTo), findsOneWidget);
      expect(
        find.text(movementPatternLabel(l10n, exercise.movementPattern!)),
        findsWidgets,
      );
      expect(
        find.text(trainingDifficultyLabel(l10n, exercise.difficulty)),
        findsWidgets,
      );
      expect(find.text(exercise.exerciseType.label), findsOneWidget);
      final equipmentText = exercise.requiredEquipment.isEmpty ||
              exercise.requiredEquipment.contains(WorkoutEquipment.none)
          ? l10n.trainingNoEquipment
          : exercise.requiredEquipment
              .map((item) => equipmentLabel(l10n, item))
              .join(' · ');
      expect(find.text(equipmentText), findsOneWidget);

      final instructionTops = <double>[];
      for (final instruction in exercise.instructions) {
        final finder = find.text(instruction);
        expect(finder, findsOneWidget, reason: instruction);
        expect(tester.widget<Text>(finder).maxLines, isNull);
        instructionTops.add(tester.getTopLeft(finder).dy);
      }
      expect(instructionTops, orderedEquals(instructionTops.toList()..sort()));

      for (final muscle in {
        ...exercise.primaryMuscles,
        ...exercise.secondaryMuscles,
      }) {
        expect(find.text(muscle.label), findsWidgets, reason: muscle.label);
      }
      for (final mistake in exercise.commonMistakes) {
        expect(find.text(mistake), findsOneWidget, reason: mistake);
      }
      expect(
        find.text(exercise.breathingGuidance!),
        findsOneWidget,
      );

      final progression = ExerciseProgressionResolver.resolve(exercise)!;
      expect(
        find.text(l10n.trainingStep(progression.step, progression.total)),
        findsOneWidget,
      );
      expect(find.text(l10n.trainingProgression), findsOneWidget);

      final forbiddenMetrics = RegExp(
        r'\b(calories|kcal|fitness score|intensity score|effectiveness|injury risk|rating)\b|\b\d+(?:\.\d+)?%',
        caseSensitive: false,
      );
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final value = text.data ?? text.textSpan?.toPlainText() ?? '';
        expect(forbiddenMetrics.hasMatch(value), isFalse, reason: value);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('progression shows the same variations and canonical artwork',
      (tester) async {
    addTearDown(tester.view.reset);
    final exercise = ExerciseCatalog.byId('pushup_standard')!;
    final progression = ExerciseProgressionResolver.resolve(exercise)!;
    await _pumpDetail(tester, exerciseId: exercise.id);

    final variations = [
      progression.easier!,
      progression.current,
      progression.harder!,
    ];
    for (final variation in variations) {
      final cardFinder =
          find.byKey(ValueKey('exercise_variation_${variation.id}'));
      expect(cardFinder, findsOneWidget);
      final card = tester.widget<ExerciseVariationCard>(cardFinder);
      expect(card.exercise.id, variation.id);
      expect(
        tester.getSize(cardFinder).height,
        greaterThanOrEqualTo(48),
      );
      final mediaFinder = find.byKey(
        ValueKey('exercise_variation_media_${variation.id}'),
      );
      expect(
        tester.widget<FitFlowExerciseImage>(mediaFinder).exerciseId,
        variation.id,
      );
    }

    expect(
      tester
          .widget<ExerciseVariationCard>(
            find.byKey(ValueKey('exercise_variation_${exercise.id}')),
          )
          .isCurrent,
      isTrue,
    );
    expect(
      tester
          .widget<ExerciseVariationCard>(
            find.byKey(ValueKey('exercise_variation_${exercise.id}')),
          )
          .onTap,
      isNull,
    );
    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('Knee Push-Up'), findsOneWidget);
    expect(find.text('Decline Push-Up'), findsOneWidget);
    expect(find.text('View full skill tree'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('easier, harder and skill-tree destinations remain keyboardable',
      (tester) async {
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final exercise = ExerciseCatalog.byId('pushup_standard')!;
    final progression = ExerciseProgressionResolver.resolve(exercise)!;
    final familyId = exercise.progressionFamilyId!;
    final router = GoRouter(
      initialLocation: AppRoutes.exerciseDetail(exercise.id),
      routes: [
        GoRoute(
          path: '${AppRoutes.exerciseLibrary}/:exerciseId',
          builder: (context, state) => ExerciseDetailScreen(
            exerciseId: state.pathParameters['exerciseId']!,
          ),
        ),
        GoRoute(
          path: '${AppRoutes.skillTrees}/:familyId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text(
                  'Skill tree destination: ${state.pathParameters['familyId']}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    try {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final easierCard =
          find.byKey(ValueKey('exercise_variation_${progression.easier!.id}'));
      await tester.ensureVisible(easierCard);
      final cardInkWell =
          find.descendant(of: easierCard, matching: find.byType(InkWell));
      expect(tester.widget<InkWell>(cardInkWell).onTap, isNotNull);
      await tester.tap(find.text(progression.easier!.name));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExerciseDetailScreen>(
              find.byType(ExerciseDetailScreen).last,
            )
            .exerciseId,
        progression.easier!.id,
      );

      router.pop();
      await tester.pumpAndSettle();
      final harderCard =
          find.byKey(ValueKey('exercise_variation_${progression.harder!.id}'));
      await tester.ensureVisible(harderCard);
      await tester.tap(find.text(progression.harder!.name));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExerciseDetailScreen>(
              find.byType(ExerciseDetailScreen).last,
            )
            .exerciseId,
        progression.harder!.id,
      );

      router.pop();
      await tester.pumpAndSettle();
      final treeButton =
          find.byKey(const ValueKey('exercise_skill_tree_button'));
      await tester.ensureVisible(treeButton);
      expect(tester.getSize(treeButton).height, greaterThanOrEqualTo(48));
      final treeButtonData = tester.getSemantics(treeButton).getSemanticsData();
      expect(treeButtonData.flagsCollection.isButton, isTrue);
      expect(treeButtonData.label,
          contains(englishAppLocalizations().trainingViewTree));

      var focused = false;
      for (var attempt = 0; attempt < 32; attempt++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final data = tester.getSemantics(treeButton).getSemanticsData();
        if (data.flagsCollection.isFocused == Tristate.isTrue) {
          focused = true;
          break;
        }
      }
      expect(focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Skill tree destination: $familyId'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('prescription and characteristics disclosures retain values',
      (tester) async {
    addTearDown(tester.view.reset);
    final exercise = ExerciseCatalog.byId('pushup_standard')!;
    final l10n = englishAppLocalizations();
    await _pumpDetail(tester, exerciseId: exercise.id);

    final prescriptionTitle = find.text(l10n.trainingDefaults);
    expect(prescriptionTitle, findsOneWidget);
    expect(
      tester.getSize(find.byType(ExpansionTile).first).height,
      greaterThanOrEqualTo(48),
    );
    await tester.ensureVisible(prescriptionTitle);
    await tester.tap(prescriptionTitle);
    await tester.pumpAndSettle();

    expect(find.text(l10n.flowReps(exercise.defaultReps!)), findsOneWidget);
    expect(
      find.text(
        l10n.trainingRest(
          FitFlowLocaleFormat.formatDuration(l10n, exercise.defaultRest!),
        ),
      ),
      findsOneWidget,
    );

    final characteristicsTitle = find.text(l10n.trainingCatalogDetails);
    await tester.ensureVisible(characteristicsTitle);
    await tester.tap(characteristicsTitle);
    await tester.pumpAndSettle();
    expect(find.text('Exercise Characteristics'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text(exercise.bodyPosition!.label), findsWidgets);
    expect(find.text('Impact'), findsOneWidget);
    expect(find.text(exercise.impactLevel.label), findsWidgets);
    expect(find.text('Noise'), findsOneWidget);
    expect(find.text(exercise.noiseLevel.label), findsWidgets);
    expect(find.text('Space'), findsOneWidget);
    expect(find.text(exercise.spaceRequirement.label), findsWidgets);
    expect(find.text('Wrist load'), findsOneWidget);
    expect(find.text(exercise.wristLoad.label), findsWidgets);
    expect(find.text('Knee load'), findsOneWidget);
    expect(find.text(exercise.kneeLoad.label), findsWidgets);

    await tester.tap(characteristicsTitle);
    await tester.pumpAndSettle();
    expect(find.text('Exercise Characteristics'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timed and standalone details keep their original conditions',
      (tester) async {
    addTearDown(tester.view.reset);
    final timedExercise = ExerciseCatalog.byId('wall_sit')!;
    final l10n = englishAppLocalizations();
    await _pumpDetail(tester, exerciseId: timedExercise.id);

    expect(timedExercise.exerciseType, ExerciseType.timed);
    expect(find.text(timedExercise.name), findsWidgets);
    expect(find.text(timedExercise.exerciseType.label), findsOneWidget);
    expect(find.text(l10n.trainingProgression), findsNothing);
    expect(find.byType(ExerciseProgressionSection), findsNothing);

    final defaults = find.text(l10n.trainingDefaults);
    await tester.ensureVisible(defaults);
    await tester.tap(defaults);
    await tester.pumpAndSettle();
    expect(
      find.text(
        FitFlowLocaleFormat.formatDuration(
          l10n,
          timedExercise.defaultDuration!,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.trainingRest(
          FitFlowLocaleFormat.formatDuration(l10n, timedExercise.defaultRest!),
        ),
      ),
      findsOneWidget,
    );

    await _pumpDetail(tester, exerciseId: 'pushup_pike');
    expect(
        find.text(englishAppLocalizations().trainingProgression), findsNothing);
    expect(find.byType(ExerciseProgressionSection), findsNothing);
    // pushup_pike has registered production photography, so its hero renders;
    // the unknown-ID case below still covers the missing-media fallback.
    expect(
        find.byKey(const ValueKey('exercise_detail_media')), findsOneWidget);
    expect(find.byType(FitFlowExerciseImage), findsOneWidget);
    expect(find.text(ExerciseCatalog.byId('pushup_pike')!.shortDescription!),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing exercise still shows the existing safe fallback',
      (tester) async {
    addTearDown(tester.view.reset);
    await _pumpDetail(tester, exerciseId: 'unknown_exercise_xyz');
    final l10n = englishAppLocalizations();

    expect(find.text(l10n.trainingNotFound), findsWidgets);
    expect(find.text(l10n.trainingNotFoundHelp), findsOneWidget);
    expect(find.text(l10n.trainingBack), findsOneWidget);
    expect(find.text(l10n.trainingHowTo), findsNothing);
    expect(find.text(l10n.trainingMuscles), findsNothing);
    expect(find.byType(FitFlowExerciseImage), findsNothing);
    await tester.tap(find.text(l10n.trainingBack));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Light and Dark themes render without continuous motion',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final brightness in [Brightness.light, Brightness.dark]) {
      await _pumpDetail(tester, brightness: brightness);
      expect(
        Theme.of(tester
                .element(find.byKey(const ValueKey('exercise_detail_title'))))
            .brightness,
        brightness,
      );
      expect(
          find.byKey(const ValueKey('exercise_detail_media')), findsOneWidget);
      expect(find.byType(FitFlowExerciseImage), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'responsive sizes and 2x text keep content reachable and unclamped',
      (tester) async {
    addTearDown(tester.view.reset);
    const sizes = [
      Size(320, 700),
      Size(390, 844),
      Size(600, 900),
      Size(840, 1000),
      Size(900, 320),
    ];
    for (final size in sizes) {
      await _pumpDetail(tester, size: size);
      final media = tester.getSize(
        find.byKey(const ValueKey('exercise_detail_media')),
      );
      expect(media.width, greaterThan(0), reason: '$size');
      expect(media.height, greaterThan(0), reason: '$size');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('exercise_detail_title')))
            .maxLines,
        isNull,
        reason: '$size',
      );
      expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('exercise_detail_description')))
            .maxLines,
        isNull,
        reason: '$size',
      );
      expect(
          find.byKey(const ValueKey('exercise_detail_scroll')), findsOneWidget);
      if (size.width >= 840) {
        expect(
          tester
              .getSize(find.byKey(const ValueKey('exercise_detail_scroll')))
              .width,
          lessThanOrEqualTo(FitFlowLayout.maxContentWidth),
          reason: '$size',
        );
      }
      expect(media.width / media.height, closeTo(4 / 3, .001));
      expect(media.width, lessThanOrEqualTo(size.width - 32));
      expect(tester.takeException(), isNull, reason: '$size');
    }

    await _pumpDetail(
      tester,
      size: const Size(320, 700),
      textScale: 2,
    );
    final scaledMedia = tester.getSize(
      find.byKey(const ValueKey('exercise_detail_media')),
    );
    expect(scaledMedia.width, 288);
    expect(scaledMedia.width / scaledMedia.height, closeTo(4 / 3, .001));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('exercise_detail_title')))
          .maxLines,
      isNull,
    );
    await tester
        .ensureVisible(find.text(englishAppLocalizations().trainingDefaults));
    expect(tester.takeException(), isNull);
  });
}
