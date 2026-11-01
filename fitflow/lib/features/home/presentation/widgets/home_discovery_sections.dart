import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_photo_surface.dart';

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
                color: const Color(0xFF243454),
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
                          border: Border(
                              bottom: BorderSide(
                            color: isToday
                                ? const Color(0xFFC8FA63)
                                : Colors.transparent,
                            width: isToday ? 3 : 1,
                          )),
                        ),
                        child: Column(children: [
                          Text(
                              FitFlowLocaleFormat.shortWeekday(
                                  material, date.weekday),
                              style: text.bodySmall
                                  ?.copyWith(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(material.formatDecimal(date.day),
                                  style: text.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600))),
                          const SizedBox(height: 2),
                          Icon(
                              count > 0
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 12,
                              color: count > 0
                                  ? const Color(0xFFC8FA63)
                                  : Colors.white60),
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
    final theme = Theme.of(context);
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
                    child: Material(
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('home_program_${program.id}'),
                        onTap: () =>
                            context.push(AppRoutes.programDetail(program.id)),
                        child: HomePhotoSurface(
                          width: width,
                          color: cardColor(
                              program.id, theme.brightness == Brightness.dark),
                          image: FitFlowProgramImage(
                              programId: program.id,
                              width: width,
                              height: width * .75),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(program.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          l.trainingProgramWeeks(
                                              program.weekCount),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(color: Colors.white))),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 24),
                                ]),
                              ]),
                        ),
                      ),
                    ),
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
