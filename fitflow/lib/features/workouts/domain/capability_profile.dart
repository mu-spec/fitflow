import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_source.dart';
import 'package:fitflow/features/workouts/domain/movement_capability.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Immutable complete per-movement ability state.
///
/// Contains exactly one entry for each of the 10 trainable movement patterns.
@immutable
class CapabilityProfile {
  CapabilityProfile._(Map<MovementPattern, MovementCapability> capabilities)
      : _capabilities = Map.unmodifiable(capabilities);

  /// Canonical collection of trainable patterns (10), excludes warmup/cooldown.
  static const List<MovementPattern> trainablePatterns = [
    MovementPattern.push,
    MovementPattern.pull,
    MovementPattern.squat,
    MovementPattern.lunge,
    MovementPattern.hinge,
    MovementPattern.core,
    MovementPattern.glute,
    MovementPattern.cardio,
    MovementPattern.mobility,
    MovementPattern.balance,
  ];

  final Map<MovementPattern, MovementCapability> _capabilities;

  /// Unmodifiable view of capabilities.
  Map<MovementPattern, MovementCapability> get capabilities =>
      Map.unmodifiable(_capabilities);

  /// All capabilities as list.
  List<MovementCapability> get all => List.unmodifiable(_capabilities.values);

  /// Returns capability for given pattern, or null if not found or non-trainable.
  MovementCapability? capabilityFor(MovementPattern pattern) {
    if (!_isTrainable(pattern)) return null;
    return _capabilities[pattern];
  }

  /// Operator for convenient lookup, returns null for unsupported patterns.
  MovementCapability? operator [](MovementPattern pattern) => capabilityFor(pattern);

  /// Whether profile contains exactly the 10 trainable patterns.
  bool get isComplete {
    if (_capabilities.length != trainablePatterns.length) return false;
    for (final pattern in trainablePatterns) {
      if (!_capabilities.containsKey(pattern)) return false;
    }
    return true;
  }

  /// Validation similar to Exercise.validate().
  List<String> validate() {
    final problems = <String>[];
    if (_capabilities.length != trainablePatterns.length) {
      problems.add('profile must contain exactly ${trainablePatterns.length} trainable patterns, found ${_capabilities.length}');
    }
    for (final pattern in trainablePatterns) {
      final cap = _capabilities[pattern];
      if (cap == null) {
        problems.add('missing capability for ${pattern.name}');
      } else {
        if (cap.movementPattern != pattern) {
          problems.add('capability key ${pattern.name} mismatches capability movementPattern ${cap.movementPattern.name}');
        }
        problems.addAll(cap.validate().map((p) => '${pattern.name}: $p'));
      }
    }
    // Check for unexpected warmup/cooldown entries
    for (final entry in _capabilities.entries) {
      if (!_isTrainable(entry.key)) {
        problems.add('profile must not contain ${entry.key.name}');
      }
    }
    return problems;
  }

  bool get isValid => validate().isEmpty;

  static bool _isTrainable(MovementPattern pattern) {
    return trainablePatterns.contains(pattern);
  }

  /// Neutral factory for initial capability profile.
  ///
  /// Level 1 for every trainable movement with initialAssessment source.
  /// Requires deterministic updatedAt for tests (avoid DateTime.now() scattered).
  factory CapabilityProfile.initial({required DateTime updatedAt}) {
    final map = <MovementPattern, MovementCapability>{};
    for (final pattern in trainablePatterns) {
      map[pattern] = MovementCapability(
        movementPattern: pattern,
        level: CapabilityLevel.level1,
        source: CapabilitySource.initialAssessment,
        updatedAt: updatedAt,
      );
    }
    return CapabilityProfile._(map);
  }

  /// Alias for initial, clearer naming alternative.
  factory CapabilityProfile.defaultProfile({required DateTime updatedAt}) {
    return CapabilityProfile.initial(updatedAt: updatedAt);
  }

  /// Factory from explicit map, validates completeness internally (but does not throw).
  /// If map is incomplete or contains invalid entries, it still creates profile,
  /// but validate() will report problems.
  factory CapabilityProfile.fromMap(
      Map<MovementPattern, MovementCapability> map) {
    // Defensive copy, ensure unmodifiable inside
    return CapabilityProfile._(Map<MovementPattern, MovementCapability>.from(map));
  }

  /// Immutable update: replace only matching movement, preserve others.
  CapabilityProfile withCapability(MovementCapability updatedCapability) {
    if (!_isTrainable(updatedCapability.movementPattern)) {
      // Invalid pattern, return self unchanged (do not crash)
      return this;
    }
    final newMap = Map<MovementPattern, MovementCapability>.from(_capabilities);
    newMap[updatedCapability.movementPattern] = updatedCapability;
    return CapabilityProfile._(newMap);
  }

  /// Optional lightweight JSON for future persistence.
  Map<String, dynamic> toJson() {
    return {
      'capabilities': _capabilities.values.map((c) => c.toJson()).toList(),
    };
  }

  /// Parses from JSON, ignores unknown/malformed entries safely, never crashes.
  /// Returns profile with only valid trainable entries; if incomplete, validate() will fail.
  static CapabilityProfile? fromJson(Map<String, dynamic> json) {
    try {
      final list = json['capabilities'] as List?;
      if (list == null) return null;
      final map = <MovementPattern, MovementCapability>{};
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final cap = MovementCapability.fromJson(item);
        if (cap == null) continue;
        // Only accept trainable, and last wins if duplicates
        if (!trainablePatterns.contains(cap.movementPattern)) continue;
        map[cap.movementPattern] = cap;
      }
      return CapabilityProfile._(map);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CapabilityProfile) return false;
    if (_capabilities.length != other._capabilities.length) return false;
    for (final pattern in _capabilities.keys) {
      final a = _capabilities[pattern];
      final b = other._capabilities[pattern];
      if (a != b) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // Order-independent hash based on trainablePatterns order
    var hash = 0;
    for (final pattern in trainablePatterns) {
      final cap = _capabilities[pattern];
      hash = hash ^ (cap?.hashCode ?? 0);
    }
    return hash;
  }

  @override
  String toString() {
    final entries = trainablePatterns
        .map((p) => '${p.name}=${_capabilities[p]?.level.name ?? 'missing'}')
        .join(', ');
    return 'CapabilityProfile($entries)';
  }
}
