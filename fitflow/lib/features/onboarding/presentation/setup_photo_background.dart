import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:flutter/material.dart';

/// Decorative setup photography, not an exercise demonstration or prescription.
/// The backdrop fills the viewport; the foreground keeps its own scroll/safe area.
class SetupPhotoBackground extends StatelessWidget {
  const SetupPhotoBackground(
      {super.key, required this.exerciseId, required this.child});
  final String exerciseId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final asset = ExerciseMediaRegistry.lookup(exerciseId)?.hero;
    return Stack(fit: StackFit.expand, children: [
      ColoredBox(color: surface),
      if (asset != null)
        ExcludeSemantics(
            child: Image.asset(asset.path,
                key: const Key('setup_fullscreen_photo'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => ColoredBox(color: surface))),
      // Keep the athlete vivid. Text has its own readable panel instead of
      // washing the entire photograph out with a continuous opaque scrim.
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surface.withValues(alpha: .40),
          surface.withValues(alpha: .04),
          surface.withValues(alpha: .04),
          surface.withValues(alpha: .90)
        ],
        stops: const [0, .35, .78, 1],
      ))),
      child,
    ]);
  }
}

/// Local contrast protection; light and dark choices retain the selected theme.
class SetupPhotoPanel extends StatelessWidget {
  const SetupPhotoPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(12), child: child));
}
