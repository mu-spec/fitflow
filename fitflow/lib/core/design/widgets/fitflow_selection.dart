import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

enum FitFlowStatus {
  neutral,
  success,
  warning,
  error,
  info,
  active,
  rest,
  progress,
}

/// Status is never color alone: every tone has a default icon plus a label.
class FitFlowStatusChip extends StatelessWidget {
  const FitFlowStatusChip({
    super.key,
    required this.label,
    this.status = FitFlowStatus.neutral,
    this.icon,
  });

  final String label;
  final FitFlowStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final (color, onColor, fallbackIcon) = _tone(theme);
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: FitFlowRadius.pillBorder,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FitFlowSpace.sm,
              vertical: FitFlowSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? fallbackIcon, size: 16, color: color),
                const SizedBox(width: FitFlowSpace.xs),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: onColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, IconData) _tone(FitFlowTheme theme) {
    return switch (status) {
      FitFlowStatus.neutral => (
          theme.textSecondary,
          theme.textPrimary,
          Icons.circle_outlined,
        ),
      FitFlowStatus.success => (
          theme.success,
          theme.textPrimary,
          Icons.check_circle_outline,
        ),
      FitFlowStatus.warning => (
          theme.warning,
          theme.textPrimary,
          Icons.warning_amber_rounded,
        ),
      FitFlowStatus.error => (
          theme.error,
          theme.textPrimary,
          Icons.error_outline,
        ),
      FitFlowStatus.info => (
          theme.info,
          theme.textPrimary,
          Icons.info_outline,
        ),
      FitFlowStatus.active => (
          theme.workoutActive,
          theme.textPrimary,
          Icons.play_circle_outline,
        ),
      FitFlowStatus.rest => (
          theme.workoutRest,
          theme.textPrimary,
          Icons.pause_circle_outline,
        ),
      FitFlowStatus.progress => (
          theme.progress,
          theme.textPrimary,
          Icons.emoji_events_outlined,
        ),
    };
  }
}

/// A selectable control. Selection is a check icon plus a border, not color
/// alone. Focus, pressed, disabled, and error states are distinct.
class FitFlowSelectableTile extends StatelessWidget {
  const FitFlowSelectableTile({
    super.key,
    required this.label,
    required this.selected,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.hasError = false,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final bool hasError;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    final borderColor = hasError
        ? theme.error
        : selected
            ? theme.brand
            : theme.border;
    final background =
        selected ? theme.brand.withValues(alpha: 0.12) : theme.subtleSurface;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: AnimatedContainer(
        duration: SystemMotion.duration(context, FitFlowMotion.standard),
        curve: FitFlowMotion.standardCurve,
        decoration: BoxDecoration(
          color: enabled ? background : theme.subtleSurface,
          borderRadius: FitFlowRadius.mediumBorder,
          border: Border.all(
            color: enabled ? borderColor : theme.border,
            width: selected || hasError ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: FitFlowRadius.mediumBorder,
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
                        child: Icon(
                          icon,
                          color:
                              enabled ? theme.textSecondary : theme.textMuted,
                        ),
                      ),
                      const SizedBox(width: FitFlowSpace.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: text.titleSmall?.copyWith(
                              color:
                                  enabled ? theme.textPrimary : theme.textMuted,
                            ),
                          ),
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
                    if (hasError)
                      Icon(Icons.error_outline, color: theme.error)
                    else if (selected)
                      Icon(Icons.check_circle, color: theme.brand)
                    else
                      Icon(Icons.circle_outlined, color: theme.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
