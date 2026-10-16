import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// Opt-in V2 presentation roles derived from the existing semantic palette.
/// No global ThemeData replacement: unadopted features remain unchanged.
class FitFlowVisualV2 {
  FitFlowVisualV2.of(BuildContext context)
      : this.fromTheme(FitFlowTheme.of(context), Theme.of(context).brightness);

  FitFlowVisualV2.fromTheme(FitFlowTheme theme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final p = theme.palette;
    page = p.background;
    heroStart = dark ? p.elevatedSurface : p.onBrandContainer;
    // Keep legacy consumers compatible while removing large gradient blocks.
    heroEnd = heroStart;
    onHero = dark ? p.textPrimary : p.onBrand;
    heroSecondary = Color.lerp(onHero, heroStart, .18)!;
    heroLine = dark ? p.border : onHero.withValues(alpha: .20);
    action = dark ? p.brand : p.brandContainer;
    onAction = dark ? p.onBrand : p.onBrandContainer;
    support = p.surface;
    tint = p.subtleSurface;
    onTint = p.textPrimary;
    subtleBorder = p.border;
  }

  late final Color page, heroStart, heroEnd, onHero, heroSecondary, heroLine;
  late final Color action, onAction, support, tint, onTint, subtleBorder;
}

/// An emphasis surface, distinct from ordinary information containers.
class FitFlowV2HeroSurface extends StatelessWidget {
  const FitFlowV2HeroSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FitFlowRadius.sheet),
        color: v.heroStart,
        border: Border.all(color: v.heroLine),
      ),
      child:
          Padding(padding: const EdgeInsets.all(FitFlowSpace.lg), child: child),
    );
  }
}

/// A quiet supporting surface. Tonal treatment is useful for compact facts.
class FitFlowV2InfoSurface extends StatelessWidget {
  const FitFlowV2InfoSurface(
      {super.key,
      required this.child,
      this.tonal = false,
      this.padding = const EdgeInsets.all(FitFlowSpace.md)});
  final Widget child;
  final bool tonal;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tonal ? v.tint : v.support,
        borderRadius:
            tonal ? FitFlowRadius.mediumBorder : FitFlowRadius.cardBorder,
        border: tonal ? null : Border.all(color: v.subtleBorder),
      ),
      child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child)),
    );
  }
}

/// Noninteractive, wrapping metadata — not a fake selectable chip.
class FitFlowV2Tag extends StatelessWidget {
  const FitFlowV2Tag(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    return DecoratedBox(
      decoration:
          BoxDecoration(color: v.tint, borderRadius: FitFlowRadius.pillBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FitFlowSpace.sm, vertical: FitFlowSpace.xs),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            ExcludeSemantics(
                child: Icon(icon,
                    size: 18, color: FitFlowTheme.of(context).brand)),
            const SizedBox(width: FitFlowSpace.xs),
          ],
          Flexible(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: v.onTint))),
        ]),
      ),
    );
  }
}
