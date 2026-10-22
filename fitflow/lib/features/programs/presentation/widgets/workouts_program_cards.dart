import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Real "Programs" entry row on the Workouts screen.
class ProgramsEntryRow extends StatelessWidget {
  const ProgramsEntryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          onTap: () => context.push(AppRoutes.programs),
          leading: const Icon(Icons.calendar_view_week_outlined),
          title: Text(context.l10n.trainingProgramEntryTitle),
          subtitle: Text(
            context.l10n.trainingProgramEntrySubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Icon(Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Recommended program card driven by the saved profile goal.
class RecommendedProgramCard extends ConsumerWidget {
  const RecommendedProgramCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profileAsync = ref.watch(userFitnessProfileProvider);
    final profile = profileAsync.value;

    if (profileAsync.isLoading) {
      return const SizedBox.shrink();
    }

    if (profile == null) {
      return Card(
        margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.trainingProgramRecommendedTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(context.l10n.trainingProgramRecommendedMissingProfile,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final def =
        AdaptiveProgramRecommendationPolicy.recommendedFor(profile.goal);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.trainingProgramRecommendedTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(def.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.trainingProgramWeeks(def.weekCount)} • ${context.l10n.trainingProgramPerWeek(def.sessionsPerWeek)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ProgramTag(
              label: context.l10n.trainingProgramRecommendedMatch,
              icon: Icons.flag_outlined,
              emphasized: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.programDetail(def.id)),
              child: Text(context.l10n.trainingProgramViewProgram),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hub-only continuation with factual status and the exact registered cover.
/// Renders nothing when no program is active.
class ActiveProgramCard extends ConsumerWidget {
  const ActiveProgramCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    final stateAsync = ref.watch(adaptiveProgramsControllerProvider);
    final state = stateAsync.value;
    if (state == null) return const SizedBox.shrink();
    final activeId = state.activeProgramId;
    final def = AdaptiveProgramCatalog.byId(activeId);
    if (activeId == null || def == null) return const SizedBox.shrink();

    final status = AdaptiveProgramStatus(
      definition: def,
      progress: state.progressFor(activeId),
    );
    final next = status.nextSession;

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.trainingProgramActiveTitle,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.brand,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: FitFlowSpace.xs),
        Text(def.name, style: theme.textTheme.titleMedium),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          context.l10n
              .trainingSessions(status.completedCount, status.totalCount),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          status.isComplete
              ? context.l10n.trainingProgramProgramComplete
              : context.l10n.trainingNextSession(status.currentWeek,
                  context.l10n.trainingSession(next!.session)),
          style:
              theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
      child: Container(
        padding: const EdgeInsets.all(FitFlowSpace.sm),
        decoration: BoxDecoration(
          color: colors.palette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              // Artwork yields space to text; the text never shrinks.
              final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
              final artSize = largeText ? 64.0 : 88.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: artSize,
                    height: artSize * 3 / 4,
                    child: Center(
                      child: FitFlowProgramImage(
                        programId: def.id,
                        width: artSize,
                        height: artSize * 3 / 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: FitFlowSpace.sm),
                  Expanded(child: texts),
                ],
              );
            }),
            const SizedBox(height: FitFlowSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: () {
                  if (next != null) {
                    context
                        .push(AppRoutes.programSessionPreview(def.id, next.id));
                  } else {
                    context.push(AppRoutes.programDetail(def.id));
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(next == null
                    ? context.l10n.trainingProgramViewProgram
                    : context.l10n.trainingProgramContinueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
