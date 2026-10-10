import 'dart:async';

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_screen.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/home/presentation/widgets/home_workout_hero_card.dart';
import 'package:fitflow/features/main/presentation/main_shell.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_choice.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/exercise_skill_tree_fixtures.dart';

void window(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(Widget child,
    {bool dark = false,
    double scale = 1,
    bool reduced = false,
    List<Override> overrides = const [],
    GoRouter? router}) {
  Widget builder(BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: reduced),
        child: SystemMotionTheme(child: child!),
      );
  return ProviderScope(
    overrides: overrides,
    child: router == null
        ? MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: builder,
            home: child)
        : MaterialApp.router(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: builder,
            routerConfig: router),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _ProfileLoader extends UserFitnessProfileController {
  _ProfileLoader(this.load);
  final Future<UserFitnessProfile?> Function() load;
  @override
  Future<UserFitnessProfile?> build() => load();
}

class _FailingSave extends UserFitnessProfileController {
  int saves = 0;
  @override
  Future<UserFitnessProfile?> build() async => null;
  @override
  Future<bool> saveProfile(UserFitnessProfile profile) async {
    saves++;
    return false;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sizes = [
    Size(320, 700),
    Size(390, 844),
    Size(430, 900),
    Size(600, 800),
    Size(900, 800),
    Size(900, 320)
  ];
  for (final dark in [false, true]) {
    for (final size in sizes) {
      testWidgets('Home and onboarding at $size dark=$dark 2x text',
          (tester) async {
        window(tester, size);
        await tester.pumpWidget(host(const HomeScreen(),
            dark: dark,
            scale: 2,
            reduced: true,
            overrides: programOverrides()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(HomeWorkoutHeroCard)).width,
            lessThanOrEqualTo(FitFlowLayout.maxContentWidth));
        await tester.ensureVisible(find.text('View workout'));
        expect(
            tester
                .getSize(find.widgetWithText(FilledButton, 'View workout'))
                .height,
            greaterThanOrEqualTo(48));
        await tapVisible(tester, find.text('Adjust'));
        expect(find.text("Choose today's workout"), findsOneWidget);
        await tapVisible(tester, find.text('Low Energy').last);
        final container =
            ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
        expect(container.read(workoutSessionModeProvider),
            WorkoutSessionMode.lowEnergy);
        expect(find.text('Temporary for this workout'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(host(const OnboardingScreen(),
            dark: dark, scale: 2, reduced: true));
        await tester.pumpAndSettle();
        expect(find.text('1 of 8'), findsOneWidget);
        await tapVisible(tester, find.text('Continue'));
        expect(find.text('2 of 8'), findsOneWidget);
        expect(
            tester
                .widget<FilledButton>(
                    find.widgetWithText(FilledButton, 'Continue'))
                .onPressed,
            isNull);
        await tapVisible(tester, find.text('General fitness'));
        expect(
            tester
                .widget<FilledButton>(
                    find.widgetWithText(FilledButton, 'Continue'))
                .onPressed,
            isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final reduced in [false, true]) {
    testWidgets(
        'all onboarding steps, selection/back and save routing reduced=$reduced',
        (tester) async {
      window(tester, const Size(320, 700));
      final router = GoRouter(initialLocation: AppRoutes.onboarding, routes: [
        GoRoute(
            path: AppRoutes.onboarding,
            builder: (context, state) => const OnboardingScreen()),
        GoRoute(
            path: AppRoutes.capabilityAssessment,
            builder: (context, state) => const CapabilityAssessmentScreen()),
        GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Text('Home destination'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(
          host(const SizedBox(), router: router, scale: 2, reduced: reduced));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
          tester.element(find.byType(OnboardingScreen)));
      const choices = {
        'goal': 'Build strength',
        'experience': 'Regular training',
        'workout_time': '20 minutes',
        'environment': 'Normal home',
        'equipment': 'Chair'
      };
      for (var i = 0; i < OnboardingPages.all.length; i++) {
        final page = OnboardingPages.all[i];
        expect(find.text('${i + 1} of 8'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (choices.containsKey(page.id)) {
          expect(
              tester
                  .widget<FilledButton>(
                      find.widgetWithText(FilledButton, 'Continue'))
                  .onPressed,
              isNull);
          await tapVisible(tester, find.text(choices[page.id]!));
        }
        if (page.id == 'equipment') {
          await tapVisible(tester, find.text('Exercise mat'));
          expect(container.read(onboardingControllerProvider).equipment,
              {WorkoutEquipment.chair, WorkoutEquipment.exerciseMat});
          await tapVisible(tester, find.text('None'));
          expect(container.read(onboardingControllerProvider).equipment,
              {WorkoutEquipment.none});
          await tapVisible(tester, find.text('Chair'));
          expect(container.read(onboardingControllerProvider).equipment,
              {WorkoutEquipment.chair});
        }
        if (page.id == 'preferences') {
          final before = container.read(onboardingControllerProvider);
          await tapVisible(tester, find.text('Back'));
          expect(container.read(onboardingControllerProvider), same(before));
          await tapVisible(tester, find.text('Continue'));
        }
        await tapVisible(
            tester, find.text(i == 7 ? 'Get Started' : 'Continue'));
      }
      expect(router.state.uri.path, AppRoutes.capabilityAssessment);
      expect(container.read(userFitnessProfileProvider).value!.equipment,
          {WorkoutEquipment.chair});
      expect(find.text('Movement Check'), findsOneWidget);
      expect(find.text('L3'), findsNothing);
      final selected = find.byKey(const ValueKey('level_push_level3'));
      await tester.scrollUntilVisible(selected, 150,
          scrollable: find.byType(Scrollable).first);
      expect(tester.widget<ChoiceChip>(selected).selected, isTrue);
      final easy = find.byKey(const ValueKey('level_push_level2'));
      await tapVisible(tester, easy);
      expect(tester.widget<ChoiceChip>(easy).selected, isTrue);
      expect(tester.takeException(), isNull);
      await tapVisible(
          tester, find.byKey(const Key('save_and_continue_button')));
      expect(router.state.uri.path, AppRoutes.home);
      expect(find.text('Home destination'), findsOneWidget);
    });
  }

  testWidgets('onboarding failed save stays on ready and offers retry',
      (tester) async {
    final fake = _FailingSave();
    await tester.pumpWidget(host(const OnboardingScreen(),
        overrides: [userFitnessProfileProvider.overrideWith(() => fake)]));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(OnboardingScreen)));
    final seed = programTestProfile();
    final controller = container.read(onboardingControllerProvider.notifier);
    controller.selectGoal(seed.goal);
    controller.selectExperience(seed.experience);
    controller.selectWorkoutDuration(seed.workoutDuration);
    controller.selectEnvironment(seed.environment);
    controller.toggleEquipment(WorkoutEquipment.none);
    for (var i = 0; i < 7; i++) {
      await tapVisible(tester, find.text('Continue'));
    }
    await tapVisible(tester, find.text('Get Started'));
    expect(find.text('Couldn’t save your setup. Please try again.'),
        findsOneWidget);
    expect(find.text('8 of 8'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Get Started'))
            .onPressed,
        isNotNull);
    await tapVisible(tester, find.text('Get Started'));
    expect(fake.saves, 2);
  });

  testWidgets('Home loading, local error, retry and truthful generated plan',
      (tester) async {
    final completer = Completer<UserFitnessProfile?>();
    var fail = true;
    var builds = 0;
    await tester.pumpWidget(host(const HomeScreen(), reduced: true, overrides: [
      ...programOverrides(),
      userFitnessProfileProvider.overrideWith(() => _ProfileLoader(() async {
            builds++;
            if (builds == 1) return completer.future;
            if (fail) throw StateError('PRIVATE_EXCEPTION');
            return programTestProfile();
          })),
    ]));
    await tester.pump();
    expect(find.text('Loading your adaptive workout...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    completer.completeError(StateError('PRIVATE_EXCEPTION'));
    await tester.pumpAndSettle();
    expect(find.text("We couldn't load your workout profile."), findsOneWidget);
    expect(find.textContaining('PRIVATE_EXCEPTION'), findsNothing);
    fail = false;
    await tapVisible(tester, find.text('Retry'));
    expect(builds, 2);
    final expected = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
        userProfile: programTestProfile(),
        capabilityProfile: skillTreeCapabilityProfile()))!;
    expect(
        find.text('${expected.totalExerciseCount} exercises'), findsOneWidget);
    final hero =
        tester.widget<HomeWorkoutHeroCard>(find.byType(HomeWorkoutHeroCard));
    expect(hero.plan.main.exercises.map((p) => p.exercise.id),
        expected.main.exercises.map((p) => p.exercise.id));
  });

  testWidgets('no-plan state offers profile recovery, not a fabricated plan',
      (tester) async {
    final profile = programUngenerableProfile();
    final capability =
        skillTreeCapabilityProfile(defaultLevel: CapabilityLevel.level1);
    expect(
        WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
            userProfile: profile, capabilityProfile: capability)),
        isNull);
    final router = GoRouter(initialLocation: AppRoutes.home, routes: [
      GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) =>
              const Scaffold(body: Text('Profile destination'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(host(const SizedBox(),
        router: router,
        overrides: programOverrides(profile: profile, capability: capability)));
    await tester.pumpAndSettle();
    expect(find.text('No complete workout available'), findsOneWidget);
    expect(find.text('View workout'), findsNothing);
    await tapVisible(tester, find.text('Review your profile'));
    expect(router.state.uri.path, AppRoutes.profile);
  });

  testWidgets('Home CTA keeps native accessibility tap and routes to preview',
      (tester) async {
    final handle = tester.ensureSemantics();
    final router = GoRouter(initialLocation: AppRoutes.home, routes: [
      GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
                path: 'workout-preview',
                builder: (context, state) =>
                    const Scaffold(body: Text('Preview destination'))),
          ]),
    ]);
    addTearDown(router.dispose);
    try {
      await tester.pumpWidget(host(const SizedBox(),
          router: router, overrides: programOverrides()));
      await tester.pumpAndSettle();
      final data = tester
          .getSemantics(find.widgetWithText(FilledButton, 'View workout'))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);
      await tapVisible(tester, find.text('View workout'));
      expect(router.state.uri.path, AppRoutes.workoutPreview);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
      'onboarding option retains native tap action and selected semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(Scaffold(
          body: OnboardingChoice(
              label: 'Option', selected: true, onSelected: () {}))));
      final data = tester
          .getSemantics(find.bySemanticsLabel(RegExp('Option')))
          .getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, contains('Selected'));
      expect(data.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
      'navigation preserves branches/reselect and widget state through bar/rail resize',
      (tester) async {
    window(tester, const Size(390, 800));
    final router = GoRouter(initialLocation: '/home', routes: [
      StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(navigationShell: shell),
          branches: [
            for (final path in ['home', 'workouts', 'progress', 'profile'])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: '/$path',
                    builder: (context, state) => _BranchCounter(name: path),
                    routes: [
                      GoRoute(
                          path: 'detail',
                          builder: (context, state) =>
                              Scaffold(body: Text('$path detail'))),
                    ]),
              ]),
          ]),
    ]);
    addTearDown(router.dispose);
    await tester
        .pumpWidget(host(const SizedBox(), router: router, reduced: true));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('home count 0'));
    router.push('/home/detail');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Workouts'));
    await tapVisible(tester, find.text('workouts count 0'));
    await tapVisible(tester, find.text('Home'));
    expect(router.state.uri.path, '/home/detail');
    await tapVisible(tester, find.text('Home'));
    expect(router.state.uri.path, '/home');
    expect(find.text('home count 1'), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0);
    expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .animationDuration,
        Duration.zero);
    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('home count 1'), findsOneWidget);
    await tapVisible(tester, find.text('Workouts'));
    expect(find.text('workouts count 1'), findsOneWidget);
    tester.view.physicalSize = const Size(900, 220);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Profile'));
    expect(router.state.uri.path, '/profile');
    expect(tester.takeException(), isNull);
  });
}

class _BranchCounter extends StatefulWidget {
  const _BranchCounter({required this.name});
  final String name;
  @override
  State<_BranchCounter> createState() => _BranchCounterState();
}

class _BranchCounterState extends State<_BranchCounter> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: TextButton(
        onPressed: () => setState(() => count++),
        child: Text('${widget.name} count $count'),
      )));
}
