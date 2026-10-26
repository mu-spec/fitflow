import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Presentation-paced local setup. Completion is gated by successful preparation.
class WorkoutPreparationView extends StatelessWidget {
  const WorkoutPreparationView(
      {super.key,
      required this.progress,
      this.saving = false,
      required this.failed,
      required this.onRetry});
  final double progress;
  final bool failed;
  final bool saving;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final stage = progress >= 1
        ? l.setupReady
        : saving
            ? l.setupSaving
            : l.setupPreparationLocal;
    final percent = '${(progress * 100).round()}%';
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          minWidth: constraints.maxWidth),
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l.appTitle,
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 32),
                                Semantics(
                                    label: l.setupPreparing,
                                    value: percent,
                                    liveRegion: false,
                                    child: ExcludeSemantics(
                                        child: SizedBox.square(
                                            dimension: 184,
                                            child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Positioned.fill(
                                                      child: CircularProgressIndicator(
                                                          value: progress,
                                                          strokeWidth: 7,
                                                          backgroundColor: theme
                                                              .colorScheme
                                                              .surfaceContainerHigh,
                                                          strokeCap:
                                                              StrokeCap.round)),
                                                  Text(percent,
                                                      style: theme.textTheme
                                                          .displaySmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500)),
                                                ])))),
                                const SizedBox(height: 28),
                                Text(l.setupPreparing,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge),
                                const SizedBox(height: 12),
                                Text(failed ? l.setupPreparationFailed : stage,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium),
                                if (failed) ...[
                                  const SizedBox(height: 20),
                                  FilledButton(
                                      onPressed: onRetry, child: Text(l.retry)),
                                ],
                              ])),
                    ),
                  )),
        )));
  }
}
