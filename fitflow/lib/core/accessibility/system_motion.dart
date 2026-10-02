import 'package:flutter/material.dart';

/// System reduced-motion helpers. FitFlow does not store its own motion
/// preference; it follows [MediaQuery.disableAnimations].
class SystemMotion {
  SystemMotion._();

  static const double minTouchTarget = 48;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Decorative motion duration. Functional state changes still complete.
  static Duration duration(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}

/// Page transition that keeps the normal Material zoom for everyone else and
/// completes immediately when the system asks for reduced motion.
class FitFlowPageTransitionsBuilder extends PageTransitionsBuilder {
  const FitFlowPageTransitionsBuilder({this.reducedMotion = false});

  final bool reducedMotion;

  static const ZoomPageTransitionsBuilder _zoom = ZoomPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      reducedMotion ? Duration.zero : _zoom.transitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return _zoom.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Applies the system reduced-motion page transition on top of the current
/// theme. Place this above the navigator so route changes inherit it.
class SystemMotionTheme extends StatelessWidget {
  const SystemMotionTheme({super.key, required this.child});

  final Widget child;

  static PageTransitionsTheme transitions({required bool reducedMotion}) {
    final builder = FitFlowPageTransitionsBuilder(reducedMotion: reducedMotion);
    return PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: builder,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = SystemMotion.reduced(context);
    return Theme(
      data: Theme.of(context).copyWith(
        pageTransitionsTheme: transitions(reducedMotion: reduced),
      ),
      child: child,
    );
  }
}
