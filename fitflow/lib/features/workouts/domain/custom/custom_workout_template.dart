import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:flutter/foundation.dart';

/// Immutable custom workout template – editable configuration, not historical snapshot.
@immutable
class CustomWorkoutTemplate {
  const CustomWorkoutTemplate({
    required this.id,
    required this.name,
    required this.targetDuration,
    required this.createdAt,
    required this.updatedAt,
    List<CustomWorkoutExerciseEntry>? warmup,
    List<CustomWorkoutExerciseEntry>? main,
    List<CustomWorkoutExerciseEntry>? cooldown,
  })  : _warmup = warmup ?? const [],
        _main = main ?? const [],
        _cooldown = cooldown ?? const [];

  final String id;
  final String name;
  final WorkoutDuration targetDuration;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<CustomWorkoutExerciseEntry> _warmup;
  final List<CustomWorkoutExerciseEntry> _main;
  final List<CustomWorkoutExerciseEntry> _cooldown;

  List<CustomWorkoutExerciseEntry> get warmup => List.unmodifiable(_warmup);
  List<CustomWorkoutExerciseEntry> get main => List.unmodifiable(_main);
  List<CustomWorkoutExerciseEntry> get cooldown => List.unmodifiable(_cooldown);

  List<CustomWorkoutExerciseEntry> get allEntries => List.unmodifiable([..._warmup, ..._main, ..._cooldown]);

  int get totalExerciseCount => _warmup.length + _main.length + _cooldown.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetDuration': targetDuration.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'warmup': _warmup.map((e) => e.toJson()).toList(),
      'main': _main.map((e) => e.toJson()).toList(),
      'cooldown': _cooldown.map((e) => e.toJson()).toList(),
    };
  }

  static CustomWorkoutTemplate? fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final name = json['name'] as String?;
      final targetDurationName = json['targetDuration'] as String?;
      final createdAtStr = json['createdAt'] as String?;
      final updatedAtStr = json['updatedAt'] as String?;

      if (id == null || name == null || targetDurationName == null || createdAtStr == null || updatedAtStr == null) {
        return null;
      }

      final createdAt = DateTime.tryParse(createdAtStr);
      final updatedAt = DateTime.tryParse(updatedAtStr);
      if (createdAt == null || updatedAt == null) return null;

      WorkoutDuration? targetDuration;
      for (final d in WorkoutDuration.values) {
        if (d.name == targetDurationName) {
          targetDuration = d;
          break;
        }
      }
      if (targetDuration == null) return null;

      List<CustomWorkoutExerciseEntry> parseList(dynamic raw) {
        final result = <CustomWorkoutExerciseEntry>[];
        if (raw is List) {
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              final entry = CustomWorkoutExerciseEntry.fromJson(item);
              if (entry != null) result.add(entry);
            } else if (item is Map) {
              final entry = CustomWorkoutExerciseEntry.fromJson(Map<String, dynamic>.from(item));
              if (entry != null) result.add(entry);
            }
          }
        }
        return result;
      }

      final warmup = parseList(json['warmup']);
      final main = parseList(json['main']);
      final cooldown = parseList(json['cooldown']);

      return CustomWorkoutTemplate(
        id: id,
        name: name,
        targetDuration: targetDuration,
        createdAt: createdAt,
        updatedAt: updatedAt,
        warmup: warmup,
        main: main,
        cooldown: cooldown,
      );
    } catch (_) {
      return null;
    }
  }

  CustomWorkoutTemplate copyWith({
    String? id,
    String? name,
    WorkoutDuration? targetDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CustomWorkoutExerciseEntry>? warmup,
    List<CustomWorkoutExerciseEntry>? main,
    List<CustomWorkoutExerciseEntry>? cooldown,
  }) {
    return CustomWorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDuration: targetDuration ?? this.targetDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      warmup: warmup ?? List<CustomWorkoutExerciseEntry>.from(_warmup),
      main: main ?? List<CustomWorkoutExerciseEntry>.from(_main),
      cooldown: cooldown ?? List<CustomWorkoutExerciseEntry>.from(_cooldown),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomWorkoutTemplate) return false;
    if (id != other.id) return false;
    if (name != other.name) return false;
    if (targetDuration != other.targetDuration) return false;
    if (createdAt != other.createdAt) return false;
    if (updatedAt != other.updatedAt) return false;
    if (_warmup.length != other._warmup.length) return false;
    if (_main.length != other._main.length) return false;
    if (_cooldown.length != other._cooldown.length) return false;
    for (int i = 0; i < _warmup.length; i++) {
      if (_warmup[i] != other._warmup[i]) return false;
    }
    for (int i = 0; i < _main.length; i++) {
      if (_main[i] != other._main[i]) return false;
    }
    for (int i = 0; i < _cooldown.length; i++) {
      if (_cooldown[i] != other._cooldown[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        targetDuration,
        createdAt,
        updatedAt,
        Object.hashAll(_warmup),
        Object.hashAll(_main),
        Object.hashAll(_cooldown),
      );

  @override
  String toString() => 'CustomTemplate(id:$id name:$name duration:$targetDuration total:$totalExerciseCount)';
}
