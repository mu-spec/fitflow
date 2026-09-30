import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/presentation/program_copy.dart';
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
          title: const Text(ProgramCopy.entryTitle),
          subtitle: Text(
            ProgramCopy.entrySubtitle,
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
              Text(ProgramCopy.recommendedTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(ProgramCopy.recommendedMissingProfile,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final def = AdaptiveProgramRecommendationPolicy.recommendedFor(profile.goal);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ProgramCopy.recommendedTitle,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(def.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${ProgramCopy.weeksLabel(def.weekCount)} • ${ProgramCopy.perWeekLabel(def.sessionsPerWeek)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            const ProgramTag(
              label: ProgramCopy.recommendedMatch,
              icon: Icons.flag_outlined,
              emphasized: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.programDetail(def.id)),
              child: const Text(ProgramCopy.viewProgram),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active program card: factual completion and the next planned session.
/// Renders nothing when no program is active.
class ActiveProgramCard extends ConsumerWidget {
  const ActiveProgramCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ProgramCopy.activeTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                )),
            const SizedBox(height: 6),
            Text(def.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Text(
              ProgramCopy.completedShort(
                  status.completedCount, status.totalCount),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              status.isComplete
                  ? ProgramCopy.programComplete
                  : '${ProgramCopy.weekLabel(status.currentWeek)} • Next: ${next!.title} — ${next.focus}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                if (next != null) {
                  context.push(
                      AppRoutes.programSessionPreview(def.id, next.id));
                } else {
                  context.push(AppRoutes.programDetail(def.id));
                }
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(ProgramCopy.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
