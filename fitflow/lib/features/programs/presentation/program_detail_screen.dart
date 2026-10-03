import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_copy.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Program detail: structure, factual progress, week groups and actions.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = AdaptiveProgramCatalog.byId(programId);
    if (definition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(ProgramCopy.programNotFound)),
        body: const ProgramNotFoundBody(
          title: ProgramCopy.programNotFound,
          body: ProgramCopy.programNotFoundBody,
        ),
      );
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final goal = ref.watch(userFitnessProfileProvider).value?.goal;
    final programsAsync = ref.watch(adaptiveProgramsControllerProvider);
    final programsState = programsAsync.value ?? AdaptiveProgramsState.empty;
    final status = AdaptiveProgramStatus(
      definition: definition,
      progress: programsState.progressFor(definition.id),
    );
    final isActive = programsState.isActive(definition.id);
    final isRecommended =
        AdaptiveProgramRecommendationPolicy.isRecommended(definition.id, goal);
    final otherActive = programsState.activeProgramId != null && !isActive;

    return Scaffold(
      appBar: AppBar(title: Text(definition.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: [
                Text(definition.description,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ProgramTag(
                        label: ProgramCopy.weeksLabel(definition.weekCount),
                        icon: Icons.calendar_view_week_outlined),
                    ProgramTag(
                        label: ProgramCopy.perWeekLabel(
                            definition.sessionsPerWeek),
                        icon: Icons.repeat),
                    ProgramTag(
                        label: ProgramCopy.totalLabel(
                            definition.totalSessionCount),
                        icon: Icons.fitness_center_outlined),
                    if (isRecommended)
                      const ProgramTag(
                        label: ProgramCopy.recommendedMatch,
                        icon: Icons.flag_outlined,
                        emphasized: true,
                      ),
                    if (isActive)
                      const ProgramTag(
                        label: ProgramCopy.activeTitle,
                        icon: Icons.play_circle_outline,
                        emphasized: true,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (status.hasProgress) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (status.isComplete) ...[
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: colors.primary),
                                const SizedBox(width: 8),
                                Text(ProgramCopy.programComplete,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          ProgramCompletionBar(status: status),
                          if (!status.isComplete &&
                              status.nextSession != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${ProgramCopy.weekLabel(status.currentWeek)} • Next: ${status.nextSession!.title}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _ProgramActions(
                  definition: definition,
                  status: status,
                  isActive: isActive,
                  otherActive: otherActive,
                ),
                const SizedBox(height: 24),
                for (final week in definition.weeks) ...[
                  Text(ProgramCopy.weekLabel(week.number),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final session in week.sessions)
                    ProgramSessionRow(
                      session: session,
                      status: status.statusOf(session),
                      onView: () => context.push(
                        AppRoutes.programSessionPreview(
                            definition.id, session.id),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramActions extends ConsumerWidget {
  const _ProgramActions({
    required this.definition,
    required this.status,
    required this.isActive,
    required this.otherActive,
  });

  final AdaptiveProgramDefinition definition;
  final AdaptiveProgramStatus status;
  final bool isActive;
  final bool otherActive;

  Future<void> _showFailure(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ProgramCopy.actionFailed)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(adaptiveProgramsControllerProvider.notifier);
    final buttons = <Widget>[];

    if (isActive) {
      final next = status.nextSession;
      if (next != null) {
        buttons.add(FilledButton.icon(
          onPressed: () => context.push(
              AppRoutes.programSessionPreview(definition.id, next.id)),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text(ProgramCopy.continueLabel),
        ));
      }
    } else if (otherActive) {
      buttons.add(FilledButton.icon(
        onPressed: () async {
          final confirmed = await ProgramDialogs.confirmSwitch(context);
          if (!confirmed) return;
          final ok = await controller.switchActiveProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(ProgramCopy.switchProgram),
      ));
    } else {
      buttons.add(FilledButton.icon(
        onPressed: () async {
          final ok = await controller.startOrResumeProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: Icon(status.hasProgress
            ? Icons.play_arrow_rounded
            : Icons.play_circle_outline),
        label: Text(status.hasProgress
            ? ProgramCopy.resumeProgram
            : context.l10n.programStart),
      ));
    }

    if (status.hasProgress) {
      buttons.add(OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await ProgramDialogs.confirmRestart(context);
          if (!confirmed) return;
          final ok = await controller.restartProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text(ProgramCopy.restartProgram),
      ));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}
