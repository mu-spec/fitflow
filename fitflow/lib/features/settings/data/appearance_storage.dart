import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the appearance preference.
///
/// [save] is a checked API: it reports the raw write result and never
/// swallows it, so callers can keep the UI truthful about what was
/// actually persisted.
class AppearanceStorage {
  AppearanceStorage(this._prefs, {Future<bool> Function(SharedPreferences prefs, String key, String value)? writeString})
      : _writeString = writeString;

  final SharedPreferences _prefs;

  /// Injectable write seam (same pattern as other storages) so tests can
  /// simulate failed or slow persistence without plugin internals.
  final Future<bool> Function(SharedPreferences prefs, String key, String value)? _writeString;

  static const String appearanceKey = 'appearance_mode';

  Future<AppearanceMode> load() async {
    final raw = _prefs.getString(appearanceKey);
    return AppearanceMode.fromString(raw);
  }

  /// Persists [mode]. Returns whether the write succeeded — callers MUST
  /// check the result before treating the mode as active.
  Future<bool> save(AppearanceMode mode) {
    final write = _writeString;
    if (write != null) {
      return write(_prefs, appearanceKey, mode.name);
    }
    return _prefs.setString(appearanceKey, mode.name);
  }
}
