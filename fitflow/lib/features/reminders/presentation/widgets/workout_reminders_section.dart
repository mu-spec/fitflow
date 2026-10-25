import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/settings/presentation/widgets/utility_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_controller.dart';
import 'package:fitflow/features/reminders/application/workout_reminders_state.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_preferences.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_permission_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_schedule_status.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Workout reminders" section of the Settings screen (M17).
///
/// Presentation only: every action goes through
/// [WorkoutRemindersController]; no plugin calls live here.
class WorkoutRemindersSection extends ConsumerStatefulWidget {
  const WorkoutRemindersSection({super.key});

  /// Locale-aware day names and time. Selected weekdays stay ISO values.
  static String scheduleSummary(
    BuildContext context,
    WorkoutReminderPreferences prefs,
  ) =>
      _WorkoutRemindersSectionState.scheduleSummary(context, prefs);

  @override
  ConsumerState<WorkoutRemindersSection> createState() =>
      _WorkoutRemindersSectionState();
}

class _WorkoutRemindersSectionState
    extends ConsumerState<WorkoutRemindersSection> {
  late final AppLifecycleListener _lifecycle;
  bool _acting = false;

  // Some disabled-preference writes and test notifications do not publish a
  // controller busy state. Serialize this screen's actions, never its scheduler.
  Future<void> _run(Future<dynamic> Function() action,
      {WorkoutReminderMessage failure =
          WorkoutReminderMessage.saveFailed}) async {
    final state = ref.read(workoutRemindersControllerProvider);
    if (_acting || state.isBusy || !state.isLoaded) return;
    setState(() => _acting = true);
    try {
      await action();
    } catch (_) {
      if (mounted) _showMessage(failure);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    if (!mounted) return;
    // ignore: discarded_futures
    ref.read(workoutRemindersControllerProvider.notifier).refreshStatus();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _pickTime(WorkoutReminderTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: context.l10n.reminderTimeLabel,
    );
    if (picked == null || !mounted) return;
    await ref
        .read(workoutRemindersControllerProvider.notifier)
        .setTime(WorkoutReminderTime(hour: picked.hour, minute: picked.minute));
  }

  void _showMessage(WorkoutReminderMessage message) {
    final l10n = context.l10n;
    final text = switch (message) {
      WorkoutReminderMessage.permissionNeeded => l10n.reminderPermissionNeeded,
      WorkoutReminderMessage.selectAtLeastOneDay => l10n.reminderSelectDay,
      WorkoutReminderMessage.scheduleFailed => l10n.reminderStatusError,
      WorkoutReminderMessage.saveFailed => l10n.reminderSaveFailed,
      WorkoutReminderMessage.testSent => l10n.reminderTestSent,
      WorkoutReminderMessage.testFailed => l10n.reminderTestFailed,
      WorkoutReminderMessage.settingsUnavailable =>
        l10n.reminderSettingsUnavailable,
    };
    // The inline `Open notification settings` action below the status line
    // covers the denied case; keep the SnackBar simple so it never overflows
    // on narrow phones or large text scales.
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
    ref.read(workoutRemindersControllerProvider.notifier).clearMessage();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkoutRemindersState>(workoutRemindersControllerProvider,
        (previous, next) {
      if (next.message != null &&
          (previous?.messageId != next.messageId ||
              previous?.message == null)) {
        _showMessage(next.message!);
      }
    });

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(workoutRemindersControllerProvider);
    final controller = ref.read(workoutRemindersControllerProvider.notifier);
    final prefs = state.preferences;
    final status = state.status;
    final busy = _acting || state.isBusy || !state.isLoaded;
    final l = context.l10n;
    if (!state.isLoaded) {
      return UtilityDisclosure(
          title: l.reminderSectionTitle,
          summary: l.utilityLoadingReminders,
          children: [FitFlowLoading(label: l.utilityLoadingReminders)]);
    }
    final statusText = switch (status) {
      WorkoutReminderScheduleStatus.off => l.reminderStatusOff,
      WorkoutReminderScheduleStatus.scheduled => l.reminderStatusScheduled,
      WorkoutReminderScheduleStatus.permissionBlocked =>
        l.reminderStatusBlocked,
      WorkoutReminderScheduleStatus.scheduleError => l.reminderStatusError,
    };

    return UtilityDisclosure(
      title: l.reminderSectionTitle,
      icon: Icons.notifications_outlined,
      summary: busy
          ? l.utilityUpdating
          : '$statusText\n${scheduleSummary(context, prefs)}',
      children: [
        if (busy) Text(l.utilityUpdating),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.reminderToggleTitle),
          value: prefs.enabled,
          onChanged: busy
              ? null
              : (value) {
                  // ignore: discarded_futures
                  _run(() => controller.setEnabled(value));
                },
        ),
        const SizedBox(height: FitFlowSpace.xs),
        if (status == WorkoutReminderScheduleStatus.permissionBlocked ||
            state.permission == WorkoutReminderPermissionStatus.denied) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () {
                      // ignore: discarded_futures
                      _run(controller.openNotificationSettings,
                          failure: WorkoutReminderMessage.settingsUnavailable);
                    },
              icon: const ExcludeSemantics(
                child: Icon(Icons.settings_outlined),
              ),
              label: Text(context.l10n.reminderOpenSettings),
            ),
          ),
        ],
        const Divider(height: 16),
        Semantics(
          header: true,
          child: Text(
            l.utilitySavedSchedule,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.reminderDaysLabel,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: FitFlowSpace.xs),
        _WeekdayPicker(
          selected: prefs.weekdays,
          enabled: !busy,
          onToggle: (weekday) {
            // ignore: discarded_futures
            _run(() => controller.toggleWeekday(weekday));
          },
        ),
        if (prefs.weekdays.isEmpty) ...[
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            context.l10n.reminderSelectDay,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
        const SizedBox(height: FitFlowSpace.xs),
        ListTile(
          minVerticalPadding: FitFlowSpace.xs,
          contentPadding: EdgeInsets.zero,
          leading: const ExcludeSemantics(
            child: Icon(Icons.schedule_outlined),
          ),
          title: Text(context.l10n.reminderTimeLabel),
          subtitle: Text(_formatTime(context, prefs.time)),
          trailing: const ExcludeSemantics(
            child: Icon(Icons.edit_outlined),
          ),
          enabled: !busy,
          onTap: () {
            // ignore: discarded_futures
            _run(() => _pickTime(prefs.time));
          },
        ),
        const SizedBox(height: FitFlowSpace.xs),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: FitFlowSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: FitFlowSpace.sm),
              Expanded(
                child: Text(
                  context.l10n.reminderInexactNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: state.canSendTest && !busy
                ? () {
                    // ignore: discarded_futures
                    _run(controller.sendTestNotification,
                        failure: WorkoutReminderMessage.testFailed);
                  }
                : null,
            icon: const ExcludeSemantics(
              child: Icon(Icons.notifications_active_outlined),
            ),
            label: Text(context.l10n.reminderSendTest),
          ),
        ),
      ],
    );
  }

  static String _formatTime(BuildContext context, WorkoutReminderTime time) =>
      TimeOfDay(hour: time.hour, minute: time.minute).format(context);

  /// Locale-aware day names and time. Selected weekdays stay ISO values.
  static String scheduleSummary(
      BuildContext context, WorkoutReminderPreferences prefs) {
    final l10n = context.l10n;
    final time = _formatTime(context, prefs.time);
    final material = MaterialLocalizations.of(context);
    if (prefs.weekdays.isEmpty) {
      return l10n.scheduleSummary(l10n.reminderNoDays, time);
    }
    final days = prefs.isEveryDay
        ? l10n.reminderEveryDay
        : prefs.weekdays
            .map((day) => FitFlowLocaleFormat.shortWeekday(material, day))
            .join(', ');
    return l10n.scheduleSummary(days, time);
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final Set<int> selected;
  final bool enabled;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final order = FitFlowLocaleFormat.weekdayDisplayOrder(
      material.firstDayOfWeekIndex,
    );
    return Wrap(
      spacing: FitFlowSpace.xs,
      runSpacing: FitFlowSpace.xs,
      children: [
        for (final weekday in order)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: FilterChip(
              key: ValueKey<String>('reminder_weekday_$weekday'),
              label: Semantics(
                  label: FitFlowLocaleFormat.fullWeekday(material, weekday),
                  excludeSemantics: true,
                  child: Text(
                      FitFlowLocaleFormat.shortWeekday(material, weekday))),
              showCheckmark: true,
              selected: selected.contains(weekday),
              onSelected: enabled ? (_) => onToggle(weekday) : null,
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
      ],
    );
  }
}
