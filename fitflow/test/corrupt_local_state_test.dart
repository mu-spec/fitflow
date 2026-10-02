import 'package:fitflow/app/app.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile_storage.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/reminders/data/workout_reminder_storage.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Each store keeps its own safe fallback. Loading must not crash and must
/// not overwrite the corrupt bytes just because they could not be parsed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const corrupt = '{not-json';

  test('malformed persisted values follow each storage fallback', () async {
    SharedPreferences.setMockInitialValues({
      UserFitnessProfileStorage.profileKey: corrupt,
      CapabilityProfileStorage.profileKey: '[]',
      AdaptiveProgressionEvidenceStorage.evidenceKey: 'nope',
      WorkoutHistoryStorage.key: '{"id":1}',
      CustomWorkoutStorage.key: '{"templates":true}',
      AdaptiveProgramsStorage.key: '[]',
      WorkoutReminderStorage.key: 'true',
      AppearanceStorage.appearanceKey: 'neon',
    });
    final prefs = await SharedPreferences.getInstance();
    final before = {
      for (final key in prefs.getKeys()) key: prefs.getString(key),
    };

    expect(UserFitnessProfileStorage(prefs).load(), isNull);
    expect(CapabilityProfileStorage(prefs).load(), isNull);
    expect(
      AdaptiveProgressionEvidenceStorage(prefs).load(),
      AdaptiveProgressionEvidence.zero(),
    );
    expect(WorkoutHistoryStorage(prefs).load(), isEmpty);
    expect(await const CustomWorkoutStorage().loadAll(), isEmpty);
    expect(await const AdaptiveProgramsStorage().load(), isNotNull);
    expect(
      (await const AdaptiveProgramsStorage().load()).activeProgramId,
      isNull,
    );
    expect(
      await const WorkoutReminderStorage().load(),
      WorkoutReminderPreferences.defaults,
    );
    expect(
      await AppearanceStorage(prefs).load(),
      isNotNull,
    );

    final after = {
      for (final key in prefs.getKeys()) key: prefs.getString(key),
    };
    expect(after, before);
  });

  testWidgets('corrupt startup data does not crash or auto-repair',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      UserFitnessProfileStorage.profileKey: corrupt,
      CapabilityProfileStorage.profileKey: corrupt,
      AdaptiveProgressionEvidenceStorage.evidenceKey: corrupt,
      WorkoutHistoryStorage.key: corrupt,
      CustomWorkoutStorage.key: corrupt,
      AdaptiveProgramsStorage.key: corrupt,
      WorkoutReminderStorage.key: corrupt,
      AppearanceStorage.appearanceKey: 'not-a-mode',
    });
    final prefs = await SharedPreferences.getInstance();
    final before = {
      for (final key in prefs.getKeys()) key: prefs.getString(key),
    };

    await tester.pumpWidget(const ProviderScope(child: FitFlowApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome to FitFlow'), findsOneWidget);
    final after = {
      for (final key in prefs.getKeys()) key: prefs.getString(key),
    };
    expect(after, before);
  });
}
