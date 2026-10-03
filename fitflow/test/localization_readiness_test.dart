import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/features/backup/data/backup_codec.dart';
import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/presentation/widgets/workout_reminders_section.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/workout_player/domain/workout_session_origin.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_session_view.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_plan.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_section_type.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_time_budget.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_filter.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';
import 'helpers/backup_test_helpers.dart';
import 'helpers/workout_reminder_test_helpers.dart';

WorkoutPlan _plan() {
  WorkoutExercisePrescription timed(String id) {
    final base = WorkoutExercisePrescription.fromExerciseDefaults(
      ExerciseCatalog.byId(id)!,
    )!;
    return WorkoutExercisePrescription(
      exercise: base.exercise,
      sets: 1,
      repsPerSet: null,
      workDuration: const Duration(seconds: 20),
      restBetweenSets: const Duration(seconds: 10),
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

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Widget home,
  Locale? locale,
  bool rtl = false,
  bool alwaysUse24HourFormat = false,
  double textScale = 1,
  List<Override> overrides = const [],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) {
          final media = MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: alwaysUse24HourFormat,
            textScaler: TextScaler.linear(textScale),
          );
          final content = MediaQuery(data: media, child: child!);
          if (!rtl) return content;
          return Directionality(
            textDirection: TextDirection.rtl,
            child: content,
          );
        },
        home: home,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ensureTimezones();
  });

  group('supported locale', () {
    test('English is the only declared UI locale', () {
      expect(AppLocalizations.supportedLocales, [const Locale('en')]);
      expect(
        AppLocalizations.localizationsDelegates,
        containsAll([
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ]),
      );
      expect(BackupFormat.schemaVersion, 1);
      expect(
        BackupFormat.sections.any((section) => section.toLowerCase().contains('locale')),
        isFalse,
      );
    });

    test('lookup refuses locales that are not fully translated', () {
      for (final locale in const [
        Locale('ur', 'PK'),
        Locale('ar', 'SA'),
        Locale('ja', 'JP'),
      ]) {
        expect(
          () => lookupAppLocalizations(locale),
          throwsA(isA<FlutterError>()),
        );
        expect(AppLocalizations.delegate.isSupported(locale), isFalse);
      }
      expect(lookupAppLocalizations(const Locale('en')).appTitle, 'FitFlow');
    });

    testWidgets('unsupported system locales fall back to English', (tester) async {
      for (final locale in const [
        Locale('ur', 'PK'),
        Locale('ar', 'SA'),
        Locale('ja', 'JP'),
      ]) {
        await _pumpLocalized(
          tester,
          locale: locale,
          home: Builder(
            builder: (context) => Text(context.l10n.beginWorkout),
          ),
        );
        expect(find.text('Begin workout'), findsOneWidget);
        final context = tester.element(find.text('Begin workout'));
        expect(Localizations.localeOf(context), const Locale('en'));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('dates, weekdays, and time', () {
    test('display order follows first-day-of-week without renumbering ISO days', () {
      expect(
        FitFlowLocaleFormat.weekdayDisplayOrder(0),
        [DateTime.sunday, 1, 2, 3, 4, 5, 6],
      );
      expect(
        FitFlowLocaleFormat.weekdayDisplayOrder(1),
        [1, 2, 3, 4, 5, 6, DateTime.sunday],
      );
    });

    testWidgets('English reminder chips are Sunday-first and stored days stay ISO',
        (tester) async {
      final service = FakeWorkoutReminderNotificationService();
      final stored = WorkoutReminderPreferences(
        enabled: false,
        weekdays: const {1, 3, 5},
        time: const WorkoutReminderTime(hour: 19, minute: 0),
      );
      await _pumpLocalized(
        tester,
        overrides: reminderOverrides(service: service),
        size: const Size(390, 1200),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    Text(WorkoutRemindersSection.scheduleSummary(context, stored)),
                    const WorkoutRemindersSection(),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Mon, Wed, Fri • 7:00 PM'), findsWidgets);
      expect(stored.weekdays, {1, 3, 5});
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(
        chips.map((chip) => (chip.key! as ValueKey<String>).value).toList(),
        [
          'reminder_weekday_7',
          'reminder_weekday_1',
          'reminder_weekday_2',
          'reminder_weekday_3',
          'reminder_weekday_4',
          'reminder_weekday_5',
          'reminder_weekday_6',
        ],
      );
      expect(tester.widget<FilterChip>(find.byKey(const ValueKey('reminder_weekday_1'))).selected, isTrue);
      expect(tester.widget<FilterChip>(find.byKey(const ValueKey('reminder_weekday_7'))).selected, isFalse);
    });

    testWidgets('12-hour and 24-hour clocks format the same stored time', (tester) async {
      Future<void> expectTime(bool use24h, String expected) async {
        await _pumpLocalized(
          tester,
          alwaysUse24HourFormat: use24h,
          home: Builder(
            builder: (context) => Text(
              FitFlowLocaleFormat.formatReminderTime(context, 19, 0),
            ),
          ),
        );
        expect(find.text(expected), findsOneWidget);
      }

      await expectTime(false, '7:00 PM');
      await expectTime(true, '19:00');
    });

    test('enum adapters match current English labels and do not live on the enum', () {
      final l10n = englishAppLocalizations();
      expect(fitnessGoalLabel(l10n, FitnessGoal.generalFitness), 'General fitness');
      expect(difficultyLabel(l10n, ExerciseDifficulty.level3), 'Level 3');
      expect(l10n.minutes(1), '1 minute');
      expect(l10n.minutes(10), '10 minutes');
      expect(FitFlowLocaleFormat.formatWorkoutDelta(l10n, 2), '+2 workouts');
      expect(FitFlowLocaleFormat.formatWorkoutDelta(l10n, -1), '-1 workout');
      expect(FitFlowLocaleFormat.formatWorkoutDelta(l10n, 0), 'No change');
    });
  });

  group('unicode', () {
    const name = 'تمرین 💪 训练 — café';

    test('custom workout names round-trip through backup bytes', () {
      final original = fullBackupData();
      expect(original.customWorkouts, isNotEmpty);
      final unicode = original.copyWith(
        customWorkouts: [
          original.customWorkouts.first.copyWith(name: name),
          ...original.customWorkouts.skip(1),
        ],
      );
      final decoded = BackupCodec.decode(BackupCodec.encode(envelopeOf(unicode)));
      expect(decoded.isSuccess, isTrue, reason: decoded.detail);
      expect(decoded.envelope!.data.customWorkouts.first.name, name);
      expect(decoded.envelope!.data.customWorkouts.first.id, original.customWorkouts.first.id);
    });

    test('unicode and pattern-like search queries do not throw', () {
      const queries = [
        'تمرین',
        'ورزش',
        '训练',
        'ワークアウト',
        '💪',
        'café',
        'a\u0301',
        '(.*+?',
        'squat',
      ];
      for (final query in queries) {
        expect(
          () => applyExerciseLibraryFilter(
            ExerciseCatalog.all,
            ExerciseLibraryFilter(searchQuery: query),
          ),
          returnsNormally,
        );
      }
      final squat = applyExerciseLibraryFilter(
        ExerciseCatalog.all,
        const ExerciseLibraryFilter(searchQuery: 'squat'),
      );
      expect(squat, isNotEmpty);
    });
  });

  group('RTL and English text scale', () {
    testWidgets('shell screens render in RTL without throwing', (tester) async {
      final reminders = FakeWorkoutReminderNotificationService();
      final screens = <String, Widget>{
        'onboarding': const OnboardingScreen(),
        'home': const HomeScreen(),
        'preview': const WorkoutPreviewScreen(),
        'player': WorkoutPlayerSessionView(
          plan: _plan(),
          sessionMode: WorkoutSessionMode.standard,
          sessionOrigin: WorkoutSessionOrigin.adaptive,
        ),
        'library': const ExerciseLibraryScreen(),
        'program': ProgramDetailScreen(
          programId: AdaptiveProgramCatalog.balancedFoundationsId,
        ),
        'profile': const ProfileScreen(),
        'settings': const SettingsScreen(),
        'backup': const BackupRestoreScreen(),
      };

      for (final entry in screens.entries) {
        await _pumpLocalized(
          tester,
          rtl: true,
          size: const Size(320, 700),
          textScale: entry.key == 'home' ? 2 : 1,
          overrides: [
            ...programOverrides(),
            ...reminderOverrides(service: reminders),
          ],
          home: entry.value,
        );
        expect(tester.takeException(), isNull, reason: entry.key);
        expect(
          tester
              .widgetList<Directionality>(find.byType(Directionality))
              .any((direction) => direction.textDirection == TextDirection.rtl),
          isTrue,
          reason: entry.key,
        );
      }
    });

    testWidgets('localized English stays readable at text scale 2', (tester) async {
      await _pumpLocalized(
        tester,
        textScale: 2,
        size: const Size(320, 700),
        overrides: programOverrides(),
        home: const HomeScreen(),
      );
      expect(find.text('View workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
