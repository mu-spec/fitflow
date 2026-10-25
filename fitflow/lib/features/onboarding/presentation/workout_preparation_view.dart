import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

/// Completed local setup stages, not a simulated download timer.
class WorkoutPreparationView extends StatelessWidget {
  const WorkoutPreparationView(
      {super.key,
      required this.progress,
      required this.failed,
      required this.onRetry});
  final double progress;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final stage = progress >= 1
        ? l.setupReady
        : progress >= 2 / 3
            ? l.setupLoadingMedia
            : progress >= 1 / 3
                ? l.setupGenerating
                : l.setupSaving;
    final percent = '${(progress * 100).round()}%';
    return PopScope(
        canPop: false,
        child: Scaffold(
            body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
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
                                    liveRegion: true,
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
                                const SizedBox(height: 8),
                                Text(l.setupPreparationLocal,
                                    style: theme.textTheme.bodySmall),
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
