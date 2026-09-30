import 'dart:convert';

import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline storage for adaptive program state.
///
/// Key: `adaptive_programs_v1`
///
/// Root JSON:
/// ```json
/// {"activeProgramId": "...", "progress": [ {programId, startedAt, updatedAt, completions: [...]}, ... ]}
/// ```
///
/// Guarantees:
/// - malformed root → safe empty state
/// - malformed entry → skip only that entry
/// - duplicate progress IDs → deterministic (latest updatedAt wins, ties: first)
/// - duplicate completion IDs → deterministic (first wins, via model)
/// - unknown program IDs → skipped, unknown active ID → cleared
/// - immutable result
/// - `setString()` returning false → save fails
/// - exception → save fails
///
/// Does not touch workout history storage.
class AdaptiveProgramsStorage {
  const AdaptiveProgramsStorage({
    Future<SharedPreferences> Function()? getPrefs,
    Future<bool> Function(SharedPreferences prefs, String key, String value)?
        writeString,
  })  : _getPrefs = getPrefs,
        _writeString = writeString;

  static const String key = 'adaptive_programs_v1';

  final Future<SharedPreferences> Function()? _getPrefs;
  final Future<bool> Function(SharedPreferences prefs, String key, String value)?
      _writeString;

  Future<SharedPreferences> _prefs() {
    if (_getPrefs != null) return _getPrefs!();
    return SharedPreferences.getInstance();
  }

  Future<bool> _write(SharedPreferences prefs, String k, String v) {
    if (_writeString != null) return _writeString!(prefs, k, v);
    return prefs.setString(k, v);
  }

  /// Loads state; never throws.
  Future<AdaptiveProgramsState> load() async {
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) return AdaptiveProgramsState.empty;
      return decode(raw);
    } catch (_) {
      return AdaptiveProgramsState.empty;
    }
  }

  /// Pure decode of the raw JSON string. Exposed for tests.
  static AdaptiveProgramsState decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return AdaptiveProgramsState.empty;
      final root = Map<String, dynamic>.from(decoded);

      final byId = <String, AdaptiveProgramProgress>{};
      final rawProgress = root['progress'];
      if (rawProgress is List) {
        for (final item in rawProgress) {
          try {
            if (item is! Map) continue;
            final progress = AdaptiveProgramProgress.fromJson(
                Map<String, dynamic>.from(item));
            if (progress == null) continue;
            if (!AdaptiveProgramCatalog.contains(progress.programId)) continue;
            final existing = byId[progress.programId];
            if (existing == null ||
                progress.updatedAt.isAfter(existing.updatedAt)) {
              byId[progress.programId] = progress;
            }
          } catch (_) {
            continue;
          }
        }
      }

      String? active;
      final rawActive = root['activeProgramId'];
      if (rawActive is String &&
          rawActive.isNotEmpty &&
          AdaptiveProgramCatalog.contains(rawActive)) {
        active = rawActive;
      }

      return AdaptiveProgramsState(
        activeProgramId: active,
        progressByProgram: byId,
      );
    } catch (_) {
      return AdaptiveProgramsState.empty;
    }
  }

  /// Pure encode. Progress entries are written in sorted program-ID order for
  /// determinism.
  static String encode(AdaptiveProgramsState state) {
    final ids = state.progressByProgram.keys.toList()..sort();
    return jsonEncode({
      'activeProgramId': state.activeProgramId,
      'progress': [
        for (final id in ids) state.progressByProgram[id]!.toJson(),
      ],
    });
  }

  /// Persists [state]. Returns false when the write reports failure or throws.
  Future<bool> save(AdaptiveProgramsState state) async {
    try {
      final encoded = encode(state);
      final prefs = await _prefs();
      return await _write(prefs, key, encoded);
    } catch (_) {
      return false;
    }
  }

  Future<void> clearForTest() async {
    try {
      final prefs = await _prefs();
      await prefs.remove(key);
    } catch (_) {}
  }
}
