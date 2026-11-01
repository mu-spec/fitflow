import 'program_widgets.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Editorial identity artwork; it does not promise particular exercises.
/// Text and portraits occupy separate columns, including at large text scales.
class ProgramEditorialCard extends StatelessWidget {
  const ProgramEditorialCard(
      {super.key, required this.program, this.color, this.onTap});
  final AdaptiveProgramDefinition program;
  final Color? color;
  final VoidCallback? onTap;

  static Color colorFor(String id) => switch (id) {
        'balanced_foundations' => const Color(0xFF224AC5),
        'strength_foundations' => const Color(0xFF6138AE),
        'endurance_builder' => const Color(0xFF006C65),
        'mobility_movement' => const Color(0xFFA63E18),
        _ => const Color(0xFFAD285C),
      };

  @override
  Widget build(BuildContext context) {
    final fill = color ?? colorFor(program.id);
    final text = Theme.of(context)
        .textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);
    final l = context.l10n;
    void open() => onTap != null
        ? onTap!()
        : context.push(AppRoutes.programDetail(program.id));
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(program.name,
                style: text.titleLarge
                    ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                  flex: 5,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(program.focus, style: text.bodyMedium),
                        const SizedBox(height: 16),
                        ProgramStructureLine(
                            definition: program,
                            color: Colors.white,
                            includeTotal: false),
                      ])),
              const SizedBox(width: 8),
              Expanded(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Image.asset(
                        'assets/images/editorial/${program.id}_portrait.webp',
                        fit: BoxFit.contain,
                        excludeFromSemantics: true),
                  )),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: open,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: fill,
                  minimumSize: const Size(48, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l.programStart),
            ),
          ]),
        ),
      ),
    );
  }
}
