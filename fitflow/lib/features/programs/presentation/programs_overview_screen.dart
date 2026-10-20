import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// V2 discovery for the same five built-in programs. Only their presentation
/// order changes when a real active program leads; it is not listed twice.
class ProgramsOverviewScreen extends ConsumerWidget {
  const ProgramsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    final l = context.l10n;
    final goal = ref.watch(userFitnessProfileProvider).value?.goal;
    final programsAsync = ref.watch(adaptiveProgramsControllerProvider);
    if (programsAsync.isLoading || programsAsync.hasError) {
      return Scaffold(
        backgroundColor: v.page,
        appBar: AppBar(title: Text(l.trainingPrograms)),
        body: ProgramProgressState(
          loading: programsAsync.isLoading,
          onRetry: () =>
              ref.read(adaptiveProgramsControllerProvider.notifier).refresh(),
        ),
      );
    }
    final programsState = programsAsync.value ?? AdaptiveProgramsState.empty;
    final active = AdaptiveProgramCatalog.byId(programsState.activeProgramId);
    final remaining = AdaptiveProgramCatalog.all
        .where((definition) => definition.id != active?.id)
        .toList(growable: false);

    Widget card(AdaptiveProgramDefinition definition) {
      final status = AdaptiveProgramStatus(
        definition: definition,
        progress: programsState.progressFor(definition.id),
      );
      final isActive = programsState.isActive(definition.id);
      return _ProgramOverviewCard(
        key: ValueKey('v2_program_card_${definition.id}'),
        definition: definition,
        isRecommended: AdaptiveProgramRecommendationPolicy.isRecommended(
            definition.id, goal),
        isActive: isActive,
        status: status,
        onTap: () => context.push(AppRoutes.programDetail(definition.id)),
        // Same continuation route and canonical first-incomplete session used
        // by the existing active-program entry and detail; never generate here.
        onContinue: isActive && status.nextSession != null
            ? () => context.push(AppRoutes.programSessionPreview(
                definition.id, status.nextSession!.id))
            : null,
      );
    }

    return Scaffold(
      backgroundColor: v.page,
      appBar: AppBar(
        title: Text(l.trainingPrograms,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
        backgroundColor: v.page,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: FitFlowLayout.maxContentWidth),
            child: ListView(
              padding: EdgeInsets.all(ProgramV2Layout.inset(context)),
              children: [
                Text(l.trainingProgramOverviewIntro,
                    key: const Key('v2_programs_header'),
                    style: text.bodyMedium?.copyWith(color: t.textSecondary)),
                const SizedBox(height: FitFlowSpace.sm),
                for (final definition in [
                  if (active != null) active,
                  ...remaining
                ]) ...[
                  card(definition),
                  Divider(height: 1, color: v.subtleBorder),
                ],
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
    super.key,
    required this.definition,
    required this.isRecommended,
    required this.isActive,
    required this.status,
    required this.onTap,
    this.onContinue,
  });

  final AdaptiveProgramDefinition definition;
  final bool isRecommended;
  final bool isActive;
  final AdaptiveProgramStatus status;
  final VoidCallback onTap;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    final imageWidth = ProgramV2Layout.viewport(context).width < 360 ||
            ProgramV2Layout.largeText(context)
        ? 80.0
        : 112.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            child: InkWell(
              key: ValueKey('v2_program_link_${definition.id}'),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FitFlowProgramImage(
                      programId: definition.id,
                      width: imageWidth,
                      height: imageWidth * 3 / 4,
                    ),
                    const SizedBox(width: FitFlowSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(definition.name,
                                style: text.titleMedium?.copyWith(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: FitFlowSpace.xxs),
                          Text(definition.focus,
                              style: text.bodyMedium
                                  ?.copyWith(color: t.textSecondary)),
                          const SizedBox(height: FitFlowSpace.xs),
                          ProgramStructureLine(definition: definition),
                          if (isActive) ...[
                            const SizedBox(height: FitFlowSpace.xs),
                            Text(context.l10n.trainingProgramActiveTitle,
                                style:
                                    text.bodySmall?.copyWith(color: t.brand)),
                          ],
                          if (isRecommended) ...[
                            const SizedBox(height: FitFlowSpace.xxs),
                            Text(context.l10n.trainingProgramRecommendedMatch,
                                style: text.bodySmall
                                    ?.copyWith(color: t.textSecondary)),
                          ],
                          if (!isActive && !status.hasProgress) ...[
                            const SizedBox(height: FitFlowSpace.xs),
                            Text(programStatusLabel(context, status),
                                style: text.bodySmall
                                    ?.copyWith(color: t.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: FitFlowSpace.xxs),
                    ExcludeSemantics(
                        child: Icon(Icons.chevron_right,
                            color: t.textSecondary, size: 20)),
                  ],
                ),
              ),
            ),
          ),
          if (isActive || status.hasProgress) ...[
            const SizedBox(height: FitFlowSpace.sm),
            ProgramV2ProgressSummary(
                status: status, showNext: isActive, compact: true),
          ],
          if (onContinue != null) ...[
            const SizedBox(height: FitFlowSpace.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: v.action,
                  foregroundColor: v.onAction,
                  minimumSize: const Size(64, 48),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(context.l10n.trainingProgramContinueLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
