import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter/foundation.dart';

/// Minimal persisted positive evidence per trainable movement.
/// Stores 0 or 1 qualifying Easy signals, not workout history.
@immutable
class AdaptiveProgressionEvidence {
  const AdaptiveProgressionEvidence._(this._counts);

  final Map<MovementPattern, int> _counts;

  /// All trainable patterns with 0 evidence.
  factory AdaptiveProgressionEvidence.zero() {
    final map = <MovementPattern, int>{};
    for (final p in CapabilityProfile.trainablePatterns) {
      map[p] = 0;
    }
    return AdaptiveProgressionEvidence._(Map.unmodifiable(map));
  }

  /// Factory from map, sanitizes to trainable only and 0-1 range.
  factory AdaptiveProgressionEvidence.fromMap(Map<MovementPattern, int> raw) {
    final sanitized = <MovementPattern, int>{};
    for (final p in CapabilityProfile.trainablePatterns) {
      final v = raw[p];
      if (v == null) {
        sanitized[p] = 0;
      } else if (v < 0) {
        sanitized[p] = 0;
      } else if (v > 1) {
        sanitized[p] = 1;
      } else {
        sanitized[p] = v;
      }
    }
    return AdaptiveProgressionEvidence._(Map.unmodifiable(sanitized));
  }

  /// Returns count for pattern, 0 if missing or non-trainable.
  int countFor(MovementPattern pattern) {
    if (!CapabilityProfile.trainablePatterns.contains(pattern)) return 0;
    return _counts[pattern] ?? 0;
  }

  /// Immutable copy with updated count for pattern (sanitized to 0-1).
  AdaptiveProgressionEvidence withCount(MovementPattern pattern, int count) {
    if (!CapabilityProfile.trainablePatterns.contains(pattern)) return this;
    final sanitizedCount = count < 0 ? 0 : (count > 1 ? 1 : count);
    if (countFor(pattern) == sanitizedCount) return this;
    final newMap = Map<MovementPattern, int>.from(_counts);
    newMap[pattern] = sanitizedCount;
    return AdaptiveProgressionEvidence._(Map.unmodifiable(newMap));
  }

  /// All counts as unmodifiable map.
  Map<MovementPattern, int> get counts => Map.unmodifiable(_counts);

  /// For persistence.
  Map<String, dynamic> toJson() {
    final map = <String, int>{};
    for (final entry in _counts.entries) {
      map[entry.key.name] = entry.value;
    }
    return {
      'version': 1,
      'counts': map,
    };
  }

  static AdaptiveProgressionEvidence? fromJson(Map<String, dynamic> json) {
    try {
      final countsRaw = json['counts'] as Map?;
      if (countsRaw == null) return null;
      final parsed = <MovementPattern, int>{};
      for (final entry in countsRaw.entries) {
        final key = entry.key as String?;
        final value = entry.value;
        if (key == null) continue;
        final pattern = MovementPattern.values
            .where((p) => p.name == key)
            .cast<MovementPattern?>()
            .firstWhere((p) => p != null, orElse: () => null);
        if (pattern == null) continue;
        if (!CapabilityProfile.trainablePatterns.contains(pattern)) continue;
        if (value is! int) continue;
        if (value < 0 || value > 1) continue; // will be sanitized but we accept only valid for strict parsing; malformed handled elsewhere
        parsed[pattern] = value;
      }
      // Even if some entries invalid, we return zero-filled with parsed valid ones
      final base = AdaptiveProgressionEvidence.zero();
      var result = base;
      for (final e in parsed.entries) {
        result = result.withCount(e.key, e.value);
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Safe parsing: malformed JSON → neutral zero evidence, no crash.
  static AdaptiveProgressionEvidence fromJsonSafe(Map<String, dynamic>? json) {
    if (json == null) return AdaptiveProgressionEvidence.zero();
    try {
      final result = fromJson(json);
      return result ?? AdaptiveProgressionEvidence.zero();
    } catch (_) {
      return AdaptiveProgressionEvidence.zero();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdaptiveProgressionEvidence) return false;
    for (final p in CapabilityProfile.trainablePatterns) {
      if (countFor(p) != other.countFor(p)) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (final p in CapabilityProfile.trainablePatterns) {
      hash = hash ^ countFor(p).hashCode ^ p.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    final entries = CapabilityProfile.trainablePatterns.map((p) => '${p.name}:${countFor(p)}').join(', ');
    return 'AdaptiveProgressionEvidence($entries)';
  }
}
