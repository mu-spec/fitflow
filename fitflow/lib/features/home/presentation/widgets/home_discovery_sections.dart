import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_editorial_card.dart';
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
        return Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var index = 0; index < 7; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  Builder(builder: (context) {
                    final date = DateTime(
                        today.year, today.month, today.day - 6 + index);
                    final count = history.where((entry) {
                      final saved = entry.completedAt.toLocal();
                      return !entry.completedAt.isAfter(now) &&
                          DateUtils.isSameDay(saved, date);
                    }).length;
                    final isToday = DateUtils.isSameDay(date, today);
                    return Semantics(
                      label: context.l10n.homeActivityDay(
                          material.formatFullDate(date), count),
                      excludeSemantics: true,
                      child: Container(
                        key: ValueKey('home_activity_day_$index'),
                        width: width,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF325BDE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(children: [
                          Text(
                              FitFlowLocaleFormat.shortWeekday(
                                  material, date.weekday),
                              style: text.bodySmall?.copyWith(
                                  color: isToday
                                      ? Colors.white70
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(material.formatDecimal(date.day),
                                  style: text.bodyMedium?.copyWith(
                                      color: isToday
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontWeight: FontWeight.w600))),
                          const SizedBox(height: 2),
                          Icon(
                              count > 0
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 12,
                              color: count > 0
                                  ? const Color(0xFFC8FA63)
                                  : (isToday
                                      ? Colors.white60
                                      : Theme.of(context).colorScheme.outline)),
                        ]),
                      ),
                    );
                  }),
                ],
              ]),
            ));
      }),
    ]);
  }
}

/// Browse actual catalog programs, without implying a recommendation or enrollment.
class HomeProgramsShelf extends StatelessWidget {
  const HomeProgramsShelf({super.key});

  // Each actual program has a distinct editorial color, not a status color.
  static Color cardColor(String id, bool dark) => switch (id) {
        'balanced_foundations' => const Color(0xFF224AC5),
        'strength_foundations' => const Color(0xFF6138AE),
        'endurance_builder' => const Color(0xFF006C65),
        'mobility_movement' => const Color(0xFFA63E18),
        _ => const Color(0xFFAD285C),
      };
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionHeading(
          label: l.trainingProgramEntryTitle,
          onTap: () => context.go(AppRoutes.programs)),
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth * .88).clamp(240.0, 360.0);
        return SingleChildScrollView(
          key: const Key('home_programs_shelf'),
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final program in AdaptiveProgramCatalog.all)
              Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: width,
                    child: ProgramEditorialCard(
                        key: ValueKey('home_program_${program.id}'),
                        program: program, color: cardColor(program.id, false)),
                  )),
          ]),
        );
      }),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18, fontWeight: FontWeight.w600)))),
        Semantics(
            label: label,
            child: TextButton(
                onPressed: onTap, child: Text(context.l10n.homeSeeAll))),
      ]);
}
