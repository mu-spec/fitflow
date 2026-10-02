import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canonical SharedPreferences seam (M21 Part 1).
///
/// The plugin already caches the singleton instance, but routing every
/// acquisition through this FutureProvider guarantees exactly one
/// acquisition per container, makes the dependency injectable for tests, and
/// lets storage providers build their objects once and reuse them instead of
/// re-acquiring and re-constructing on every hot-path call.
///
/// Never cache mutable domain state here — only the preferences handle.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);
