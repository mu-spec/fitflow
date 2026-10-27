import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'exercise_animation_registry.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lottie/lottie.dart';

/// Shared registered exercise animation. The cached composition is loaded only while
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
    // Include outer scrolling for bounded sections inside another scroll view.
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
    final spec = ExerciseMediaRegistry.lookup(widget.exerciseId);
    return FitFlowMediaImage(
        asset: widget.heroFallback ? spec?.hero : spec?.thumbnail,
        width: widget.width,
        height: widget.height);
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
                        ? Lottie.asset(asset,
                            key: ValueKey(asset),
                            width: widget.width,
                            height: widget.height,
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: widget.animate && _foreground,
                            frameBuilder: (context, child, composition) =>
                                composition == null ? _photo() : child,
                            errorBuilder: (context, error, stackTrace) =>
                                _photo())
                        : _photo()))));
  }
}
