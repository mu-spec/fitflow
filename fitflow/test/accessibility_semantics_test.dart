import 'dart:ui' show CheckedState, Tristate;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/presentation/equipment_step_content.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

class _ThrowingProfileController extends UserFitnessProfileController {
  @override
  Future<UserFitnessProfile?> build() async {
    throw StateError('unreadable');
  }
}

WorkoutPlan _timedPlan() {
  WorkoutExercisePrescription timed(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: 1,
      repsPerSet: null,
      workDuration: const Duration(seconds: 8),
      restBetweenSets: const Duration(seconds: 4),
    );
  }

  return WorkoutPlan(
    warmup: WorkoutSection(
      type: WorkoutSectionType.warmup,
      exercises: [timed('march_in_place')],
    ),
    main: WorkoutSection(
      type: WorkoutSectionType.main,
      exercises: [timed('squat_bodyweight')],
    ),
    cooldown: WorkoutSection(
      type: WorkoutSectionType.cooldown,
      exercises: [timed('figure_four_stretch')],
    ),
    timeBudget: const WorkoutTimeBudget(
      target: Duration(minutes: 16),
      warmup: Duration(minutes: 2),
      main: Duration(minutes: 12),
      cooldown: Duration(minutes: 2),
    ),
  );
}

bool _button(SemanticsNode node) => node.flagsCollection.isButton;

bool _selected(SemanticsNode node) =>
    node.flagsCollection.isSelected == Tristate.isTrue ||
    node.flagsCollection.isChecked == CheckedState.isTrue;

bool _exclusive(SemanticsNode node) =>
    node.flagsCollection.isInMutuallyExclusiveGroup;

bool _live(SemanticsNode node) => node.flagsCollection.isLiveRegion;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onboarding option exposes label, button, and selected state',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OnboardingOptionCard(
            label: 'General fitness',
            helperText: 'A balanced starting point',
            selected: true,
            onSelected: () {},
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('General fitness')),
    );
    expect(node.label, contains('General fitness'));
    expect(node.label, contains('Selected'));
    expect(_button(node), isTrue);
    expect(_selected(node), isTrue);
    expect(_exclusive(node), isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('equipment selection is a named multi-select, not color-only',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: EquipmentStepContent()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Chair'));
    await tester.pump();

    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Chair')));
    expect(node.label, contains('Chair'));
    expect(node.label, contains('Selected'));
    expect(_button(node), isTrue);
    expect(_selected(node), isTrue);
    expect(_exclusive(node), isFalse);
    expect(find.byIcon(Icons.check_box), findsWidgets);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('startup Retry is a named button and does not write data',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
    SharedPreferences.setMockInitialValues({});
    final before = (await SharedPreferences.getInstance()).getKeys();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userFitnessProfileProvider.overrideWith(_ThrowingProfileController.new),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(SplashScreen.recoveryTitle), findsOneWidget);
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^${SplashScreen.recoveryAction}\$')),
    );
    expect(_button(node), isTrue);
    expect(node.label, SplashScreen.recoveryAction);
    expect(node.hint, contains('without changing'));
    expect((await SharedPreferences.getInstance()).getKeys(), before);
    expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('player pause and timer are named, and countdown is not live',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
    final plan = _timedPlan();
    await tester.pumpWidget(
      ProviderScope(
        overrides: programOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: WorkoutPlayerSessionView(
            plan: plan,
            sessionMode: WorkoutSessionMode.standard,
            sessionOrigin: WorkoutSessionOrigin.adaptive,
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkoutPlayerSessionView)),
    );
    final controller =
        container.read(workoutPlayerControllerProvider(plan).notifier);
    controller.beginWorkout();
    await tester.pump();

    final pause = tester.getSemantics(find.byTooltip('Pause workout'));
    expect(pause.label, contains('Pause workout'));
    expect(_button(pause), isTrue);

    final timer = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Remaining \d+ seconds$')),
    );
    expect(_live(timer), isFalse);

    final phase = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'Warm-up\.')),
    );
    expect(_live(phase), isTrue);
    expect(phase.label, isNot(contains('seconds')));
    final announced = phase.label;

    await tester.pump(const Duration(seconds: 1));
    final after = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'Warm-up\.')),
    );
    expect(after.label, announced);
    expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('completion feedback selection is exposed to semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
    MovementWorkoutFeedback? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SegmentedButton<MovementWorkoutFeedback>(
                segments: [
                  for (final option in MovementWorkoutFeedback.values)
                    ButtonSegment(
                      value: option,
                      label: Text(option.label),
                      tooltip: option.description,
                    ),
                ],
                selected: selected == null ? {} : {selected!},
                emptySelectionAllowed: true,
                onSelectionChanged: (next) {
                  setState(() => selected = next.isEmpty ? null : next.first);
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Too hard'));
    await tester.pump();
    final node = tester.getSemantics(find.text('Too hard'));
    expect(_selected(node), isTrue);
    expect(find.text('Just right'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('appearance choice exposes the selected radio', (tester) async {
    ensureTimezones();
    final handle = tester.ensureSemantics();
    try {
    final reminders = FakeWorkoutReminderNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: reminderOverrides(service: reminders),
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Light'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final node = tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Light, selected$')));
    expect(node.label, contains('Light'));
    expect(_selected(node), isTrue);
    expect(_exclusive(node), isTrue);
    expect(_button(node), isTrue);
    expect(_exclusive(node), isTrue);
    expect(tester.takeException(), isNull);
    } finally {
      handle.dispose();
    }
  });
}
