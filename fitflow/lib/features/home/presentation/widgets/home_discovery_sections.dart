import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Seven local calendar dates ending today; only saved completions are marked.
class HomeActivityStrip extends StatelessWidget {
  const HomeActivityStrip(
      {super.key, required this.history, required this.now});
  final List<CompletedWorkout> history;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final material = MaterialLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionHeading(
          label: context.l10n.homeActivity,
          onTap: () => context.go(AppRoutes.progress)),
      LayoutBuilder(builder: (context, constraints) {
        final scaled = MediaQuery.textScalerOf(context).scale(14);
        final width = ((constraints.maxWidth - 36) / 7)
            .clamp(scaled > 20 ? 62.0 : 40.0, 80.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var index = 0; index < 7; index++) ...[
              if (index > 0) const SizedBox(width: 6),
              Builder(builder: (context) {
                final date =
                    DateTime(today.year, today.month, today.day - 6 + index);
                final count = history.where((entry) {
                  final saved = entry.completedAt.toLocal();
                  return !entry.completedAt.isAfter(now) &&
                      DateUtils.isSameDay(saved, date);
                }).length;
                final isToday = DateUtils.isSameDay(date, today);
                return Semantics(
                  label: context.l10n
                      .homeActivityDay(material.formatFullDate(date), count),
                  excludeSemantics: true,
                  child: Container(
                    key: ValueKey('home_activity_day_$index'),
                    width: width,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(24)),
                    child: Column(children: [
                      Text(
                          FitFlowLocaleFormat.shortWeekday(
                              material, date.weekday),
                          style: text.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFFC8FA63)
                                  : Colors.transparent,
                              shape: BoxShape.circle),
                          child: Text(material.formatDecimal(date.day),
                              style: text.bodyMedium?.copyWith(
                                  color: isToday
                                      ? const Color(0xFF171918)
                                      : colors.onSurface,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(height: 2),
                      Icon(
                          count > 0
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: count > 0 ? colors.primary : colors.outline),
                    ]),
                  ),
                );
              }),
            ],
          ]),
        );
      }),
    ]);
  }
}

/// Browse actual catalog programs, without implying a recommendation or enrollment.
class HomeProgramsShelf extends StatelessWidget {
  const HomeProgramsShelf({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionHeading(
          label: l.trainingProgramEntryTitle,
          onTap: () => context.go(AppRoutes.programs)),
      SingleChildScrollView(
        key: const Key('home_programs_shelf'),
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final program in AdaptiveProgramCatalog.all)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 164,
                child: Material(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('home_program_${program.id}'),
                    onTap: () =>
                        context.push(AppRoutes.programDetail(program.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FitFlowProgramImage(
                                    programId: program.id,
                                    width: 144,
                                    height: 108)),
                            const SizedBox(height: 8),
                            Text(program.name,
                                style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(l.trainingProgramWeeks(program.weekCount),
                                style: theme.textTheme.bodySmall),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Semantics(
                header: true,
                child: Text(label,
                    style: Theme.of(context).textTheme.titleMedium))),
        Semantics(
            label: label,
            child: TextButton(
                onPressed: onTap, child: Text(context.l10n.homeSeeAll))),
      ]);
}
