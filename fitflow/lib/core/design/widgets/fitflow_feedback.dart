import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_typography.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:flutter/material.dart';

class FitFlowStat extends StatelessWidget {
  const FitFlowStat({
    super.key,
    required this.label,
    required this.value,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: semanticsLabel ?? '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: FitFlowTypography.stat.copyWith(color: theme.textPrimary),
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(
            label,
            style: text.labelMedium?.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class FitFlowProgress extends StatelessWidget {
  const FitFlowProgress({
    super.key,
    required this.label,
    this.value,
  });

  final String label;

  /// 0–1. Null shows an indeterminate indicator.
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final percent = value == null ? null : (value!.clamp(0, 1) * 100).round();
    return Semantics(
      label: percent == null ? label : '$label, $percent percent',
      value: percent == null ? 'in progress' : '$percent%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: theme.textSecondary,
                ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          ClipRRect(
            borderRadius: FitFlowRadius.pillBorder,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: theme.brand,
              backgroundColor: theme.subtleSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class FitFlowEmptyState extends StatelessWidget {
  const FitFlowEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateBlock(
      icon: icon,
      title: title,
      message: message,
      action: action,
    );
  }
}

class FitFlowErrorState extends StatelessWidget {
  const FitFlowErrorState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return _StateBlock(
      icon: Icons.error_outline,
      iconColor: theme.error,
      title: title,
      message: message,
      action: action,
    );
  }
}

class FitFlowLoading extends StatelessWidget {
  const FitFlowLoading({
    super.key,
    this.label = 'Loading',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return Semantics(
      label: label,
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: FitFlowSpace.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBlock extends StatelessWidget {
  const _StateBlock({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.action,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(FitFlowSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: iconColor ?? theme.textSecondary),
          const SizedBox(height: FitFlowSpace.sm),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            message,
            style: text.bodyMedium?.copyWith(color: theme.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: FitFlowSpace.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class FitFlowConfirmDialog extends StatelessWidget {
  const FitFlowConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FitFlowConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FitFlowTheme.of(context);
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FitFlowTertiaryButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (destructive)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.error,
              minimumSize: const Size(48, SystemMotion.minTouchTarget),
            ),
            child: Text(confirmLabel),
          )
        else
          FitFlowPrimaryButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
      ],
    );
  }
}

class FitFlowSheet extends StatelessWidget {
  const FitFlowSheet({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => FitFlowSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          FitFlowSpace.xl,
          FitFlowSpace.xs,
          FitFlowSpace.xl,
          FitFlowSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: text.titleLarge),
              const SizedBox(height: FitFlowSpace.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
