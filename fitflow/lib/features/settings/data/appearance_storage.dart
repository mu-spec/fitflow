import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the appearance preference.
class AppearanceStorage {
  AppearanceStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String appearanceKey = 'appearance_mode';

  Future<AppearanceMode> load() async {
    final raw = _prefs.getString(appearanceKey);
    return AppearanceMode.fromString(raw);
  }

  Future<void> save(AppearanceMode mode) async {
    await _prefs.setString(appearanceKey, mode.name);
  }
}
