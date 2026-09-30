import 'dart:convert';
import 'dart:typed_data';

import 'package:fitflow/features/backup/domain/backup_format.dart';
import 'package:fitflow/features/backup/domain/backup_reminder_preferences.dart';
import 'package:fitflow/features/backup/domain/backup_validation_result.dart';
import 'package:fitflow/features/backup/domain/fitflow_backup_data.dart';
import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_time.dart';
import 'package:fitflow/features/reminders/domain/workout_reminder_weekday.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/data/workout_history_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_limits.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

/// Pure, Flutter-free encoder/decoder for the FitFlow backup file.
///
/// * `encode` is deterministic for the same logical data + `createdAtUtc`:
///   sets are sorted by stable names, maps by IDs, history newest-first,
///   custom workouts most-recently-updated-first, timestamps in UTC ISO-8601.
/// * `decode` is STRICT (stricter than the tolerant app storages): any
///   invalid record in any section rejects the whole file. Nothing is
///   written anywhere by this class.
class BackupCodec {
  BackupCodec._();

  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  // ---------------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------------

  static Map<String, Object?> toJson(FitFlowBackupEnvelope envelope) {
    final d = envelope.data;
    return {
      BackupFormat.keyFormat: BackupFormat.marker,
      BackupFormat.keySchemaVersion: envelope.schemaVersion,
      BackupFormat.keyCreatedAtUtc: _utc(envelope.createdAtUtc),
      BackupFormat.keyData: {
        BackupFormat.sectionProfile: d.userFitnessProfile == null
            ? null
            : profileToJson(d.userFitnessProfile!),
        BackupFormat.sectionCapability: d.capabilityProfile == null
            ? null
            : capabilityToJson(d.capabilityProfile!),
        BackupFormat.sectionEvidence:
            evidenceToJson(d.adaptiveProgressionEvidence),
        BackupFormat.sectionHistory: [
          for (final w in _sortedHistory(d.workoutHistory)) workoutToJson(w),
        ],
        BackupFormat.sectionCustomWorkouts: [
          for (final t in _sortedTemplates(d.customWorkouts)) templateToJson(t),
        ],
        BackupFormat.sectionPrograms: programsToJson(d.adaptivePrograms),
        BackupFormat.sectionReminders: remindersToJson(d.workoutReminders),
        BackupFormat.sectionAppearance: d.appearance.name,
      },
    };
  }

  static String encodeString(FitFlowBackupEnvelope envelope) =>
      _encoder.convert(toJson(envelope));

  static Uint8List encode(FitFlowBackupEnvelope envelope) =>
      Uint8List.fromList(utf8.encode(encodeString(envelope)));

  static Map<String, Object?> profileToJson(UserFitnessProfile p) => {
        'goal': p.goal.name,
        'experience': p.experience.name,
        'workoutDuration': p.workoutDuration.name,
        'environment': p.environment.name,
        'equipment': _sortedNames(p.equipment.map((e) => e.name)),
        'preferences': _sortedNames(p.preferences.map((e) => e.name)),
      };

  static Map<String, Object?> capabilityToJson(CapabilityProfile profile) => {
        'capabilities': [
          for (final pattern in CapabilityProfile.trainablePatterns)
            if (profile[pattern] != null) _capabilityToJson(profile[pattern]!),
        ],
      };

  static Map<String, Object?> _capabilityToJson(MovementCapability c) => {
        'movementPattern': c.movementPattern.name,
        'level': c.level.name,
        'source': c.source.name,
        'updatedAt': _utc(c.updatedAt),
        if (c.anchorExerciseId != null) 'anchorExerciseId': c.anchorExerciseId,
      };

  static Map<String, Object?> evidenceToJson(AdaptiveProgressionEvidence e) => {
        'counts': {
          for (final pattern in CapabilityProfile.trainablePatterns)
            pattern.name: e.countFor(pattern),
        },
      };

  static Map<String, Object?> workoutToJson(CompletedWorkout w) {
    final json = Map<String, Object?>.from(w.toJson());
    json['completedAt'] = _utc(w.completedAt);
    return json;
  }

