import 'package:fitflow/app/config/app_dimensions.dart';
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

/// Lists all five built-in adaptive programs.
class ProgramsOverviewScreen extends ConsumerWidget {
  const ProgramsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goal = ref.watch(userFitnessProfileProvider).value?.goal;
    final programsState = ref.watch(adaptiveProgramsControllerProvider).value ??
        AdaptiveProgramsState.empty;

    return Scaffold(
      appBar: AppBar(title: const Text(ProgramCopy.overviewTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: [
                Text(
                  ProgramCopy.overviewIntro,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                for (final def in AdaptiveProgramCatalog.all)
                  _ProgramOverviewCard(
                    definition: def,
                    isRecommended: AdaptiveProgramRecommendationPolicy
                        .isRecommended(def.id, goal),
                    isActive: programsState.isActive(def.id),
                    status: AdaptiveProgramStatus(
                      definition: def,
                      progress: programsState.progressFor(def.id),
                    ),
                    onTap: () =>
                        context.push(AppRoutes.programDetail(def.id)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramOverviewCard extends StatelessWidget {
  const _ProgramOverviewCard({
    required this.definition,
    required this.isRecommended,
    required this.isActive,
    required this.status,
    required this.onTap,
  });

  final AdaptiveProgramDefinition definition;
  final bool isRecommended;
  final bool isActive;
  final AdaptiveProgramStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(definition.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(definition.focus,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 6),
              ProgramStructureLine(definition: definition),
              if (isRecommended || isActive || status.hasProgress) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
                      ),
                    if (status.hasProgress)
                      ProgramTag(
                        label: ProgramCopy.completedShort(
                            status.completedCount, status.totalCount),
                        icon: Icons.check_circle_outline,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
