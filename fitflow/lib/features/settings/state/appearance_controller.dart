import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injectable persistence seam for the appearance preference. Tests can
/// override this to simulate failed or slow writes; production uses the
/// real [AppearanceStorage].
typedef AppearanceStorageFactory = AppearanceStorage Function(
  SharedPreferences prefs,
);

final appearanceStorageFactoryProvider = Provider<AppearanceStorageFactory>(
  (ref) => AppearanceStorage.new,
);

/// Holds the active appearance mode and keeps it in sync with local storage.
///
/// Persistence contract (M19 Part 2): state only ever reflects a mode that
/// was successfully persisted. Failed or slow writes never leave an unsaved
/// mode active.
class AppearanceController extends AsyncNotifier<AppearanceMode> {
  bool _saving = false;

  /// Whether a [setMode] write is currently in flight.
  bool get isSaving => _saving;

  AppearanceStorage _storage(SharedPreferences prefs) =>
      ref.read(appearanceStorageFactoryProvider)(prefs);

  @override
  Future<AppearanceMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _storage(prefs).load();
  }

  /// Re-reads the persisted mode (used after a backup restore) so the theme
  /// switches immediately without a loading flash. Performs no save.
  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncData(await _storage(prefs).load());
  }

  /// Persist-first save: writes [mode] to storage and only publishes the new
  /// state after the write succeeded.
  ///
  /// Returns whether the new mode is now the persisted, active mode.
  /// Returns `false` (and keeps the previous mode) when the write reports
  /// failure, throws, or another write is already in flight.
  Future<bool> setMode(AppearanceMode mode) async {
    if (_saving) {
      return false;
    }
    _saving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await _storage(prefs).save(mode);
      if (saved) {
        state = AsyncData(mode);
      }
      return saved;
    } on Object {
      // Persistence failed: the previous mode stays active and truthful.
      return false;
    } finally {
      _saving = false;
    }
  }
}

/// App-wide provider for the selected appearance mode.
final appearanceControllerProvider =
    AsyncNotifierProvider<AppearanceController, AppearanceMode>(
  AppearanceController.new,
);
