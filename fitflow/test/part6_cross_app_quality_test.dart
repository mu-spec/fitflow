import 'dart:ui' show CheckedState, Tristate;
import 'package:flutter/services.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'dart:async';

import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_capability_snapshot.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/features/workouts/presentation/widgets/exercise_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/backup_test_helpers.dart';

import 'helpers/part6_quality_helpers.dart';

class _FailedProfile extends UserFitnessProfileController {
  @override
  Future<UserFitnessProfile?> build() async =>
      throw StateError('TEST_INTERNAL_ERROR');
}

class _Capability extends CapabilityProfileController {
  _Capability(this.load);
  final Future<CapabilityProfile?> Function() load;
  @override
  Future<CapabilityProfile?> build() => load();
}

void main() {
  testWidgets('Startup recovery retains native semantic tap and minimum target',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await seedPart6();
    await tester.pumpWidget(part6Host(
        child: const SplashScreen(),
        extra: [userFitnessProfileProvider.overrideWith(_FailedProfile.new)]));
    await tester.pumpAndSettle();
    final retry = find.widgetWithText(FilledButton, 'Try again');
    final data = tester.getSemantics(retry).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hint, contains('without changing'));
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(find.textContaining('TEST_INTERNAL_ERROR'), findsNothing);
    semantics.dispose();
  });
  testWidgets(
      'Capability loading is static with reduced motion and failed read can retry',
      (tester) async {
    final pending = Completer<CapabilityProfile?>();
    await tester.pumpWidget(part6Host(
        child: const Scaffold(body: ProgressCapabilitySnapshot()),
        extra: [
          capabilityProfileProvider
              .overrideWith(() => _Capability(() => pending.future))
        ]));
    await tester.pumpAndSettle();
    expect(find.byType(FitFlowLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.completeError(StateError('TEST_INTERNAL_ERROR'));
    await tester.pumpAndSettle();
    expect(find.byType(FitFlowErrorState), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    assertClean(tester, 'capability error');
    await tester.pumpWidget(const SizedBox.shrink());
    var attempts = 0;
    await tester.pumpWidget(part6Host(
        child: const Scaffold(body: ProgressCapabilitySnapshot()),
        extra: [
          capabilityProfileProvider.overrideWith(() => _Capability(() async {
                if (attempts++ == 0) throw StateError('TEST_INTERNAL_ERROR');
                return backupCapabilityProfile();
              }))
        ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(FitFlowErrorState), findsNothing);
  });
  test('Central route fade uses canonical 200ms and zero reduced motion', () {
    expect(const FitFlowPageTransitionsBuilder().transitionDuration,
        FitFlowMotion.standard);
    expect(const FitFlowPageTransitionsBuilder().reverseTransitionDuration,
        FitFlowMotion.standard);
    expect(
        const FitFlowPageTransitionsBuilder(reducedMotion: true)
            .transitionDuration,
        Duration.zero);
    expect(
        const FitFlowPageTransitionsBuilder(reducedMotion: true)
            .reverseTransitionDuration,
        Duration.zero);
  });
  testWidgets(
      'Native navigation preserves Library branch and resize, same-tab resets',
      (tester) async {
    await seedPart6();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final router = await part6Route(tester, AppRoutes.exerciseLibrary);
    await tester.enterText(find.byType(TextField), 'squat');
    await tester.pumpAndSettle();
    Future<void> tab(String label) async {
      final chrome = find.byType(NavigationBar);
      await tester
          .tap(find.descendant(of: chrome, matching: find.text(label)).first);
      await tester.pumpAndSettle();
    }

    await tab('Home');
    expect(router.state.uri.path, AppRoutes.home);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0);
    await tab('Workouts');
    expect(router.state.uri.path, AppRoutes.exerciseLibrary);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'squat');
    tester.view.physicalSize = const Size(840, 1000);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.getTopLeft(find.byType(NavigationRail)).dy, 0);
    expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'squat');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tab('Workouts');
    expect(router.state.uri.path, AppRoutes.workouts);
    router.push(AppRoutes.exerciseLibrary);
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.workouts);
    assertClean(tester, 'navigation');
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
  for (final size in [const Size(320, 700), const Size(900, 320)]) {
    testWidgets('Custom add sheet scrolls with large text $size',
        (tester) async {
      await seedPart6();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final router =
          await part6Route(tester, AppRoutes.customWorkoutNew, scale: 2);
      await tester.ensureVisible(find.text('Add exercise').first);
      await tester.tap(find.text('Add exercise').first);
      await tester.pumpAndSettle();
      assertClean(tester, 'custom add sheet');
      final dialogContext = tester.element(find.text('Add exercise: Warm-up'));
      expect(
          (ModalRoute.of(dialogContext)! as TransitionRoute).transitionDuration,
          Duration.zero);
      await tester.enterText(
          find.widgetWithText(TextField, 'Search'), 'nothing-matches-TEST');
      await tester.pumpAndSettle();
      assertClean(tester, 'custom empty sheet');
      final clear = find.text('Clear search');
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      expect(clear.hitTestable(), findsOneWidget);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextField>(find.widgetWithText(TextField, 'Search'))
              .controller!
              .text,
          isEmpty);
      assertClean(tester, 'custom search cleared');

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
    testWidgets('Library keyboard scroll and filter $size', (tester) async {
      await seedPart6();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final router = await part6Route(tester, AppRoutes.exerciseLibrary,
          scale: 2, keyboard: size.height < 400 ? 100 : 250);
      await tester.enterText(find.byType(TextField), 'squat');
      await tester.pumpAndSettle();
      assertClean(tester, 'Library keyboard');
      final filter = find.text('Filters').first;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.ensureVisible(filter);
      await tester.pumpAndSettle();
      expect(filter.hitTestable(), findsOneWidget);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseFilterSheet), findsOneWidget);
      assertClean(tester, 'Library filter sheet');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    });
  }
  testWidgets(
      'Native appearance radio, reminder switch and filter keyboard semantics',
      (tester) async {
    await seedPart6();
    final router = await part6Route(tester, AppRoutes.settings);
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    try {
      final radio =
          find.widgetWithText(RadioListTile<AppearanceMode>, 'System default');
      final data = tester.getSemantics(radio).getSemanticsData();
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(radio).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(find.text('Workout reminders').first);
      await tester.tap(find.text('Workout reminders').first);
      await tester.pumpAndSettle();
      final toggle = find.byType(SwitchListTile).first;
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      final state = tester.getSemantics(toggle).getSemanticsData();
      expect(state.flagsCollection.isToggled, Tristate.isFalse);
      expect(state.hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(toggle).height, greaterThanOrEqualTo(48));
    } finally {
      handle.dispose();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    final library = await part6Route(tester, AppRoutes.exerciseLibrary);
    await tester.tap(find.widgetWithText(FilterChip, 'No equipment'));
    await tester.pumpAndSettle();
    final chipHandle = tester.ensureSemantics();
    try {
      final chip = tester
          .getSemantics(find.widgetWithText(FilterChip, 'No equipment'))
          .getSemanticsData();
      expect(chip.flagsCollection.isSelected, Tristate.isTrue);
      expect(chip.hasAction(SemanticsAction.tap), isTrue);
    } finally {
      chipHandle.dispose();
    }
    final filter = find.text('Filters (1)');
    Focus.of(tester.element(filter)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseFilterSheet), findsOneWidget);
    assertClean(tester, 'native controls');
    await tester.pumpWidget(const SizedBox.shrink());
    library.dispose();
  });
  testWidgets(
      'Central transition is fade only and reduced returns the unchanged child',
      (tester) async {
    const child = Text('TEST route');
    late Widget normal;
    late Widget reduced;
    await tester.pumpWidget(part6Host(
        reduced: false,
        child: Builder(builder: (context) {
          final route = MaterialPageRoute<void>(builder: (_) => child);
          normal = const FitFlowPageTransitionsBuilder().buildTransitions(
              route,
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0.0),
              child);
          reduced = const FitFlowPageTransitionsBuilder(reducedMotion: true)
              .buildTransitions(
                  route,
                  context,
                  const AlwaysStoppedAnimation(0.5),
                  const AlwaysStoppedAnimation(0.0),
                  child);
          return normal;
        })));
    expect(normal, isA<FadeTransition>());
    expect((normal as FadeTransition).opacity.value, inExclusiveRange(0, 1));
    expect(identical(reduced, child), isTrue);
  });
  testWidgets('Custom workout menu is immediate under reduced motion',
      (tester) async {
    await seedPart6();
    final router = await part6Route(tester, AppRoutes.workouts);
    final menu = find.byTooltip('Workout actions');
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    final entry = find.byType(PopupMenuItem<String>).first;
    expect(
        (ModalRoute.of(tester.element(entry))! as TransitionRoute)
            .transitionDuration,
        Duration.zero);
    assertClean(tester, 'custom menu');
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
  });
  for (final reduced in [false, true]) {
    testWidgets(
        'Program overlay short landscape native result reduced=$reduced',
        (tester) async {
      tester.view.physicalSize = const Size(900, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      bool? result;
      await tester.pumpWidget(part6Host(
          reduced: reduced,
          scale: 2,
          child: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await ProgramDialogs.confirmRestart(context);
                      },
                      child: const Text('Open TEST dialog'))))));
      await tester.tap(find.text('Open TEST dialog'));
      await tester.pumpAndSettle();
      assertClean(tester, 'program overlay');
      final route = ModalRoute.of(tester.element(find.byType(AlertDialog)))!;
      expect((route as TransitionRoute).transitionDuration,
          reduced ? Duration.zero : FitFlowMotion.standard);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, false);
    });
  }
}
