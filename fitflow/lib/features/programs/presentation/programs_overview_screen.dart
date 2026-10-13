import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_program_cover.dart';
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
        appBar: AppBar(title: Text(l.trainingProgramOverviewTitle)),
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
    final two = ProgramV2Layout.twoColumns(context);

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
        title: Text(l.trainingPrograms),
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
                Column(
                  key: const Key('v2_programs_header'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeBrand,
                        style: text.labelMedium
                            ?.copyWith(color: t.brand, letterSpacing: 1.2)),
                    const SizedBox(height: FitFlowSpace.xs),
                    Semantics(
                      header: true,
                      child: Text(l.trainingProgramOverviewTitle,
                          style: text.headlineMedium),
                    ),
                    const SizedBox(height: FitFlowSpace.sm),
                    Text(l.trainingProgramOverviewIntro,
                        style:
                            text.bodyLarge?.copyWith(color: t.textSecondary)),
                  ],
                ),
                const SizedBox(height: FitFlowSpace.lg),
                if (active != null) ...[
                  card(active),
                  const SizedBox(height: FitFlowSpace.lg),
                ],
                for (var i = 0; i < remaining.length; i += two ? 2 : 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FitFlowSpace.md),
                    child: two
                        ? LayoutBuilder(builder: (context, c) {
                            // A wide window may still host a narrower route
                            // pane. This is a local row builder, not a root
                            // route LayoutBuilder that could disturb dialogs.
                            final readable = c.maxWidth >=
                                2 * ProgramV2Layout.minimumCardWidth +
                                    FitFlowSpace.md;
                            if (!readable) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  card(remaining[i]),
                                  if (i + 1 < remaining.length) ...[
                                    const SizedBox(height: FitFlowSpace.md),
                                    card(remaining[i + 1]),
                                  ],
                                ],
                              );
                            }
                            return Row(
                              key: ValueKey('v2_programs_pair_$i'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: card(remaining[i])),
                                const SizedBox(width: FitFlowSpace.md),
                                Expanded(
                                  child: i + 1 < remaining.length
                                      ? card(remaining[i + 1])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            );
                          })
                        : card(remaining[i]),
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
    // Completed programs return to a restrained supporting surface, even
    // when still active. The completion label/check carry the success state.
    final hero = isActive && !status.isComplete;
    final foreground = hero ? v.onHero : t.textPrimary;
    final secondary = hero ? v.heroSecondary : t.textSecondary;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: hero ? v.heroStart : v.support,
      shape: RoundedRectangleBorder(
        borderRadius: FitFlowRadius.cardBorder,
        side: BorderSide(color: hero ? v.heroLine : v.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            child: InkWell(
              key: ValueKey('v2_program_link_${definition.id}'),
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FitFlowV2ProgramCover(
                    programId: definition.id,
                    height: ProgramV2Layout.coverHeight(context),
                    onHero: hero,
                    borderRadius: BorderRadius.zero,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(FitFlowSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isActive || isRecommended) ...[
                          Wrap(
                            spacing: FitFlowSpace.xs,
                            runSpacing: FitFlowSpace.xs,
                            children: [
                              if (isActive)
                                FitFlowV2Tag(
                                    context.l10n.trainingProgramActiveTitle,
                                    icon: Icons.play_circle_outline),
                              if (isRecommended)
                                FitFlowV2Tag(
                                    context
                                        .l10n.trainingProgramRecommendedMatch,
                                    icon: Icons.flag_outlined),
                            ],
                          ),
                          const SizedBox(height: FitFlowSpace.sm),
                        ],
                        Semantics(
                          header: true,
                          child: Text(definition.name,
                              style: text.titleLarge?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: FitFlowSpace.xxs),
                        Text(definition.focus,
                            style: text.bodyMedium?.copyWith(color: secondary)),
                        const SizedBox(height: FitFlowSpace.xs),
                        ProgramStructureLine(
                            definition: definition, color: secondary),
                        const SizedBox(height: FitFlowSpace.sm),
                        if (isActive || status.hasProgress)
                          ProgramV2ProgressSummary(
                              status: status, onHero: hero, showNext: isActive)
                        else
                          Text(programStatusLabel(context, status),
                              style:
                                  text.labelLarge?.copyWith(color: secondary)),
                        const SizedBox(height: FitFlowSpace.xs),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: ExcludeSemantics(
                              child:
                                  Icon(Icons.chevron_right, color: secondary)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onContinue != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  FitFlowSpace.md, 0, FitFlowSpace.md, FitFlowSpace.md),
              child: Align(
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
            ),
        ],
      ),
    );
  }
}
