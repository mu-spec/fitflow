import 'dart:convert';

import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdaptiveProgressionEvidenceStorage {
  AdaptiveProgressionEvidenceStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String evidenceKey = 'adaptive_progression_evidence_v1';

  AdaptiveProgressionEvidence load() {
    final raw = _prefs.getString(evidenceKey);
    if (raw == null) {
      return AdaptiveProgressionEvidence.zero();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return AdaptiveProgressionEvidence.zero();
      }
      // Validate version if present
      final version = decoded['version'];
      if (version != null && version != 1) {
        // For now, only version 1 supported, but treat unknown as zero for safety
        // Could be future migration point
        return AdaptiveProgressionEvidence.zero();
      }
      final countsRaw = decoded['counts'];
      if (countsRaw is! Map) {
        return AdaptiveProgressionEvidence.zero();
      }

      // Sanitize: only trainable patterns, counts 0-1
      final sanitizedMap = <MovementPattern, int>{};
      for (final p in CapabilityProfile.trainablePatterns) {
        sanitizedMap[p] = 0;
      }

      for (final entry in countsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String) continue;
        final pattern = MovementPattern.values
            .where((p) => p.name == key)
            .cast<MovementPattern?>()
            .firstWhere((p) => p != null, orElse: () => null);
        if (pattern == null) continue;
        if (!CapabilityProfile.trainablePatterns.contains(pattern)) continue; // ignore warmup/cooldown
        if (value is! int) continue;
        if (value < 0) {
          sanitizedMap[pattern] = 0;
        } else if (value > 1) {
          sanitizedMap[pattern] = 1;
        } else {
          sanitizedMap[pattern] = value;
        }
      }

      return AdaptiveProgressionEvidence.fromMap(sanitizedMap);
    } catch (_) {
      return AdaptiveProgressionEvidence.zero();
    }
  }

  Future<bool> save(AdaptiveProgressionEvidence evidence) async {
    try {
      final encoded = jsonEncode(evidence.toJson());
      return await _prefs.setString(evidenceKey, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(evidenceKey);
  }
}
