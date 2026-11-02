import 'package:flutter/material.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'program_editorial_card.dart';
import 'program_widgets.dart';

/// The same editorial identity used by the program collection.
class ProgramIdentityBanner extends StatelessWidget {
  const ProgramIdentityBanner({super.key, required this.program});
  final AdaptiveProgramDefinition program;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context)
        .textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: ProgramEditorialCard.colorFor(program.id),
          borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Expanded(
            flex: 5,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                  header: true,
                  child: Text(program.name,
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700))),
              const SizedBox(height: 8),
              Text(program.focus, style: text.bodyMedium),
              const SizedBox(height: 12),
              ProgramStructureLine(definition: program, color: Colors.white),
            ])),
        const SizedBox(width: 12),
        Expanded(
            flex: 4,
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Image.asset(
                            'assets/images/editorial/${program.id}_portrait.webp',
                            fit: BoxFit.contain,
                            excludeFromSemantics: true))))),
      ]),
    );
  }
}
