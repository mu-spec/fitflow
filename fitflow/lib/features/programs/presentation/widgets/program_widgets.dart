import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:flutter/material.dart';

/// Small tonal tag, e.g. "Matches your selected goal" or "Active program".
class ProgramTag extends StatelessWidget {
  const ProgramTag({
    super.key,
    required this.label,
    this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = emphasized ? colors.primaryContainer : colors.secondaryContainer;
    final fg =
        emphasized ? colors.onPrimaryContainer : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip for a planned session: Completed / Next / Planned.
class ProgramSessionStatusChip extends StatelessWidget {
  const ProgramSessionStatusChip({super.key, required this.status});

  final AdaptiveProgramSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    switch (status) {
      case AdaptiveProgramSessionStatus.completed:
        bg = colors.tertiaryContainer;
        fg = colors.onTertiaryContainer;
        icon = Icons.check_circle_outline;
      case AdaptiveProgramSessionStatus.next:
        bg = colors.primaryContainer;
        fg = colors.onPrimaryContainer;
        icon = Icons.play_circle_outline;
      case AdaptiveProgramSessionStatus.planned:
        bg = colors.surfaceContainerHighest;
        fg = colors.onSurfaceVariant;
        icon = Icons.radio_button_unchecked;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              switch (status) {
                AdaptiveProgramSessionStatus.completed =>
                  context.l10n.trainingCompleted,
                AdaptiveProgramSessionStatus.next => context.l10n.trainingNext,
                AdaptiveProgramSessionStatus.planned =>
                  context.l10n.trainingUpcoming,
              },
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Factual completion label + the existing canonical completion fraction.
/// Hero colors are opt-in; no callers outside Programs are restyled.
class ProgramCompletionBar extends StatelessWidget {
  const ProgramCompletionBar({
    super.key,
    required this.status,
    this.onHero = false,
  });

  final AdaptiveProgramStatus status;
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = FitFlowVisualV2.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n
              .trainingSessions(status.completedCount, status.totalCount),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: onHero ? v.onHero : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        ClipRRect(
          borderRadius: FitFlowRadius.smallBorder,
          child: LinearProgressIndicator(
            value: status.completionFraction,
            color: onHero ? v.action : FitFlowTheme.of(context).brand,
            backgroundColor:
                onHero ? v.heroLine : theme.colorScheme.surfaceContainerHighest,
            minHeight: 6,
            semanticsLabel: context.l10n
                .trainingSessions(status.completedCount, status.totalCount),
          ),
        ),
      ],
    );
  }
}

/// Compact structural facts: weeks • sessions/week • total workouts.
class ProgramStructureLine extends StatelessWidget {
  const ProgramStructureLine({super.key, required this.definition, this.color});

  final AdaptiveProgramDefinition definition;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${context.l10n.trainingProgramWeeks(definition.weekCount)} • '
      '${context.l10n.trainingProgramPerWeek(definition.sessionsPerWeek)} • '
      '${context.l10n.trainingProgramTotal(definition.totalSessionCount)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Compact V2 timeline row; state and navigation are supplied by the same
/// canonical status calculator and caller as before. No locking or selection.
class ProgramSessionRow extends StatelessWidget {
  const ProgramSessionRow({
    super.key,
    required this.session,
    required this.status,
    required this.onView,
    this.isFirst = true,
    this.isLast = true,
  });

  final AdaptiveProgramSession session;
  final AdaptiveProgramSessionStatus status;
  final VoidCallback onView;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    final next = status == AdaptiveProgramSessionStatus.next;
    final nodeColor = switch (status) {
      AdaptiveProgramSessionStatus.completed => t.success,
      AdaptiveProgramSessionStatus.next => t.brand,
      AdaptiveProgramSessionStatus.planned => t.textMuted,
    };
    final nodeIcon = switch (status) {
      AdaptiveProgramSessionStatus.completed => Icons.check_rounded,
      AdaptiveProgramSessionStatus.next => Icons.play_arrow_rounded,
      AdaptiveProgramSessionStatus.planned => Icons.circle_outlined,
    };
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: FitFlowSpace.xs,
          runSpacing: FitFlowSpace.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(context.l10n.trainingSession(session.session),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            // This shared chip is intentionally unchanged: Preview uses it too.
            ProgramSessionStatusChip(status: status),
          ],
        ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text('${session.focus} • Goal: ${session.generationGoal.label}',
            style: theme.textTheme.bodySmall?.copyWith(color: t.textSecondary)),
      ],
    );
    final action = TextButton.icon(
      onPressed: onView,
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: Text(context.l10n.trainingProgramViewWorkout),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: FitFlowSpace.xs),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
      child: Stack(
        children: [
          if (!(isFirst && isLast))
            PositionedDirectional(
              start: 13,
              top: isFirst ? 26 : 0,
              bottom: isLast ? null : 0,
              height: isLast ? 26 : null,
              child: ExcludeSemantics(
                child: SizedBox(
                    width: 2, child: ColoredBox(color: v.subtleBorder)),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: FitFlowSpace.xxxl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: next ? v.tint : v.support,
                borderRadius: FitFlowRadius.mediumBorder,
                border: Border.all(color: next ? t.brand : v.subtleBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(FitFlowSpace.xs),
                child: LayoutBuilder(builder: (context, c) {
                  final inline =
                      c.maxWidth >= 420 && !ProgramV2Layout.largeText(context);
                  if (inline) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          Expanded(child: copy),
                          const SizedBox(width: FitFlowSpace.xs),
                          action,
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: FitFlowSpace.xxs),
                      action,
                    ],
                  );
                }),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: FitFlowSpace.sm,
            child: ExcludeSemantics(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: v.page,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor),
                ),
                child: Icon(nodeIcon, color: nodeColor, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic "not found" body for unknown program/session IDs.
class ProgramNotFoundBody extends StatelessWidget {
  const ProgramNotFoundBody({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialogs with the exact spec copy.
class ProgramDialogs {
  ProgramDialogs._();

  static Future<bool> confirmSwitch(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      animationStyle: SystemMotion.overlay(context),
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.trainingProgramSwitchDialogTitle),
        content: Text(context.l10n.trainingProgramSwitchDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.trainingProgramCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.trainingProgramSwitchDialogConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  static Future<bool> confirmRestart(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      animationStyle: SystemMotion.overlay(context),
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.trainingProgramRestartDialogTitle),
        content: Text(context.l10n.trainingProgramRestartDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.trainingProgramCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.trainingProgramRestartDialogConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }
}

String programStatusLabel(BuildContext context, AdaptiveProgramStatus status) =>
    status.isComplete
        ? context.l10n.trainingCompleted
        : status.hasProgress
            ? context.l10n.trainingInProgress
            : context.l10n.trainingNotStarted;

class ProgramProgressState extends StatelessWidget {
  const ProgramProgressState(
      {super.key, required this.loading, required this.onRetry});
  final bool loading;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            FitFlowLoading(label: context.l10n.trainingProgramsLoading),
          const SizedBox(height: 16),
          if (!loading) Text(context.l10n.trainingProgramsError),
          if (!loading)
            TextButton(
                onPressed: onRetry, child: Text(context.l10n.trainingRetry)),
        ]),
      ));
}

/// Local presentation breakpoints only. No root LayoutBuilder is introduced
/// on a route-stack page, so switch/restart dialogs remain ordinary routes.
class ProgramV2Layout {
  ProgramV2Layout._();

  static const double minimumCardWidth = 340;

  static Size viewport(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Some legacy test shells supply a MediaQuery with no size. A real app
    // uses its logical viewport; this fallback also respects device density.
    if (!size.isEmpty) return size;
    final view = View.of(context);
    return view.physicalSize / view.devicePixelRatio;
  }

  static bool largeText(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) > 22;

  static bool twoColumns(BuildContext context) =>
      viewport(context).width >= FitFlowLayout.expandedBreakpoint &&
      !largeText(context);

  static double inset(BuildContext context) => viewport(context).width < 360
      ? FitFlowSpace.md
      : FitFlowSpace.screenHorizontal;

  static double coverHeight(BuildContext context, {bool detail = false}) {
    if (largeText(context)) return 56;
    final size = viewport(context);
    if (size.height < 400) return 64;
    if (detail) return size.height < 700 ? 72 : 120;
    return size.width < 360 ? 88 : 112;
  }
}

/// Existing factual status, count/fraction and next-session copy in one
/// presentation slot. Completion uses text + a check, never an achievement.
class ProgramV2ProgressSummary extends StatelessWidget {
  const ProgramV2ProgressSummary({
    super.key,
    required this.status,
    this.onHero = false,
    this.showNext = true,
    this.compact = false,
  });

  final AdaptiveProgramStatus status;
  final bool onHero;
  final bool showNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
    final hasNext =
        showNext && !status.isComplete && status.nextSession != null;
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status.isComplete) ...[
          ExcludeSemantics(
              child:
                  Icon(Icons.check_circle_outline, color: t.success, size: 20)),
          const SizedBox(width: FitFlowSpace.xs),
        ],
        Flexible(
          child: Text(
            status.isComplete
                ? context.l10n.trainingProgramProgramComplete
                : programStatusLabel(context, status),
            style: text.labelLarge?.copyWith(color: onHero ? v.onHero : null),
          ),
        ),
      ],
    );
    Widget nextLabel() => Text(
          context.l10n.trainingNextSession(status.currentWeek,
              context.l10n.trainingSession(status.nextSession!.session)),
          style: text.bodySmall
              ?.copyWith(color: onHero ? v.heroSecondary : t.textSecondary),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          Wrap(
            spacing: FitFlowSpace.sm,
            runSpacing: FitFlowSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [label, if (hasNext) nextLabel()],
          )
        else
          label,
        const SizedBox(height: FitFlowSpace.xs),
        ProgramCompletionBar(status: status, onHero: onHero),
        if (!compact && hasNext) ...[
          const SizedBox(height: FitFlowSpace.xs),
          nextLabel(),
        ],
      ],
    );
  }
}
