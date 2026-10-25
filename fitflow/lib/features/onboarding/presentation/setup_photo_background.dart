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
    final dark = Theme.of(context).brightness == Brightness.dark;
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
      // A continuous scrim keeps questions readable even over bright clothing.
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surface.withValues(alpha: dark ? .82 : .88),
          surface.withValues(alpha: dark ? .78 : .76),
          surface.withValues(alpha: dark ? .90 : .92)
        ],
        stops: const [0, .48, 1],
      ))),
      child,
    ]);
  }
}
