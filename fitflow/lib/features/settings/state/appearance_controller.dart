import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active appearance mode and keeps it in sync with local storage.
class AppearanceController extends AsyncNotifier<AppearanceMode> {
  @override
  Future<AppearanceMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppearanceStorage(prefs).load();
  }

  Future<void> setMode(AppearanceMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await AppearanceStorage(prefs).save(mode);
  }
}

/// App-wide provider for the selected appearance mode.
final appearanceControllerProvider =
    AsyncNotifierProvider<AppearanceController, AppearanceMode>(
  AppearanceController.new,
);
