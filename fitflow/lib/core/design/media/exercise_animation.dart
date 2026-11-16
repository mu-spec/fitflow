import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lottie/lottie.dart';

/// Shared registered exercise animation. Media is loaded only while
/// visible; it never controls session timing or exercise prescriptions.
class ExerciseAnimation extends StatefulWidget {
  const ExerciseAnimation(
      {super.key,
      required this.exerciseId,
      this.width = 72,
      this.height = 72,
      this.animate = true,
      this.decorative = true,
      this.semanticLabel,
      this.heroFallback = false})
      : assert(width > 0 && height > 0),
        assert(decorative || (semanticLabel != null && semanticLabel != ''));
  final String exerciseId;
  final double width, height;
  final bool animate, decorative, heroFallback;
  final String? semanticLabel;

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation>
    with WidgetsBindingObserver {
  bool _foreground = true, _visible = false, _checkScheduled = false;
  final Set<ScrollPosition> _positions = {};

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final position in _positions) {
      position.removeListener(_scheduleVisibility);
    }
    _positions.clear();
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        _positions.add((element.state as ScrollableState).position);
      }
      return true;
    });
    for (final position in _positions) {
      position.addListener(_scheduleVisibility);
    }
    _scheduleVisibility();
  }

  @override
  void didUpdateWidget(covariant ExerciseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleVisibility();
  }

  void _scheduleVisibility() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      var visible = true;
      RenderObject? ancestor = box.parent;
      while (ancestor != null) {
        if (ancestor is RenderAbstractViewport) {
          final bounds = MatrixUtils.transformRect(
              box.getTransformTo(ancestor), Offset.zero & box.size);
          if (!bounds.overlaps(ancestor.paintBounds)) {
            visible = false;
            break;
          }
        }
        ancestor = ancestor.parent;
      }
      if (visible != _visible) setState(() => _visible = visible);
    });
  }

  @override
  void didChangeMetrics() => _scheduleVisibility();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    for (final position in _positions) {
      position.removeListener(_scheduleVisibility);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget _photo() {
    final poster = ExerciseAnimationRegistry.posterFor(widget.exerciseId);
    if (poster != null) {
      return Image.asset(poster,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          excludeFromSemantics: true);
    }
    final spec = ExerciseMediaRegistry.lookup(widget.exerciseId);
    return FitFlowMediaImage(
        asset: widget.heroFallback ? spec?.hero : spec?.thumbnail,
        width: widget.width,
        height: widget.height);
  }

  Widget _animation(String asset) {
    if (asset.endsWith('.webp') || asset.endsWith('.gif')) {
      return TickerMode(
        enabled: widget.animate && _foreground,
        child: Image.asset(
          asset,
          key: ValueKey(asset),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          cacheWidth: (widget.width * MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, 480),
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) =>
              frame == null ? _photo() : child,
          errorBuilder: (context, error, stackTrace) => _photo(),
        ),
      );
    }
    return _PacedExerciseLottie(
        key: ValueKey('paced:$asset'),
        exerciseId: widget.exerciseId,
        asset: asset,
        width: widget.width,
        height: widget.height,
        animate: widget.animate && _foreground,
        fallback: _photo());
  }

  @override
  Widget build(BuildContext context) {
    final asset = ExerciseAnimationRegistry.assetFor(widget.exerciseId);
    final enabled = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    return Semantics(
        container: !widget.decorative,
        label: widget.decorative ? null : widget.semanticLabel,
        excludeSemantics: true,
        child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ClipRRect(
                borderRadius: FitFlowRadius.mediumBorder,
                child: ColoredBox(
                    color: FitFlowTheme.of(context).subtleSurface,
                    child: _visible && enabled && asset != null
                        ? _animation(asset)
                        : _photo()))));
  }
}

/// Owns only the visual clock. Removing an offscreen/reduced-motion animation
/// disposes its ticker; pausing an onscreen one retains its exact frame.
class _PacedExerciseLottie extends StatefulWidget {
  const _PacedExerciseLottie(
      {super.key,
      required this.exerciseId,
      required this.asset,
      required this.width,
      required this.height,
      required this.animate,
      required this.fallback});
  final String exerciseId, asset;
  final double width, height;
  final bool animate;
  final Widget fallback;

  @override
  State<_PacedExerciseLottie> createState() => _PacedExerciseLottieState();
}

class _PacedExerciseLottieState extends State<_PacedExerciseLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _loaded = false;

  void _syncPlayback() {
    if (_loaded && widget.animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant _PacedExerciseLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Lottie.asset(widget.asset,
      key: ValueKey(widget.asset),
      controller: _controller,
      width: widget.width,
      height: widget.height,
      fit: BoxFit.contain,
      repeat: true,
      animate: widget.animate,
      onLoaded: (composition) {
        if (!mounted) return;
        _controller.duration = ExerciseAnimationRegistry.playbackDuration(
            widget.exerciseId, composition.duration);
        _loaded = true;
        _syncPlayback();
      },
      frameBuilder: (context, child, composition) =>
          composition == null ? widget.fallback : child,
      errorBuilder: (context, error, stackTrace) => widget.fallback);
}
