import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Immutable per-movement capability.
///
/// Tracks ability separately for each trainable movement category.
@immutable
class MovementCapability {
  const MovementCapability({
    required this.movementPattern,
    required this.level,
    required this.source,
    required this.updatedAt,
    this.anchorExerciseId,
  });

  final MovementPattern movementPattern;
  final CapabilityLevel level;
  final CapabilitySource source;
  final DateTime updatedAt;
  final String? anchorExerciseId;

  /// Lightweight validation, similar to Exercise.validate().
  /// Returns human-readable problems; empty when valid.
  List<String> validate() {
    final problems = <String>[];
    if (!_isTrainable(movementPattern)) {
      problems.add('movementPattern ${movementPattern.name} is not trainable (warmup/cooldown excluded)');
    }
    if (anchorExerciseId != null && anchorExerciseId!.trim().isEmpty) {
      problems.add('anchorExerciseId must not be empty when provided');
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  static bool _isTrainable(MovementPattern pattern) {
    return pattern != MovementPattern.warmup &&
        pattern != MovementPattern.cooldown;
  }

  /// Whether this pattern is trainable.
  bool get isTrainablePattern => _isTrainable(movementPattern);

  MovementCapability copyWith({
    MovementPattern? movementPattern,
    CapabilityLevel? level,
    CapabilitySource? source,
    DateTime? updatedAt,
    String? anchorExerciseId,
    bool clearAnchor = false,
  }) {
    return MovementCapability(
      movementPattern: movementPattern ?? this.movementPattern,
      level: level ?? this.level,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      anchorExerciseId: clearAnchor ? null : (anchorExerciseId ?? this.anchorExerciseId),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovementCapability &&
        other.movementPattern == movementPattern &&
        other.level == level &&
        other.source == source &&
        other.updatedAt == updatedAt &&
        other.anchorExerciseId == anchorExerciseId;
  }

  @override
  int get hashCode => Object.hash(
        movementPattern,
        level,
        source,
        updatedAt,
        anchorExerciseId,
      );

  @override
  String toString() {
    return 'MovementCapability(movementPattern: ${movementPattern.name}, level: ${level.name}, source: ${source.name}, updatedAt: $updatedAt, anchorExerciseId: $anchorExerciseId)';
  }

  /// Optional lightweight JSON for future persistence (stable .name values).
  Map<String, dynamic> toJson() {
    return {
      'movementPattern': movementPattern.name,
      'level': level.name,
      'source': source.name,
      'updatedAt': updatedAt.toIso8601String(),
      if (anchorExerciseId != null) 'anchorExerciseId': anchorExerciseId,
    };
  }

  /// Parses from JSON, returns null for malformed or non-trainable entries (does not crash).
  static MovementCapability? fromJson(Map<String, dynamic> json) {
    try {
      final patternName = json['movementPattern'] as String?;
      final levelName = json['level'] as String?;
      final sourceName = json['source'] as String?;
      final updatedAtString = json['updatedAt'] as String?;

      if (patternName == null || levelName == null || sourceName == null || updatedAtString == null) {
        return null;
      }

      final pattern = MovementPattern.values
          .where((p) => p.name == patternName)
          .cast<MovementPattern?>()
          .firstWhere((p) => p != null, orElse: () => null);
      if (pattern == null) {
        return null;
      }
      if (pattern == MovementPattern.warmup ||
          pattern == MovementPattern.cooldown) {
        return null;
      }

      final level = CapabilityLevel.values
          .where((l) => l.name == levelName)
          .cast<CapabilityLevel?>()
          .firstWhere((l) => l != null, orElse: () => null);
      if (level == null) {
        return null;
      }

      final source = CapabilitySource.values
          .where((s) => s.name == sourceName)
          .cast<CapabilitySource?>()
          .firstWhere((s) => s != null, orElse: () => null);
      if (source == null) {
        return null;
      }

      final updatedAt = DateTime.tryParse(updatedAtString);
      if (updatedAt == null) {
        return null;
      }

      final anchor = json['anchorExerciseId'] as String?;

      final capability = MovementCapability(
        movementPattern: pattern,
        level: level,
        source: source,
        updatedAt: updatedAt,
        anchorExerciseId: anchor,
      );

      if (!capability.isValid) {
        return null;
      }
      return capability;
    } catch (_) {
      return null;
    }
  }
}
