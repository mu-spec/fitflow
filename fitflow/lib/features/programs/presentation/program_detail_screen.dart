import 'program_session_preview_screen.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'widgets/program_identity_banner.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// V2 program identity, factual progress, original actions and compact weeks.
/// No program/session definition, policy, controller or route is replaced.
/// Scoped Slate + Citrus presentation, identical tokens to the Workouts hub.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      WorkoutsTheme(child: _ProgramDetailContent(programId: programId));
}

class _ProgramDetailContent extends ConsumerStatefulWidget {
  const _ProgramDetailContent({required this.programId});

  final String programId;

  @override
  ConsumerState<_ProgramDetailContent> createState() =>
      _ProgramDetailContentState();
}

class _ProgramDetailContentState extends ConsumerState<_ProgramDetailContent> {
  int? selectedWeek;
  String? expandedSession;
  final sessionsKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final definition = AdaptiveProgramCatalog.byId(widget.programId);
    final v = FitFlowVisualV2.of(context);
    if (definition == null) {
      return Scaffold(
        backgroundColor: v.page,
        appBar:
            AppBar(title: Text(context.l10n.trainingProgramProgramNotFound)),
        body: ProgramNotFoundBody(
          title: context.l10n.trainingProgramProgramNotFound,
          body: context.l10n.trainingProgramProgramNotFoundBody,
        ),
      );
    }

    final theme = Theme.of(context);
    final goal = ref.watch(userFitnessProfileProvider).value?.goal;
    final programsAsync = ref.watch(adaptiveProgramsControllerProvider);
    if (programsAsync.isLoading || programsAsync.hasError) {
      return Scaffold(
        backgroundColor: v.page,
        appBar: AppBar(title: Text(definition.name)),
        body: ProgramProgressState(
          loading: programsAsync.isLoading,
          onRetry: () =>
              ref.read(adaptiveProgramsControllerProvider.notifier).refresh(),
        ),
      );
    }
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
      backgroundColor: v.page,
      appBar: AppBar(
        // The program's own heading lives in the content, once. This short
        // parent-section label also stays readable at 2x text in the app bar.
        title: Text(context.l10n.trainingPrograms,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
        backgroundColor: v.page,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: FitFlowLayout.maxReadableWidth),
            child: ListView(
              // Only the selected week's sessions are mounted.
              padding: EdgeInsets.all(ProgramV2Layout.inset(context)),
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProgramDetailHeader(
                        definition: definition,
                        isRecommended: isRecommended,
                      ),
                      const SizedBox(height: FitFlowSpace.sm),
                      ProgramV2ProgressSummary(
                          status: status, isActive: isActive),
                      const SizedBox(height: FitFlowSpace.sm),
                      _ProgramActions(
                        definition: definition,
                        status: status,
                        isActive: isActive,
                        otherActive: otherActive,
                        onContinue: () {
                          setState(() {
                            selectedWeek = status.nextSession?.week;
                            expandedSession = status.nextSession?.id;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final target = sessionsKey.currentContext;
                            if (target != null) {
                              Scrollable.ensureVisible(target);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: FitFlowSpace.sm),
                      ExpansionTile(
                        key: const Key('program_details_disclosure'),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding:
                            const EdgeInsets.only(bottom: FitFlowSpace.md),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(context.l10n.trainingProgramAbout,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(definition.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: FitFlowTheme.of(context)
                                        .textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: FitFlowSpace.md),
                      SingleChildScrollView(
                        key: sessionsKey,
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final week in definition.weeks)
                            Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 8),
                                child: ChoiceChip(
                                  key: ValueKey('program_week_${week.number}'),
                                  label: Text(context.l10n
                                      .trainingProgramWeek(week.number)),
                                  selected: week.number ==
                                      (selectedWeek ??
                                          status.nextSession?.week ??
                                          1),
                                  onSelected: (_) => setState(() {
                                    selectedWeek = week.number;
                                    expandedSession = null;
                                  }),
                                )),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      for (final session in definition.weeks
                          .firstWhere((w) =>
                              w.number ==
                              (selectedWeek ?? status.nextSession?.week ?? 1))
                          .sessions)
                        Card(
                          key: ValueKey('v2_program_session_${session.id}'),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            key: ValueKey(
                                'session_${session.id}_${expandedSession == session.id}'),
                            initiallyExpanded: expandedSession == session.id,
                            onExpansionChanged: (open) => setState(() =>
                                expandedSession = open ? session.id : null),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: Text(session.focus,
                                style: theme.textTheme.titleMedium),
                            subtitle: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(context.l10n
                                      .trainingSession(session.session)),
                                  ProgramSessionStatusChip(
                                      status: status.statusOf(session))
                                ]),
                            childrenPadding: const EdgeInsets.all(12),
                            children: [
                              if (expandedSession == session.id)
                                ProgramSessionContent(
                                    programId: definition.id,
                                    sessionId: session.id,
                                    embedded: true),
                            ],
                          ),
                        ),
                    ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramDetailHeader extends StatelessWidget {
  const _ProgramDetailHeader({
    required this.definition,
    required this.isRecommended,
  });

  final AdaptiveProgramDefinition definition;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    return Column(
      key: const Key('v2_program_detail_header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProgramIdentityBanner(program: definition),
        if (isRecommended) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Text(context.l10n.trainingProgramRecommendedMatch,
              style: text.bodySmall?.copyWith(color: t.textSecondary)),
        ],
      ],
    );
  }
}

class _ProgramActions extends ConsumerWidget {
  const _ProgramActions({
    required this.definition,
    required this.status,
    required this.isActive,
    required this.otherActive,
    required this.onContinue,
  });

  final AdaptiveProgramDefinition definition;
  final AdaptiveProgramStatus status;
  final bool isActive;
  final bool otherActive;
  final VoidCallback onContinue;

  Future<void> _showFailure(BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.trainingProgramActionFailed)),
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
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(context.l10n.trainingProgramContinueLabel),
        ));
      }
    } else if (otherActive) {
      buttons.add(FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
        onPressed: () async {
          final confirmed = await ProgramDialogs.confirmSwitch(context);
          if (!confirmed) return;
          final ok = await controller.switchActiveProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text(context.l10n.trainingProgramSwitchProgram),
      ));
    } else {
      buttons.add(FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
        onPressed: () async {
          final ok = await controller.startOrResumeProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: Icon(status.hasProgress
            ? Icons.play_arrow_rounded
            : Icons.play_circle_outline),
        label: Text(status.hasProgress
            ? context.l10n.trainingProgramResumeProgram
            : context.l10n.programStart),
      ));
    }

    if (status.hasProgress) {
      buttons.add(OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
        onPressed: () async {
          final confirmed = await ProgramDialogs.confirmRestart(context);
          if (!confirmed) return;
          final ok = await controller.restartProgram(definition.id);
          if (!ok && context.mounted) await _showFailure(context);
        },
        icon: const Icon(Icons.restart_alt_rounded),
        label: Text(context.l10n.trainingProgramRestartProgram),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: FitFlowSpace.xs),
          if (buttons[i] is FilledButton || buttons.length == 1)
            buttons[i]
          else
            Align(
                alignment: AlignmentDirectional.centerStart, child: buttons[i]),
        ],
      ],
    );
  }
}
