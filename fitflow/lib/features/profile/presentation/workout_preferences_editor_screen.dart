import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/widgets/profile_editor_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Editor for optional workout preferences (user preferences, never medical
/// advice). An empty selection is valid and can be saved.
class WorkoutPreferencesEditorScreen extends ConsumerStatefulWidget {
  const WorkoutPreferencesEditorScreen({super.key});

  static const String successMessage = 'Workout preferences updated.';

  @override
  ConsumerState<WorkoutPreferencesEditorScreen> createState() =>
      _WorkoutPreferencesEditorScreenState();
}

class _WorkoutPreferencesEditorScreenState
    extends ConsumerState<WorkoutPreferencesEditorScreen> {
  /// Persisted profile the draft was started from.
  UserFitnessProfile? _baseline;

  /// Current in-progress draft; never persisted until an explicit save.
  UserFitnessProfile? _draft;

  bool _saving = false;

  bool get _hasUnsavedChanges {
    final draft = _draft;
    final baseline = _baseline;
    return draft != null && baseline != null && draft != baseline;
  }

  void _togglePreference(WorkoutPreference preference) {
    setState(() {
      final updated = {..._draft!.preferences};
      if (!updated.remove(preference)) {
        updated.add(preference);
      }
      _draft = _draft!.copyWith(preferences: updated);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = _draft;
    if (draft == null || !_hasUnsavedChanges) return;

    setState(() => _saving = true);
    final saved = await ref
        .read(userFitnessProfileProvider.notifier)
        .saveProfile(draft);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? WorkoutPreferencesEditorScreen.successMessage
                : profileEditorSaveFailedMessage,
          ),
        ),
      );

    if (saved) {
      setState(() {
        _baseline = draft;
        _draft = draft;
        _saving = false;
      });
      if (mounted) {
        context.pop();
      }
    } else {
      // Stay on screen; the old persisted profile remains authoritative.
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userFitnessProfileProvider);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        confirmDiscardEditorChanges(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Workout preferences')),
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text("Your workout preferences couldn't be loaded."),
            ),
            data: (profile) {
              if (profile == null) {
                return const Center(
                  child: Text('Fitness profile not set up'),
                );
              }
              _baseline ??= profile;
              _draft ??= profile;
              final draft = _draft!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FitFlow uses these preferences when choosing exercises.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final preference in WorkoutPreference.values)
                          OnboardingOptionCard(
                            label: preference.label,
                            multiSelect: true,
                            selected: draft.preferences.contains(preference),
                            onSelected: () => _togglePreference(preference),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: _draft == null
            ? null
            : ProfileEditorSaveBar(
                enabled: _hasUnsavedChanges,
                saving: _saving,
                onSave: _save,
              ),
      ),
    );
  }
}
