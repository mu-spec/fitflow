import 'dart:ui' show Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/profile/presentation/equipment_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/widgets/profile_editor_widgets.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  testWidgets(
      'Profile keeps canonical summaries, read-only movement order, and Settings',
      (tester) async {
    final profile = _summaryProfile();
    final capability = _capabilityFixture();
    final router = await _pumpProfileV2App(
      tester,
      initialLocation: AppRoutes.profile,
      profile: profile,
      capability: capability,
    );
    addTearDown(router.dispose);

    final semantics = tester.ensureSemantics();
    try {
      expect(find.text('FITFLOW'), findsOneWidget);
      expect(find.text('Your profile'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Your profile')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        find.text('Your setup for future workouts.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'General fitness • Some experience\n20 minutes • Normal home',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Exercise mat, Chair, Dumbbells, Towel'),
        findsOneWidget,
      );
      expect(
        find.text('No jumping, Low impact, Standing only'),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance, reminders, and backups.'), findsOneWidget);
      expect(find.byType(ProfileOptionTile), findsNothing);

      await _ensureVisibleAndTap(tester, 'Movement levels');
      expect(find.text('How exercise variations are chosen'), findsOneWidget);
      final movementLabels = [
        'Push',
        'Pull',
        'Squat',
        'Lunge',
        'Hinge',
        'Core',
        'Glute',
        'Cardio',
        'Mobility',
        'Balance',
      ];
      final yPositions = <double>[];
      for (final label in movementLabels) {
        expect(find.text(label), findsOneWidget, reason: label);
        yPositions.add(tester.getTopLeft(find.text(label)).dy);
      }
      for (var index = 1; index < yPositions.length; index++) {
        expect(yPositions[index], greaterThan(yPositions[index - 1]));
      }
      for (final choice in [
        'Just starting',
        'Basic',
        'Solid',
        'Strong',
        'Advanced'
      ]) {
        expect(find.text(choice), findsWidgets, reason: choice);
      }
      expect(find.byType(ProfileOptionTile), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('editing one Fitness Profile value saves only that value',
      (tester) async {
    final profile = profileEditorSeed();
    final capability = _capabilityFixture();
    final router = await _pumpProfileV2App(
      tester,
      initialLocation: AppRoutes.profile,
      profile: profile,
      capability: capability,
    );
    addTearDown(router.dispose);

    final prefs = await SharedPreferences.getInstance();
    final capabilitiesBefore =
        prefs.getString(CapabilityProfileStorage.profileKey);
    final profileBefore = prefs.getString(UserFitnessProfileStorage.profileKey);

    await _ensureVisibleAndTap(tester, 'Fitness Profile');
    expect(find.text('These settings shape future adaptive workouts.'),
        findsOneWidget);
    await _ensureVisibleAndTap(tester, 'Goal');
    await _ensureVisibleAndTap(tester, 'Build muscle');

    // Draft selection is visible, but persistence waits for explicit Save.
    expect(
      prefs.getString(UserFitnessProfileStorage.profileKey),
      profileBefore,
    );
    await _ensureVisibleAndTap(tester, 'Save changes');
    await _settleProfileFrames(tester);

    expect(find.text('Fitness profile updated.'), findsOneWidget);
    expect(find.text('Your profile'), findsOneWidget);
    final saved = UserFitnessProfileStorage(prefs).load()!;
    expect(saved.goal, FitnessGoal.buildMuscle);
    expect(saved.experience, profile.experience);
    expect(saved.workoutDuration, profile.workoutDuration);
    expect(saved.environment, profile.environment);
    expect(saved.equipment, profile.equipment);
    expect(saved.preferences, profile.preferences);
    expect(
      prefs.getString(CapabilityProfileStorage.profileKey),
      capabilitiesBefore,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'equipment and preference selections stay explicit and independent',
      (tester) async {
    final profile = profileEditorSeed();
    final capability = _capabilityFixture();
    final router = await _pumpProfileV2App(
      tester,
      initialLocation: AppRoutes.equipment,
      profile: profile,
      capability: capability,
    );
    addTearDown(router.dispose);

    final prefs = await SharedPreferences.getInstance();
    final capabilitiesBefore =
        prefs.getString(CapabilityProfileStorage.profileKey);
    final chairTile = _optionTile('Chair');
    expect(tester.getSize(chairTile).height, greaterThanOrEqualTo(48));
    expect(_hasSelectedCheck(tester, chairTile), isTrue);

    final chairSemantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Chair')),
    );
    expect(chairSemantics.getSemanticsData().label, contains('Chair'));
    expect(chairSemantics.flagsCollection.isButton, isTrue);
    expect(chairSemantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(chairSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue);
    expect(chairSemantics.getSemanticsData().hasAction(SemanticsAction.focus),
        isTrue);

    await _ensureVisibleAndTap(tester, 'None');
    expect(_hasSelectedCheck(tester, _optionTile('None')), isTrue);
    expect(_hasSelectedCheck(tester, _optionTile('Chair')), isFalse);
    await _ensureVisibleAndTap(tester, 'Save changes');
    await _settleProfileFrames(tester);

    expect(find.text('Equipment updated.'), findsOneWidget);
    final afterEquipment = UserFitnessProfileStorage(prefs).load()!;
    expect(afterEquipment.equipment, {WorkoutEquipment.none});
    expect(afterEquipment.goal, profile.goal);
    expect(afterEquipment.experience, profile.experience);
    expect(afterEquipment.workoutDuration, profile.workoutDuration);
    expect(afterEquipment.environment, profile.environment);
    expect(afterEquipment.preferences, profile.preferences);
    expect(
      prefs.getString(CapabilityProfileStorage.profileKey),
      capabilitiesBefore,
    );

    await _ensureVisibleAndTap(tester, 'Workout Preferences');
    await _ensureVisibleAndTap(tester, 'Low impact');
    await _ensureVisibleAndTap(tester, 'Save changes');
    await _settleProfileFrames(tester);

    final afterPreferences = UserFitnessProfileStorage(prefs).load()!;
    expect(
      afterPreferences.preferences,
      {WorkoutPreference.noJumping, WorkoutPreference.lowImpact},
    );
    expect(afterPreferences.goal, profile.goal);
    expect(afterPreferences.experience, profile.experience);
    expect(afterPreferences.workoutDuration, profile.workoutDuration);
    expect(afterPreferences.environment, profile.environment);
    expect(afterPreferences.equipment, {WorkoutEquipment.none});
    expect(
      prefs.getString(CapabilityProfileStorage.profileKey),
      capabilitiesBefore,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile and all three editors fit the requested viewport matrix',
      (tester) async {
    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 700), textScale: 1),
      (size: Size(390, 844), textScale: 1),
      (size: Size(600, 900), textScale: 1),
      (size: Size(840, 1000), textScale: 1),
      (size: Size(900, 320), textScale: 1),
      (size: Size(320, 700), textScale: 2),
    ];
    const screens = <({String route, String title, String lastControl})>[
      (
        route: AppRoutes.fitnessProfile,
        title: 'Fitness profile',
        lastControl: 'Training environment',
      ),
      (route: AppRoutes.equipment, title: 'Equipment', lastControl: 'Towel'),
      (
        route: AppRoutes.workoutPreferences,
        title: 'Workout preferences',
        lastControl: 'Avoid deep knee bending',
      ),
    ];

    for (final viewport in viewports) {
      final router = await _pumpProfileV2App(
        tester,
        initialLocation: AppRoutes.profile,
        profile: _summaryProfile(),
        capability: _capabilityFixture(),
        size: viewport.size,
        textScale: viewport.textScale,
      );
      try {
        expect(find.text('Your profile'), findsOneWidget);
        await tester.ensureVisible(find.text('Settings'));
        expect(
            tester.getRect(find.text('Settings')).overlaps(
                  Offset.zero & viewport.size,
                ),
            isTrue);
        expect(tester.takeException(), isNull, reason: 'Profile $viewport');

        for (final screen in screens) {
          router.go(screen.route);
          await _settleProfileFrames(tester);
          expect(find.text(screen.title), findsOneWidget);
          expect(find.text('Save changes'), findsOneWidget);
          await tester.ensureVisible(find.text(screen.lastControl));
          expect(
            tester.getRect(find.text('Save changes')).overlaps(
                  Offset.zero & viewport.size,
                ),
            isTrue,
            reason: '${screen.title} Save reachability at $viewport',
          );
          final editorContent = screen.route == AppRoutes.fitnessProfile
              ? find.byType(ProfileDisclosure).first
              : find.byType(ProfileOptionTile).first;
          expect(
            tester.getSize(editorContent).width,
            lessThanOrEqualTo(720),
            reason: '${screen.title} bounded content at $viewport',
          );
          expect(tester.takeException(), isNull,
              reason: '${screen.title} $viewport');
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }
    }
  });

  testWidgets(
      'Dark mode, reduced motion, semantics, and keyboard focus remain usable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final router = await _pumpProfileV2App(
      tester,
      initialLocation: AppRoutes.equipment,
      profile: profileEditorSeed(),
      capability: _capabilityFixture(),
      brightness: Brightness.dark,
      reducedMotion: true,
    );
    try {
      final equipmentContext =
          tester.element(find.byType(EquipmentEditorScreen));
      expect(SystemMotion.standard(equipmentContext), Duration.zero);
      expect(Theme.of(equipmentContext).brightness, Brightness.dark);

      final chairTile = _optionTile('Chair');
      expect(
          find.descendant(
              of: chairTile, matching: find.byType(AnimatedContainer)),
          findsNothing);
      final focusable = find.descendant(
        of: chairTile,
        matching: find.byType(InkWell),
      );
      final gesture = find.descendant(
        of: focusable,
        matching: find.byType(GestureDetector),
      );
      final focusNode = Focus.of(tester.element(gesture), scopeOk: false);
      expect(focusNode.canRequestFocus, isTrue);

      var reachedOption = false;
      for (var index = 0; index < 24; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (identical(FocusManager.instance.primaryFocus, focusNode)) {
          reachedOption = true;
          break;
        }
      }
      expect(reachedOption, isTrue,
          reason: 'Tab should reach an equipment control');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settleProfileFrames(tester);
      expect(_hasSelectedCheck(tester, _optionTile('Chair')), isFalse);
      expect(_hasSelectedCheck(tester, _optionTile('None')), isTrue);
      expect(tester.takeException(), isNull);

      router.go(AppRoutes.profile);
      await _settleProfileFrames(tester);
      await tester.ensureVisible(find.text('Movement levels'));
      final disclosure = find.byType(ProfileDisclosure).first;
      final tile = tester.widget<ExpansionTile>(
        find.descendant(of: disclosure, matching: find.byType(ExpansionTile)),
      );
      expect(tile.expansionAnimationStyle?.duration, Duration.zero);
      await tester.tap(find.text('Movement levels'));
      await tester.pump();
      expect(find.text('How exercise variations are chosen'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      router.dispose();
    }
  });
}

UserFitnessProfile _summaryProfile() => UserFitnessProfile(
      goal: FitnessGoal.generalFitness,
      experience: ExperienceLevel.someExperience,
      workoutDuration: WorkoutDuration.twentyMinutes,
      environment: TrainingEnvironment.normalHome,
      equipment: const {
        WorkoutEquipment.dumbbells,
        WorkoutEquipment.exerciseMat,
        WorkoutEquipment.chair,
        WorkoutEquipment.towel,
      },
      preferences: const {
        WorkoutPreference.noJumping,
        WorkoutPreference.lowImpact,
        WorkoutPreference.standingOnly,
      },
    );

CapabilityProfile _capabilityFixture() {
  const levels = [
    CapabilityLevel.level2,
    CapabilityLevel.level4,
    CapabilityLevel.level1,
    CapabilityLevel.level5,
    CapabilityLevel.level3,
    CapabilityLevel.level2,
    CapabilityLevel.level4,
    CapabilityLevel.level1,
    CapabilityLevel.level3,
    CapabilityLevel.level5,
  ];
  final updatedAt = DateTime.utc(2026, 10, 16);
  return CapabilityProfile.fromMap({
    for (var index = 0;
        index < CapabilityProfile.trainablePatterns.length;
        index++)
      CapabilityProfile.trainablePatterns[index]: MovementCapability(
        movementPattern: CapabilityProfile.trainablePatterns[index],
        level: levels[index],
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      ),
  });
}

Future<GoRouter> _pumpProfileV2App(
  WidgetTester tester, {
  required String initialLocation,
  required UserFitnessProfile profile,
  required CapabilityProfile capability,
  Size size = const Size(390, 844),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool reducedMotion = false,
}) async {
  final initialValues = <String, Object>{
    ...seedProfilePrefs(profile),
    CapabilityProfileStorage.profileKey:
        CapabilityProfileStorage.encode(capability),
  };
  SharedPreferences.setMockInitialValues(initialValues);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = AppRouter.create(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: SystemMotionTheme(child: child ?? const SizedBox.shrink()),
        ),
        routerConfig: router,
      ),
    ),
  );
  await _settleProfileFrames(tester);
  return router;
}

Finder _optionTile(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byType(ProfileOptionTile),
    )
    .first;

bool _hasSelectedCheck(WidgetTester tester, Finder tile) => find
    .descendant(of: tile, matching: find.byIcon(Icons.check_circle))
    .evaluate()
    .isNotEmpty;

Future<void> _ensureVisibleAndTap(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settleProfileFrames(tester);
}

Future<void> _settleProfileFrames(WidgetTester tester, [int frames = 8]) async {
  for (var index = 0; index < frames; index++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}
