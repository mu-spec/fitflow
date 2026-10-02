import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workout_player/application/workout_player_controller.dart';
import 'package:fitflow/features/workout_player/domain/workout_coach.dart';
import 'package:fitflow/features/workout_player/domain/workout_player_phase.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:flutter_test/flutter_test.dart';

/// M21 Part 1: Player timing efficiency and resource safety.
///
/// - the controller never owns more than one timer
/// - pause/resume/dispose are resource-safe and idempotent
/// - deadline-aware ticks correct delayed-tick drift without advancing
///   while paused
/// - zero-duration paths never spin timers
/// - ticks stay quiet: no voice per countdown tick
void main() {
  /// Minimal viable plan: timed warm-up, reps main (2 sets), timed cooldown.
  WorkoutPlan buildPlan({Duration mainRest = const Duration(seconds: 15)}) {
    final march = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId('march_in_place')!,
    )!;
    final squatBase = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId('squat_bodyweight')!,
    )!;
    final squat = WorkoutExercisePrescription(
      exercise: squatBase.exercise,
      sets: 2,
      repsPerSet: squatBase.repsPerSet,
      workDuration: null,
      restBetweenSets: mainRest,
    );
    final stretch = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId('figure_four_stretch')!,
    )!;

    return WorkoutPlan(
      warmup: WorkoutSection(
        type: WorkoutSectionType.warmup,
        exercises: [march],
      ),
      main: WorkoutSection(
        type: WorkoutSectionType.main,
        exercises: [squat],
      ),
      cooldown: WorkoutSection(
        type: WorkoutSectionType.cooldown,
        exercises: [stretch],
      ),
      timeBudget: const WorkoutTimeBudget(
        target: Duration(minutes: 16),
        warmup: Duration(minutes: 2),
        main: Duration(minutes: 12),
        cooldown: Duration(minutes: 2),
      ),
    );
  }

  /// Controllable monotonic timing seam for deadline-awareness tests.
  /// Each phase receives a fresh stopwatch (like production), all driven by
  /// one shared fake clock the test advances manually.
  final clock = _FakeClock();
  WorkoutPlayerController controller({
    WorkoutPlan? plan,
    bool autoStartTimer = true,
    WorkoutCoach? coach,
  }) {
    return WorkoutPlayerController(
      plan: plan ?? buildPlan(),
      autoStartTimer: autoStartTimer,
      coach: coach,
      stopwatchFactory: () => _FakeStopwatch(clock),
    );
  }

  setUp(clock.reset);

  test('timed work phase: normal ticks stay deterministic', () {
    final c = controller();
    addTearDown(c.dispose);

    c.beginWorkout();
    expect(c.state.phase, WorkoutPlayerPhase.work);
    expect(c.hasActiveTimer, isTrue, reason: 'one timer drives the phase');

    final initial = c.state.remaining;
    clock.advance(const Duration(seconds: 1));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 1));

    clock.advance(const Duration(seconds: 1));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 2));
  });

  test('delayed ticks are corrected by the monotonic deadline', () {
    final c = controller();
    addTearDown(c.dispose);

    c.beginWorkout();
    final initial = c.state.remaining;

    // The event loop stalls: only ONE tick arrives after 7 seconds.
    clock.advance(const Duration(seconds: 7));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 7),
        reason: 'deadline-aware countdown must not accumulate tick lag');

    // Another stall pushes past the phase end; the next single tick
    // completes the phase instead of counting down stale seconds.
    clock.advance(const Duration(seconds: 60));
    c.tick();
    expect(c.state.phase, isNot(WorkoutPlayerPhase.work),
        reason: 'a delayed tick past the deadline must finish the phase');
  });

  test('pause never advances the countdown; resume stays accurate', () {
    final c = controller();
    addTearDown(c.dispose);

    c.beginWorkout();
    final initial = c.state.remaining;
    clock.advance(const Duration(seconds: 2));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 2));

    c.pause();
    expect(c.hasActiveTimer, isFalse, reason: 'pause cancels the timer');

    // Time passes while intentionally paused: nothing may advance.
    clock.advance(const Duration(seconds: 30));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 2),
        reason: 'paused countdown must not advance');

    c.resume();
    expect(c.hasActiveTimer, isTrue, reason: 'resume restarts exactly one '
        'timer');
    clock.advance(const Duration(seconds: 1));
    c.tick();
    expect(c.state.remaining, initial - const Duration(seconds: 3));
  });

  test('repeated pause/resume cycles never leave duplicate timers', () {
    final c = controller();
    addTearDown(c.dispose);

    c.beginWorkout();
    for (var i = 0; i < 6; i++) {
      c.pause();
      expect(c.hasActiveTimer, isFalse);
      c.resume();
      expect(c.hasActiveTimer, isTrue);
      // Idempotent repeat calls must not create extra timers or advance.
      c.resume();
      c.pause();
      c.pause();
      c.resume();
      clock.advance(const Duration(seconds: 1));
      c.tick();
    }
    // Exactly 6 counted seconds of countdown survived the cycles.
    expect(c.hasActiveTimer, isTrue);
  });

  test('zero-rest set progression never spins a timer', () {
    final zeroRestPlan = buildPlan(mainRest: Duration.zero);
    final c = controller(plan: zeroRestPlan);
    addTearDown(c.dispose);

    // Timed warm-up (45s): run it to completion via the deadline path.
    c.beginWorkout();
    clock.advance(const Duration(seconds: 50));
    c.tick();
    expect(c.state.phase, WorkoutPlayerPhase.sectionBreak,
        reason: 'the single warm-up exercise ends the section');
    expect(c.hasActiveTimer, isFalse,
        reason: 'section breaks never run a countdown timer');

    // Advance into the reps-based main exercise.
    c.continueSection();
    expect(c.state.phase, WorkoutPlayerPhase.work);
    expect(c.state.setNumber, 1);
    expect(c.hasActiveTimer, isFalse,
        reason: 'reps-based work phases never run a countdown timer');

    c.completeSet();
    expect(c.state.setNumber, 2,
        reason: 'zero rest must progress directly to the next set');
    expect(c.state.phase, WorkoutPlayerPhase.work);
    expect(c.hasActiveTimer, isFalse,
        reason: 'zero-duration rest must not spin a timer');
  });

  test('dispose cancels the timer and stops voice', () {
    final coach = FakeWorkoutCoach();
    final c = controller(coach: coach);

    c.beginWorkout();
    expect(c.hasActiveTimer, isTrue);

    c.dispose();
    expect(c.hasActiveTimer, isFalse, reason: 'dispose must cancel the '
        'timer');
    expect(coach.stopCalls, greaterThan(0),
        reason: 'dispose must stop pending speech');

    // Ticks after disposal are no-ops and must not throw.
    clock.advance(const Duration(seconds: 10));
    c.tick();
  });

  test('ticks never repeat voice cues during an active countdown', () {
    final coach = FakeWorkoutCoach();
    final c = controller(coach: coach);
    addTearDown(c.dispose);

    c.beginWorkout();
    final cuesAfterStart = coach.spoken.length;
    expect(cuesAfterStart, greaterThan(0),
        reason: 'phase start announces once');

    // Several steady countdown ticks must not add any speech.
    for (var i = 0; i < 5; i++) {
      clock.advance(const Duration(seconds: 1));
      c.tick();
    }
    expect(coach.spoken.length, cuesAfterStart,
        reason: 'no voice request is allowed per tick');
  });
}

/// Shared fake monotonic clock advanced manually by tests.
class _FakeClock {
  Duration now = Duration.zero;

  void advance(Duration duration) {
    now += duration;
  }

  void reset() {
    now = Duration.zero;
  }
}

/// Faithful fake of [Stopwatch]: each instance measures elapsed time from
/// its own start, exactly like production, but against a [_FakeClock].
class _FakeStopwatch implements Stopwatch {
  _FakeStopwatch(this._clock);

  final _FakeClock _clock;
  Duration _startedAt = Duration.zero;
  Duration _accumulated = Duration.zero;
  bool _running = false;

  @override
  Duration get elapsed =>
      _running ? _accumulated + (_clock.now - _startedAt) : _accumulated;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMicroseconds;

  @override
  int get frequency => 1000000;

  @override
  bool get isRunning => _running;

  @override
  void start() {
    if (!_running) {
      _running = true;
      _startedAt = _clock.now;
    }
  }

  @override
  void stop() {
    if (_running) {
      _accumulated += _clock.now - _startedAt;
      _running = false;
    }
  }

  @override
  void reset() {
    _accumulated = Duration.zero;
    _startedAt = _clock.now;
  }
}