  static Map<String, Object?> templateToJson(CustomWorkoutTemplate t) {
    final json = Map<String, Object?>.from(t.toJson());
    json['createdAt'] = _utc(t.createdAt);
    json['updatedAt'] = _utc(t.updatedAt);
    return json;
  }

  static Map<String, Object?> programsToJson(AdaptiveProgramsState s) {
    final ids = s.progressByProgram.keys.toList()..sort();
    return {
      'activeProgramId': s.activeProgramId,
      'progress': [for (final id in ids) s.progressByProgram[id]!.toJson()],
    };
  }

  static Map<String, Object?> remindersToJson(BackupReminderPreferences r) => {
        'enabled': r.enabled,
        'weekdays': r.weekdays.toList()..sort(),
        'hour': r.time.hour,
        'minute': r.time.minute,
      };

  static List<CompletedWorkout> _sortedHistory(List<CompletedWorkout> input) {
    final list = List<CompletedWorkout>.from(input)
      ..sort((a, b) {
        final byTime = b.completedAt.compareTo(a.completedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return list;
  }

  static List<CustomWorkoutTemplate> _sortedTemplates(
      List<CustomWorkoutTemplate> input) {
    final list = List<CustomWorkoutTemplate>.from(input)
      ..sort((a, b) {
        final byTime = b.updatedAt.compareTo(a.updatedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return list;
  }

  static List<String> _sortedNames(Iterable<String> names) =>
      names.toSet().toList()..sort();

  static String _utc(DateTime t) => t.toUtc().toIso8601String();

  // ---------------------------------------------------------------------------
  // Strict decoding / validation
  // ---------------------------------------------------------------------------

  /// Full import pipeline: size → UTF-8 → JSON → object → marker → version →
  /// strict per-section validation → immutable envelope.
  static BackupValidationResult decode(Uint8List bytes) {
    if (bytes.length > BackupFormat.maxImportBytes) {
      return const BackupValidationResult.failure(
          BackupValidationError.tooLarge);
    }
    if (bytes.isEmpty) {
      return const BackupValidationResult.failure(
          BackupValidationError.unreadable,
          detail: 'empty');
    }
    final String text;
    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      return const BackupValidationResult.failure(
          BackupValidationError.unreadable,
          detail: 'utf8');
    }
    return decodeString(text);
  }

  static BackupValidationResult decodeString(String text) {
    Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      return const BackupValidationResult.failure(
          BackupValidationError.unreadable,
          detail: 'json');
    }
    if (root is! Map) {
      return const BackupValidationResult.failure(
          BackupValidationError.unreadable,
          detail: 'root');
    }
    final map = Map<String, Object?>.from(root);

    if (map[BackupFormat.keyFormat] != BackupFormat.marker) {
      return const BackupValidationResult.failure(
          BackupValidationError.notFitFlowBackup);
    }
    final version = map[BackupFormat.keySchemaVersion];
    if (version is! int || version < 1) {
      return const BackupValidationResult.failure(
          BackupValidationError.unsupportedVersion);
    }
    if (version > BackupFormat.schemaVersion) {
      return const BackupValidationResult.failure(
          BackupValidationError.newerVersion);
    }

    try {
      final createdRaw = map[BackupFormat.keyCreatedAtUtc];
      final createdAt =
          createdRaw is String ? DateTime.tryParse(createdRaw) : null;
      if (createdAt == null) throw const _Invalid('createdAtUtc');

      final dataRaw = map[BackupFormat.keyData];
      if (dataRaw is! Map) throw const _Invalid('data');
      final data = Map<String, Object?>.from(dataRaw);
      for (final section in BackupFormat.sections) {
        if (!data.containsKey(section)) throw _Invalid('missing $section');
      }

      final envelope = FitFlowBackupEnvelope(
        schemaVersion: version,
        createdAtUtc: createdAt.toUtc(),
        data: FitFlowBackupData(
          userFitnessProfile: _profile(data[BackupFormat.sectionProfile]),
          capabilityProfile: _capability(data[BackupFormat.sectionCapability]),
          adaptiveProgressionEvidence:
              _evidence(data[BackupFormat.sectionEvidence]),
          workoutHistory: _history(data[BackupFormat.sectionHistory]),
          customWorkouts: _templates(data[BackupFormat.sectionCustomWorkouts]),
          adaptivePrograms: _programs(data[BackupFormat.sectionPrograms]),
          workoutReminders: _reminders(data[BackupFormat.sectionReminders]),
          appearance: _appearance(data[BackupFormat.sectionAppearance]),
        ),
      );
      return BackupValidationResult.success(envelope);
    } on _Invalid catch (e) {
      return BackupValidationResult.failure(BackupValidationError.invalidData,
          detail: e.detail);
    } on Object catch (e) {
      return BackupValidationResult.failure(BackupValidationError.invalidData,
          detail: e.runtimeType.toString());
    }
  }

  // -- sections ---------------------------------------------------------------

  static UserFitnessProfile? _profile(Object? raw) {
    if (raw == null) return null;
    final m = _object(raw, 'profile');
    final equipment = _enumList(
        m['equipment'], WorkoutEquipment.values, 'profile.equipment',
        allowEmpty: false);
    final preferences = _enumList(
        m['preferences'], WorkoutPreference.values, 'profile.preferences');
    return UserFitnessProfile(
      goal: _enum(m['goal'], FitnessGoal.values, 'profile.goal'),
      experience:
          _enum(m['experience'], ExperienceLevel.values, 'profile.experience'),
      workoutDuration: _enum(m['workoutDuration'], WorkoutDuration.values,
          'profile.workoutDuration'),
      environment: _enum(
          m['environment'], TrainingEnvironment.values, 'profile.environment'),
      equipment: Set.unmodifiable(equipment),
      preferences: Set.unmodifiable(preferences),
    );
  }

  static CapabilityProfile? _capability(Object? raw) {
    if (raw == null) return null;
    final m = _object(raw, 'capability');
    final list = _list(m['capabilities'], 'capability.capabilities');
    if (list.length != CapabilityProfile.trainablePatterns.length) {
      throw _Invalid('capability count ${list.length}');
    }
    final map = <MovementPattern, MovementCapability>{};
    for (final item in list) {
      final cap =
          MovementCapability.fromJson(_object(item, 'capability entry'));
      if (cap == null) throw const _Invalid('capability entry');
      if (map.containsKey(cap.movementPattern)) {
        throw _Invalid('duplicate capability ${cap.movementPattern.name}');
      }
      map[cap.movementPattern] = cap;
    }
    final profile = CapabilityProfile.fromMap(map);
    if (!profile.isComplete || !profile.isValid) {
      throw const _Invalid('capability incomplete');
    }
    return profile;
  }

  /// Evidence must be COMPLETE: exactly the ten trainable patterns, each
  /// once, each 0 or 1. Missing keys are rejected — never filled with zero
  /// (the tolerant runtime `fromMap` default is not acceptable for restore).
  static AdaptiveProgressionEvidence _evidence(Object? raw) {
    final m = _object(raw, 'evidence');
    final counts = _object(m['counts'], 'evidence.counts');
    final byName = {
      for (final p in CapabilityProfile.trainablePatterns) p.name: p,
    };
    if (counts.length != CapabilityProfile.trainablePatterns.length) {
      throw _Invalid('evidence count ${counts.length}');
    }
    final parsed = <MovementPattern, int>{};
    for (final entry in counts.entries) {
      final pattern = byName[entry.key];
      if (pattern == null) throw _Invalid('evidence key ${entry.key}');
      final value = entry.value;
      if (value is! int || value < 0 || value > 1) {
        throw _Invalid('evidence value ${entry.key}');
      }
      parsed[pattern] = value;
    }
    for (final pattern in CapabilityProfile.trainablePatterns) {
      if (!parsed.containsKey(pattern)) {
        throw _Invalid('evidence missing ${pattern.name}');
      }
    }
    return AdaptiveProgressionEvidence.fromMap(parsed);
  }

  /// Bounded: the app keeps at most [WorkoutHistoryStorage.maxEntries]; a
  /// larger backup is rejected instead of being silently trimmed on restore.
  static List<CompletedWorkout> _history(Object? raw) {
    final list = _list(raw, 'history');
    if (list.length > WorkoutHistoryStorage.maxEntries) {
      throw _Invalid('history count ${list.length}');
    }
    final out = <CompletedWorkout>[];
    final ids = <String>{};
    for (final item in list) {
      final m = _object(item, 'history entry');
      final w = CompletedWorkout.fromJson(m);
      if (w == null) throw const _Invalid('history entry');
      _requireSameLength(m['warmup'], w.warmup.length, 'history.warmup');
      _requireSameLength(m['main'], w.main.length, 'history.main');
      _requireSameLength(m['cooldown'], w.cooldown.length, 'history.cooldown');
      if (!ids.add(w.id)) throw _Invalid('duplicate history id ${w.id}');
      out.add(w);
    }
    return _sortedHistory(out);
  }

  /// Bounded: at most [CustomWorkoutLimits.maxTemplates]; larger backups are
  /// rejected instead of being silently truncated by the storage encoder.
  static List<CustomWorkoutTemplate> _templates(Object? raw) {
    final list = _list(raw, 'customWorkouts');
    if (list.length > CustomWorkoutLimits.maxTemplates) {
      throw _Invalid('customWorkouts count ${list.length}');
    }
    final out = <CustomWorkoutTemplate>[];
    final ids = <String>{};
    for (final item in list) {
      final m = _object(item, 'custom workout');
      final t = CustomWorkoutTemplate.fromJson(m);
      if (t == null) throw const _Invalid('custom workout');
      if (t.name.trim().isEmpty || t.id.trim().isEmpty) {
        throw const _Invalid('custom workout name/id');
      }
      _requireSameLength(m['warmup'], t.warmup.length, 'custom.warmup');
      _requireSameLength(m['main'], t.main.length, 'custom.main');
      _requireSameLength(m['cooldown'], t.cooldown.length, 'custom.cooldown');
      if (!ids.add(t.id)) throw _Invalid('duplicate custom workout ${t.id}');
      out.add(t);
    }
    return _sortedTemplates(out);
  }

  static AdaptiveProgramsState _programs(Object? raw) {
    final m = _object(raw, 'programs');
    final list = _list(m['progress'], 'programs.progress');
    final byId = <String, AdaptiveProgramProgress>{};
    for (final item in list) {
      final progress =
          _programProgress(_object(item, 'program progress'), byId);
      byId[progress.programId] = progress;
    }
    final activeRaw = m['activeProgramId'];
    String? active;
    if (activeRaw != null) {
      if (activeRaw is! String || !AdaptiveProgramCatalog.contains(activeRaw)) {
        throw const _Invalid('activeProgramId');
      }
      active = activeRaw;
    }
    return AdaptiveProgramsState(
        activeProgramId: active, progressByProgram: byId);
  }

  /// Strict, lossless parse of ONE program progress record. The tolerant
  /// runtime `AdaptiveProgramProgress.fromJson` (which falls back to
  /// `startedAt` for a bad `updatedAt`, skips malformed completions and
  /// de-duplicates) is deliberately NOT used as the validator.
  static AdaptiveProgramProgress _programProgress(
      Map<String, Object?> pm, Map<String, AdaptiveProgramProgress> seen) {
    final programIdRaw = pm['programId'];
    if (programIdRaw is! String || programIdRaw.isEmpty) {
      throw const _Invalid('program.programId');
    }
    final definition = AdaptiveProgramCatalog.byId(programIdRaw);
    if (definition == null) throw _Invalid('unknown program $programIdRaw');
    if (seen.containsKey(programIdRaw)) {
      throw _Invalid('duplicate program $programIdRaw');
    }
    final startedAt = _timestamp(pm['startedAt'], 'program.startedAt');
    final updatedAt = _timestamp(pm['updatedAt'], 'program.updatedAt');

    final completionsRaw = _list(pm['completions'], 'program.completions');
    final completions = <AdaptiveProgramSessionCompletion>[];
    final plannedIds = <String>{};
    final playerIds = <String>{};
    for (final c in completionsRaw) {
      final cm = _object(c, 'program completion');
      final planned = cm['plannedSessionId'];
      final player = cm['playerSessionId'];
      if (planned is! String || planned.isEmpty) {
        throw const _Invalid('completion.plannedSessionId');
      }
      if (player is! String || player.isEmpty) {
        throw const _Invalid('completion.playerSessionId');
      }
      // The planned session must exist AND belong to THIS program.
      if (!definition.containsSession(planned)) {
        throw _Invalid('completion session $planned not in $programIdRaw');
      }
      final completedAt =
          _timestamp(cm['completedAt'], 'completion.completedAt');
      if (!plannedIds.add(planned)) {
        throw _Invalid('duplicate planned session $planned');
      }
      if (!playerIds.add(player)) {
        throw _Invalid('duplicate player session $player');
      }
      completions.add(AdaptiveProgramSessionCompletion(
        plannedSessionId: planned,
        playerSessionId: player,
        completedAt: completedAt,
      ));
    }

    final progress = AdaptiveProgramProgress(
      programId: programIdRaw,
      startedAt: startedAt,
      updatedAt: updatedAt,
      completions: completions,
    );
    // Guard: the domain constructor de-duplicates; nothing may be lost here.
    if (progress.completions.length != completionsRaw.length) {
      throw _Invalid('program $programIdRaw completions dropped');
    }
    return progress;
  }

  /// Required ISO-8601 timestamp; never substituted.
  static DateTime _timestamp(Object? raw, String what) {
    if (raw is! String) throw _Invalid(what);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) throw _Invalid(what);
    return parsed.toUtc();
  }

  static BackupReminderPreferences _reminders(Object? raw) {
    final m = _object(raw, 'reminders');
    final enabled = m['enabled'];
    if (enabled is! bool) throw const _Invalid('reminders.enabled');
    final weekdaysRaw = _list(m['weekdays'], 'reminders.weekdays');
    final weekdays = <int>{};
    for (final v in weekdaysRaw) {
      if (v is! int || !WorkoutReminderWeekday.isValid(v)) {
        throw const _Invalid('reminders.weekday');
      }
      if (!weekdays.add(v)) throw const _Invalid('reminders.weekday duplicate');
    }
    final hour = m['hour'];
    final minute = m['minute'];
    if (hour is! int || minute is! int) throw const _Invalid('reminders.time');
    final time = WorkoutReminderTime(hour: hour, minute: minute);
    if (!time.isValid) throw const _Invalid('reminders.time');
    final prefs = BackupReminderPreferences(
        enabled: enabled, weekdays: weekdays, time: time);
    if (!prefs.isValid) throw const _Invalid('reminders enabled without days');
    return prefs;
  }

  static AppearanceMode _appearance(Object? raw) =>
      _enum(raw, AppearanceMode.values, 'appearance');

  // -- primitives -------------------------------------------------------------

  static Map<String, Object?> _object(Object? raw, String what) {
    if (raw is! Map) throw _Invalid(what);
    return Map<String, Object?>.from(raw);
  }

  static List<Object?> _list(Object? raw, String what) {
    if (raw is! List) throw _Invalid(what);
    return raw;
  }

  static T _enum<T extends Enum>(Object? raw, List<T> values, String what) {
    if (raw is! String) throw _Invalid(what);
    for (final v in values) {
      if (v.name == raw) return v;
    }
    throw _Invalid(what);
  }

  static List<T> _enumList<T extends Enum>(
      Object? raw, List<T> values, String what,
      {bool allowEmpty = true}) {
    final list = _list(raw, what);
    final out = <T>[];
    for (final item in list) {
      final v = _enum(item, values, what);
      if (out.contains(v)) throw _Invalid('$what duplicate');
      out.add(v);
    }
    if (!allowEmpty && out.isEmpty) throw _Invalid('$what empty');
    return out;
  }

  static void _requireSameLength(Object? raw, int parsed, String what) {
    final list = _list(raw, what);
    if (list.length != parsed) throw _Invalid('$what dropped entries');
  }
}

class _Invalid implements Exception {
  const _Invalid(this.detail);
  final String detail;
}
