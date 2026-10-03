import 'package:fitflow/app/config/app_dimensions.dart';
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
          (previous?.messageId != next.messageId || previous?.message == null)) {
        _showMessage(next.message!);
      }
    });

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = ref.watch(workoutRemindersControllerProvider);
    final controller = ref.read(workoutRemindersControllerProvider.notifier);
    final prefs = state.preferences;
    final status = state.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reminderSectionTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimens.itemGap),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.reminderToggleTitle),
                  subtitle: Text(context.l10n.reminderToggleSubtitle),
                  value: prefs.enabled,
                  onChanged: state.isBusy
                      ? null
                      : (value) {
                          // ignore: discarded_futures
                          controller.setEnabled(value);
                        },
                ),
                const SizedBox(height: 4),
                _StatusLine(status: status),
                if (status == WorkoutReminderScheduleStatus.permissionBlocked ||
                    state.permission == WorkoutReminderPermissionStatus.denied) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // ignore: discarded_futures
                        controller.openNotificationSettings();
                      },
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(context.l10n.reminderOpenSettings),
                    ),
                  ),
                ],
                const Divider(height: 24),
                Text(context.l10n.reminderDaysLabel,
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _WeekdayPicker(
                  selected: prefs.weekdays,
                  enabled: !state.isBusy,
                  onToggle: (weekday) {
                    // ignore: discarded_futures
                    controller.toggleWeekday(weekday);
                  },
                ),
                if (prefs.weekdays.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.reminderSelectDay,
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ],
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(context.l10n.reminderTimeLabel),
                  subtitle: Text(_formatTime(context, prefs.time)),
                  trailing: const Icon(Icons.edit_outlined),
                  enabled: !state.isBusy,
                  onTap: () {
                    // ignore: discarded_futures
                    _pickTime(prefs.time);
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  scheduleSummary(context, prefs),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.reminderInexactNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: state.canSendTest
                        ? () {
                            // ignore: discarded_futures
                            controller.sendTestNotification();
                          }
                        : null,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(context.l10n.reminderSendTest),
                  ),
                ),
              ],
            ),
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

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final WorkoutReminderScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final (String text, IconData icon, Color color) = switch (status) {
      WorkoutReminderScheduleStatus.off => (
          l10n.reminderStatusOff,
          Icons.notifications_off_outlined,
          colors.onSurfaceVariant
        ),
      WorkoutReminderScheduleStatus.scheduled => (
          l10n.reminderStatusScheduled,
          Icons.check_circle_outline,
          colors.primary
        ),
      WorkoutReminderScheduleStatus.permissionBlocked => (
          l10n.reminderStatusBlocked,
          Icons.notifications_paused_outlined,
          colors.error
        ),
      WorkoutReminderScheduleStatus.scheduleError => (
          l10n.reminderStatusError,
          Icons.error_outline,
          colors.error
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
        ),
      ],
    );
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
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final weekday in order)
          Semantics(
            label: FitFlowLocaleFormat.fullWeekday(material, weekday),
            button: true,
            selected: selected.contains(weekday),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: ExcludeSemantics(
                child: FilterChip(
                  key: ValueKey<String>('reminder_weekday_$weekday'),
                  label: Text(
                    FitFlowLocaleFormat.narrowWeekday(material, weekday),
                  ),
                  showCheckmark: true,
                  selected: selected.contains(weekday),
                  onSelected: enabled ? (_) => onToggle(weekday) : null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
