import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/state/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/profile_editor_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reviewing setup seeds a draft without modifying saved data', () async {
    final profile = profileEditorSeed();
    final saved = {...seedProfilePrefs(profile), 'history_sentinel': 'retained'};
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(onboardingControllerProvider.notifier);

    controller.reviewProfile(profile);
    final draft = container.read(onboardingControllerProvider);
    expect(draft.hasRequiredProfileFields, isTrue);
    expect(draft.goal, profile.goal);
    expect(draft.experience, profile.experience);
    expect(draft.environment, profile.environment);
    expect(draft.workoutDuration, profile.workoutDuration);
    expect(draft.equipment, profile.equipment);
    expect(draft.preferences, profile.preferences);

    controller.selectGoal(FitnessGoal.generalFitness);
    expect(container.read(onboardingControllerProvider).goal,
        FitnessGoal.generalFitness);
    expect(profile.goal, FitnessGoal.buildStrength);
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, saved);
  });
}
