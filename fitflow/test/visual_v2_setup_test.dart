import 'dart:ui' show Tristate;
import 'dart:async';
import 'package:fitflow/core/design/fitflow_v2_setup.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_choice.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_screen.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_state.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitflow/features/onboarding/presentation/setup_photo_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/part6_quality_helpers.dart' as qa;
import 'helpers/backup_test_helpers.dart';
import 'helpers/profile_editor_test_helpers.dart';

Future<void> pressV2(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const setupChoices = <int, String>{
  1: 'General fitness',
  2: 'Regular training',
  3: '20 minutes',
  4: 'Normal home',
  5: 'Chair'
};

class PendingCapabilitySave extends CapabilityProfileController {
  final completion = Completer<bool>();
  int calls = 0;
  @override
  Future<CapabilityProfile?> build() async => null;
  @override
  Future<bool> saveProfile(CapabilityProfile profile) {
    calls++;
    return completion.future;
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('photo choices retain contrast without opaque cards dark=$dark',
        (tester) async {
      await tester.pumpWidget(qa.part6Host(
          dark: dark,
          child: SetupPhotoTheme(
              child: SetupPhotoBackground(
                  exerciseId: 'march_in_place',
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: SetupPhotoPanel(
                          child: OnboardingChoice(
                              label: 'TEST choice',
                              selected: false,
                              onSelected: () {})))))));
      final context = tester.element(find.byType(OnboardingChoice));
      final label = Theme.of(context).colorScheme.onSurfaceVariant;
      // Worst-case white photograph under the weakest scrim and one panel.
      final choice = tester.widget<Material>(find
          .descendant(
              of: find.byType(OnboardingChoice),
              matching: find.byType(Material))
          .first);
      final gradient = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((box) => box.gradient)
          .whereType<LinearGradient>()
          .first;
      final weakest = gradient.colors.reduce((a, b) => a.a < b.a ? a : b);
      final background = Color.alphaBlend(
          choice.color!, Color.alphaBlend(weakest, Colors.white));
      expect(
          (label.computeLuminance() + .05) /
              (background.computeLuminance() + .05),
          greaterThanOrEqualTo(4.5));
      for (final material in tester.widgetList<Material>(find.descendant(
          of: find.byType(SetupPhotoPanel), matching: find.byType(Material)))) {
        if (material.color != null) {
          expect(material.color!.a, lessThan(.7));
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final size in qa.part6Sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('V2 setup and ten movements $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({});
          await tester.pumpWidget(qa.part6Host(
              child: const OnboardingScreen(), dark: dark, scale: scale));
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
              tester.element(find.byType(OnboardingScreen)));
          final allLabels = <int, List<String>>{
            1: FitnessGoal.values.map((e) => e.label).toList(),
            2: ExperienceLevel.values.map((e) => e.label).toList(),
            3: WorkoutDuration.values.map((e) => e.label).toList(),
            4: TrainingEnvironment.values.map((e) => e.label).toList(),
            5: WorkoutEquipment.values.map((e) => e.label).toList(),
            6: WorkoutPreference.values.map((e) => e.label).toList(),
          };
          for (var step = 0; step < 8; step++) {
            expect(find.text('${step + 1} of 8'), findsOneWidget);
            final backdrop = find.byKey(const Key('setup_fullscreen_photo'));
            expect(backdrop, findsOneWidget);
            expect(tester.getSize(backdrop), size);
            expect(tester.widget<Image>(backdrop).fit, BoxFit.cover);
            for (var i = 0; i < 8; i++) {
              final segment = tester.widget<AnimatedContainer>(
                  find.byKey(ValueKey('setup_segment_$i')));
              expect(segment.duration, Duration.zero);
            }
            for (final label in allLabels[step] ?? <String>[]) {
              expect(find.text(label), findsOneWidget);
            }
            if (setupChoices.containsKey(step)) {
              expect(
                  tester
                      .widget<FilledButton>(
                          find.widgetWithText(FilledButton, 'Continue'))
                      .onPressed,
                  isNull);
              await pressV2(tester, find.text(setupChoices[step]!));
            }
            if (step == 5) {
              await pressV2(tester, find.text('None'));
              expect(container.read(onboardingControllerProvider).equipment,
                  {WorkoutEquipment.none});
              await pressV2(tester, find.text('Chair'));
              await pressV2(tester, find.text('Exercise mat'));
              expect(container.read(onboardingControllerProvider).equipment,
                  {WorkoutEquipment.chair, WorkoutEquipment.exerciseMat});
            }
            if (step == 6) {
              await pressV2(tester, find.text('No jumping'));
              await pressV2(tester, find.text('Low impact'));
              expect(container.read(onboardingControllerProvider).preferences,
                  {WorkoutPreference.noJumping, WorkoutPreference.lowImpact});
            }
            final cta = find.widgetWithText(
                FilledButton, step == 7 ? 'Get Started' : 'Continue');
            await tester.ensureVisible(cta);
            await tester.pumpAndSettle();
            expect(cta.hitTestable(), findsOneWidget);
            expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
            if (step < 7) await pressV2(tester, cta);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          SharedPreferences.setMockInitialValues(
              seedProfilePrefs(backupProfile()));
          await tester.pumpWidget(qa.part6Host(
              child: const CapabilityAssessmentScreen(),
              dark: dark,
              scale: scale));
          await tester.pumpAndSettle();
          expect(
              tester.getSize(find.byKey(const Key('setup_fullscreen_photo'))),
              size);
          final defaults = CapabilityAssessmentState.fromExperienceLevel(
              backupProfile().experience);
          expect(CapabilityAssessmentCatalog.all.length, 10);
          for (final item in CapabilityAssessmentCatalog.all) {
            final key =
                ValueKey('assessment_card_${item.movementPattern.name}');
            await tester.scrollUntilVisible(find.byKey(key), 160,
                scrollable: find.byType(Scrollable).first, maxScrolls: 150);
            for (final level in CapabilityLevel.values) {
              final chip = find.byKey(
                  ValueKey('level_${item.movementPattern.name}_${level.name}'));
              expect(
                  tester.widget<ChoiceChip>(chip).selected,
                  level ==
                      defaults.answerFor(item.movementPattern)!.selectedLevel);
            }
            final strong = find
                .byKey(ValueKey('level_${item.movementPattern.name}_level4'));
            await tester.ensureVisible(strong);
            await tester.pumpAndSettle();
            await tester.tap(strong);
            await tester.pumpAndSettle();
            expect(tester.widget<ChoiceChip>(strong).selected, isTrue);
            expect(tester.takeException(), isNull);
          }
          final save = find.byKey(const Key('save_and_continue_button'));
          if (save.evaluate().isEmpty) {
            await tester.scrollUntilVisible(save, 180,
                scrollable: find.byType(Scrollable).first, maxScrolls: 100);
          }
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          expect(save.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final multi in [false, true]) {
    testWidgets(
        'V2 selected semantics and native keyboard activation multi=$multi',
        (tester) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(qa.part6Host(
            child: Scaffold(
                body: OnboardingChoice(
                    label: 'TEST choice',
                    selected: true,
                    multiSelect: multi,
                    onSelected: () => taps++))));
        final finder = find.bySemanticsLabel(RegExp('TEST choice'));
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.flagsCollection.isSelected, Tristate.isTrue);
        expect(data.label, contains('Selected'));
        expect(tester.getSize(find.byType(OnboardingChoice)).height,
            greaterThanOrEqualTo(48));
        await tester.tap(find.text('TEST choice'));
        expect(taps, 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(taps, 2);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('V2 assessment waits for save and retains retry after failure',
      (tester) async {
    SharedPreferences.setMockInitialValues(seedProfilePrefs(backupProfile()));
    final fake = PendingCapabilitySave();
    await tester.pumpWidget(qa.part6Host(
        child: const CapabilityAssessmentScreen(),
        extra: [capabilityProfileProvider.overrideWith(() => fake)]));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('save_and_continue_button'));
    await pressV2(tester, button);
    expect(fake.calls, 1);
    expect(find.text('Saving your movement levels'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(button, findsNothing);
    fake.completion.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Failed to save your movement profile. Please try again.'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    expect(find.byType(CapabilityAssessmentScreen), findsOneWidget);
  });

  for (final size in [const Size(390, 844), const Size(900, 320)]) {
    testWidgets('V2 keyboard inset and 2x CTA $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(qa.part6Host(
          child: const OnboardingScreen(), scale: 2, keyboard: 160));
      await tester.pumpAndSettle();
      await pressV2(tester, find.text('Continue'));
      await pressV2(tester, find.text('General fitness'));
      await tester.ensureVisible(find.text('Continue'));
      expect(find.text('Continue').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('static V2 motif avoids unchanged repaint', () {
    const painter = FitFlowV2AdaptivePainter(Colors.green, Colors.white);
    expect(painter.shouldRepaint(painter), isFalse);
  });
}
