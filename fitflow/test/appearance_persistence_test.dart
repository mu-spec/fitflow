import 'dart:async';

import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/data/appearance_storage.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scripted storage used to simulate slow, failing, and throwing writes
/// through the real controller.
class ScriptedAppearanceStorage extends AppearanceStorage {
  ScriptedAppearanceStorage(
    super.prefs, {
    this.result = true,
    this.throwOnSave = false,
    this.gate,
  });

  final bool result;
  final bool throwOnSave;
  final Completer<bool>? gate;

  int saveCalls = 0;

  @override
  Future<bool> save(AppearanceMode mode) async {
    saveCalls++;
    final pending = gate;
    if (pending != null) {
      await pending.future;
    }
    if (throwOnSave) {
      throw StateError('simulated storage failure');
    }
    if (!result) {
      return false;
    }
    return super.save(mode);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer containerWith(ScriptedAppearanceStorage? storage) {
    final container = ProviderContainer(
      overrides: [
        if (storage != null)
          appearanceStorageFactoryProvider
              .overrideWithValue((prefs) => storage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AppearanceStorage.save — checked API', () {
    test('returns true and persists on success', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AppearanceStorage(prefs);

      expect(await storage.save(AppearanceMode.dark), isTrue);
      expect(
        prefs.getString(AppearanceStorage.appearanceKey),
        AppearanceMode.dark.name,
      );
    });

    test('returns false when the underlying write reports false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AppearanceStorage(
        prefs,
        writeString: (prefs, key, value) async => false,
      );

      expect(await storage.save(AppearanceMode.dark), isFalse);
      expect(prefs.getString(AppearanceStorage.appearanceKey), isNull);
    });

    test('load still falls back to system for unknown values', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'neon'},
      );
      final prefs = await SharedPreferences.getInstance();
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.system);
    });
  });

  group('AppearanceController.setMode — persist-first contract', () {
    test('System save succeeds and becomes active', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'dark'},
      );
      final container = containerWith(null);

      expect(
        await container.read(appearanceControllerProvider.future),
        AppearanceMode.dark,
      );
      final saved = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.system);

      expect(saved, isTrue);
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.system,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.system);
    });

    test('Light save succeeds and becomes active', () async {
      SharedPreferences.setMockInitialValues({});
      final container = containerWith(null);
      await container.read(appearanceControllerProvider.future);

      final saved = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.light);

      expect(saved, isTrue);
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.light,
      );
    });

    test('Dark save succeeds and becomes active', () async {
      SharedPreferences.setMockInitialValues({});
      final container = containerWith(null);
      await container.read(appearanceControllerProvider.future);

      final saved = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.dark);

      expect(saved, isTrue);
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.dark,
      );
    });

    test('failed write returns false and keeps the previous mode active',
        () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      final failing = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
        result: false,
      );
      final container = containerWith(failing);

      expect(
        await container.read(appearanceControllerProvider.future),
        AppearanceMode.light,
      );

      final saved = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.dark);

      expect(saved, isFalse);
      // The previous mode stays active — no unsaved mode is ever exposed.
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.light,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(await AppearanceStorage(prefs).load(), AppearanceMode.light);
    });

    test('exception during write returns false and keeps previous mode',
        () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      final throwing = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
        throwOnSave: true,
      );
      final container = containerWith(throwing);
      await container.read(appearanceControllerProvider.future);

      final saved = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.dark);

      expect(saved, isFalse);
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.light,
      );
    });

    test('duplicate writes are rejected while one is in flight', () async {
      SharedPreferences.setMockInitialValues({});
      final gated = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
        gate: Completer<bool>(),
      );
      final container = containerWith(gated);
      await container.read(appearanceControllerProvider.future);

      final first = container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.dark);
      // Second call while the first is still writing.
      final second = await container
          .read(appearanceControllerProvider.notifier)
          .setMode(AppearanceMode.light);

      expect(second, isFalse);
      expect(gated.saveCalls, 1);

      gated.gate!.complete(true);
      expect(await first, isTrue);
      expect(gated.saveCalls, 1);
      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.dark,
      );
    });
  });

  group('AppearanceController — startup and restore behavior', () {
    test('startup loading reads the persisted mode unchanged', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'dark'},
      );
      final container = containerWith(null);

      expect(
        await container.read(appearanceControllerProvider.future),
        AppearanceMode.dark,
      );
    });

    test('startup falls back to system when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final container = containerWith(null);

      expect(
        await container.read(appearanceControllerProvider.future),
        AppearanceMode.system,
      );
    });

    test('reload after an M18 restore activates the restored mode without '
        'any save call', () async {
      SharedPreferences.setMockInitialValues(
        {AppearanceStorage.appearanceKey: 'light'},
      );
      final scripted = ScriptedAppearanceStorage(
        await SharedPreferences.getInstance(),
      );
      final container = containerWith(scripted);

      expect(
        await container.read(appearanceControllerProvider.future),
        AppearanceMode.light,
      );

      // Simulate an M18 restore writing the appearance key directly.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppearanceStorage.appearanceKey, 'dark');

      await container.read(appearanceControllerProvider.notifier).reload();

      expect(
        container.read(appearanceControllerProvider).value,
        AppearanceMode.dark,
      );
      expect(scripted.saveCalls, 0, reason: 'reload must never save');
    });
  });
}
