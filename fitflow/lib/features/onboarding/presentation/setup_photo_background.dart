import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';

/// Foreground contrast for photographic setup only; does not save or change the
/// user's appearance preference, nor affect preparation or other app screens.
class SetupPhotoTheme extends StatelessWidget {
  const SetupPhotoTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
        data: base.copyWith(
            brightness: Brightness.dark,
            colorScheme:
                base.colorScheme.copyWith(brightness: Brightness.dark)),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: WorkoutsTheme(child: child)));
  }
}

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
      // A dark tonal scrim preserves photographic color. Translucent foregrounds
      // provide local contrast without hiding the athlete behind white cards.
      DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: .50),
          Colors.black.withValues(alpha: .25),
          Colors.black.withValues(alpha: .25),
          Colors.black.withValues(alpha: .72)
        ],
        stops: const [0, .35, .78, 1],
      ))),
      child,
    ]);
  }
}

/// See-through contrast protection on the photographic setup surface.
class SetupPhotoPanel extends StatelessWidget {
  const SetupPhotoPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.black.withValues(alpha: .58),
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.all(12), child: child));
}
