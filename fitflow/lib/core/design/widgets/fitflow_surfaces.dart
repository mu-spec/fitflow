import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_elevation.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

enum FitFlowSurfaceTone { plain, subtle, elevated }

/// A surface container. Tone and a hairline border do the work; shadows
/// are reserved for [FitFlowSurfaceTone.elevated] in light mode.
class FitFlowSurface extends StatelessWidget {
  const FitFlowSurface({
    super.key,
    required this.child,
    this.tone = FitFlowSurfaceTone.plain,
    this.padding = const EdgeInsets.all(FitFlowSpace.cardPadding),
    this.margin,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final FitFlowSurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = switch (tone) {
      FitFlowSurfaceTone.plain => theme.surface,
      FitFlowSurfaceTone.subtle => theme.subtleSurface,
      FitFlowSurfaceTone.elevated => theme.elevatedSurface,
    };
    final shadows = tone == FitFlowSurfaceTone.elevated && !isDark
        ? FitFlowElevation.lightRaised
        : const <BoxShadow>[];

    final content = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: FitFlowRadius.cardBorder,
        side: BorderSide(color: theme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: FitFlowRadius.cardBorder,
          boxShadow: shadows,
        ),
        child: semanticLabel == null
            ? content
            : Semantics(
                label: semanticLabel, button: onTap != null, child: content),
      ),
    );
  }
}

class FitFlowSectionHeader extends StatelessWidget {
  const FitFlowSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final theme = FitFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: FitFlowSpace.xxs),
                Text(
                  subtitle!,
                  style: text.bodyMedium?.copyWith(color: theme.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: FitFlowSpace.sm),
          trailing!,
        ],
      ],
    );
  }
}

class FitFlowListRow extends StatelessWidget {
  const FitFlowListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final theme = FitFlowTheme.of(context);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: FitFlowRadius.mediumBorder,
          side: BorderSide(color: theme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SystemMotion.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FitFlowSpace.md,
                vertical: FitFlowSpace.sm,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    ExcludeSemantics(
                      child: Icon(icon, color: theme.textSecondary),
                    ),
                    const SizedBox(width: FitFlowSpace.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: text.titleSmall),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: text.bodySmall?.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    ExcludeSemantics(child: trailing!)
                  else if (onTap != null)
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        color: theme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum FitFlowCalloutTone { info, warning }

class FitFlowCallout extends StatelessWidget {
  const FitFlowCallout({
    super.key,
    required this.message,
    this.title,
    this.tone = FitFlowCalloutTone.info,
  });

  final String message;
  final String? title;
  final FitFlowCalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    final color =
        tone == FitFlowCalloutTone.warning ? theme.warning : theme.info;
    final icon = tone == FitFlowCalloutTone.warning
        ? Icons.warning_amber_rounded
        : Icons.info_outline;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: FitFlowRadius.mediumBorder,
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(FitFlowSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: FitFlowSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!,
                          style: text.titleSmall?.copyWith(color: color)),
                    Text(
                      message,
                      style:
                          text.bodyMedium?.copyWith(color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
