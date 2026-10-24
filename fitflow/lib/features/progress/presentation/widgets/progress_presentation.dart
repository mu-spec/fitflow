import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Reuses the approved palette without changing the shared app/navigation theme.
class ProgressTheme extends StatelessWidget {
  const ProgressTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => WorkoutsTheme(
        child: Builder(builder: (context) {
          final base = Theme.of(context);
          return Theme(
            data: base.copyWith(
              textTheme: base.textTheme.copyWith(
                titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 18),
                labelLarge: base.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            child: child,
          );
        }),
      );
}

/// Keeps the stored seconds intact; only the visible units are abbreviated.
String progressDuration(BuildContext context, Duration duration) {
  final l = context.l10n;
  final seconds = duration.inSeconds.abs();
  if (seconds < 60) return l.progressCompactSeconds(seconds);
  if (seconds % 60 == 0) return l.progressCompactMinutes(seconds ~/ 60);
  return l.progressCompactDuration(seconds ~/ 60, seconds % 60);
}

class ProgressDisclosure extends StatelessWidget {
  const ProgressDisclosure(
      {super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        expansionAnimationStyle: AnimationStyle(
            duration: SystemMotion.standard(context),
            reverseDuration: SystemMotion.standard(context)),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: children,
      );
}

/// Plain full-width content; deliberately no enclosing card or repeated border.
class ProgressRows extends StatelessWidget {
  const ProgressRows(
      {super.key, required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Padding(padding: padding, child: child),
      );
}

class ProgressLabelValue extends StatelessWidget {
  const ProgressLabelValue(
      {super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ]),
      );
}
