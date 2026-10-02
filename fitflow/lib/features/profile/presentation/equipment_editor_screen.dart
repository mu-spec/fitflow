import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_option_card.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/widgets/profile_editor_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Editor for the equipment the user has available.
///
/// Uses the same selection rules as onboarding: `None` is exclusive, real
/// equipment removes `None`, and the selection is never empty — deselecting
/// the final real item automatically falls back to `None`.
class EquipmentEditorScreen extends ConsumerStatefulWidget {
  const EquipmentEditorScreen({super.key});

  static const String successMessage = 'Equipment updated.';

  @override
  ConsumerState<EquipmentEditorScreen> createState() =>
      _EquipmentEditorScreenState();
}

class _EquipmentEditorScreenState extends ConsumerState<EquipmentEditorScreen> {
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

  void _toggleEquipment(WorkoutEquipment item) {
    setState(() {
      final current = _draft!.equipment;
      final Set<WorkoutEquipment> updated;
      if (item == WorkoutEquipment.none) {
        // Selecting None clears every other item.
        updated = {WorkoutEquipment.none};
      } else {
        final next = {...current}..remove(WorkoutEquipment.none);
        if (!next.remove(item)) {
          next.add(item);
        }
        if (next.isEmpty) {
          // Deselecting the final real item falls back to None so the
          // persisted equipment set is never empty.
          next.add(WorkoutEquipment.none);
        }
        updated = next;
      }
      _draft = _draft!.copyWith(equipment: updated);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = _draft;
    if (draft == null || !_hasUnsavedChanges) return;
    // The toggle rules guarantee equipment is never empty; keep the guard so
    // an empty set can never be persisted.
    if (draft.equipment.isEmpty) return;

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
                ? EquipmentEditorScreen.successMessage
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
        appBar: AppBar(title: const Text('Equipment')),
        body: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: Text("Your equipment couldn't be loaded."),
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
                          'Choose the equipment you currently have available.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final equipment in WorkoutEquipment.values)
                          OnboardingOptionCard(
                            label: equipment.label,
                            multiSelect: true,
                            selected: draft.equipment.contains(equipment),
                            onSelected: () => _toggleEquipment(equipment),
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
