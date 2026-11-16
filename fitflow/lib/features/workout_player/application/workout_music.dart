import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/workout_player_phase.dart';
import '../../workouts/domain/workout/workout_plan.dart';
import 'workout_player_controller.dart';

const workoutTracks = ['EDM Detection Mode', 'Club Diver'];
const workoutTrackAssets = [
  'assets/audio/edm_detection.mp3',
  'assets/audio/club_diver.mp3'
];

/// Transport is injectable so lifecycle and loading races can be tested.
abstract class MusicTransport {
  Future<void> load(int track);
  Future<void> pause();
  Future<void> play();
  Future<void> volume(double value);
  Future<void> dispose();
}

class OfflineMusicTransport implements MusicTransport {
  AudioPlayer? _player;
  AudioPlayer get player => _player ??= AudioPlayer(handleInterruptions: false);
  @override
  Future<void> load(int track) async {
    await player.setAsset(workoutTrackAssets[track]);
    await player.setLoopMode(LoopMode.one);
  }

  @override
  Future<void> play() => player.play();
  @override
  Future<void> pause() async {
    await _player?.pause();
  }

  @override
  Future<void> volume(double value) async {
    await _player?.setVolume(value);
  }

  @override
  Future<void> dispose() async {
    await _player?.dispose();
  }
}

class WorkoutMusic extends ChangeNotifier {
  WorkoutMusic(this.transport, {this.onInterruption, this.persist = true}) {
    if (persist) unawaited(_restore().catchError((_) {}));
  }
  final MusicTransport transport;
  final void Function()? onInterruption;
  final bool persist;
  bool enabled = false, active = false, loading = false, playing = false;
  bool _closed = false;
  bool _edited = false;
  bool _speaking = false;
  bool _ducked = false;
  double get _effectiveVolume => level * (_speaking || _ducked ? .25 : 1);
  void setSpeaking(bool speaking) {
    if (_closed) return;
    _speaking = speaking;
    unawaited(transport.volume(_effectiveVolume).catchError((_) {}));
  }

  int track = 0;
  int? _loaded;
  double level = .35;
  String? error;
  Future<void> _queue = Future.value();
  StreamSubscription<AudioInterruptionEvent>? _interruptions;
  StreamSubscription<void>? _noisy;
  bool _configured = false;
  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_closed || _edited) return;
    enabled = prefs.getBool('workout.music.enabled') ?? false;
    track = (prefs.getInt('workout.music.track') ?? 0)
        .clamp(0, workoutTracks.length - 1);
    level = (prefs.getDouble('workout.music.volume') ?? .35).clamp(0, 1);
    _sync();
  }

  void updateSession(bool running) {
    if (active == running) return;
    active = running;
    _sync();
  }

  void setEnabled(bool value) {
    _edited = true;
    enabled = value;
    unawaited(_save().catchError((_) {}));
    _sync();
  }

  void selectTrack(int value) {
    _edited = true;
    track = value;
    unawaited(_save().catchError((_) {}));
    _sync();
  }

  void setVolume(double value) {
    _edited = true;
    level = value.clamp(0, 1);
    unawaited(_save().catchError((_) {}));
    _sync();
  }

  void retry() {
    error = null;
    _loaded = null;
    _sync();
  }

  Future<void> _save() async {
    if (!persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('workout.music.enabled', enabled);
    await prefs.setInt('workout.music.track', track);
    await prefs.setDouble('workout.music.volume', level);
  }

  Future<void> _configure() async {
    if (_configured || !persist) return;
    final session = await AudioSession.instance;
    if (_closed) return;
    await session.configure(const AudioSessionConfiguration.music());
    if (_closed) return;
    _interruptions = session.interruptionEventStream.listen((event) {
      audioInterrupted(
          began: event.begin, duck: event.type == AudioInterruptionType.duck);
    });
    _noisy = session.becomingNoisyEventStream
        .listen((_) => headphonesDisconnected());
    _configured = true;
  }

  /// Focus returning never starts a workout without an explicit Resume.
  void audioInterrupted({required bool began, bool duck = false}) {
    if (_closed) return;
    if (duck) {
      _ducked = began;
      unawaited(transport.volume(_effectiveVolume).catchError((_) {}));
    } else if (began) {
      onInterruption?.call();
      updateSession(false);
    }
  }

  void headphonesDisconnected() {
    if (_closed) return;
    onInterruption?.call();
    updateSession(false);
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void _sync() {
    // Pause immediately even if an asset is still loading.
    if (!enabled || !active) {
      playing = false;
      unawaited(transport.pause().catchError((_) {}));
    }
    _notify();
    _queue = _queue.then((_) async {
      if (_closed) return;
      try {
        if (!enabled || !active) {
          await transport.pause();
          return;
        }
        await _configure();
        if (_closed || !enabled || !active) return;
        final requested = track;
        if (_loaded != requested) {
          loading = true;
          _notify();
          await transport.load(requested);
          _loaded = requested;
        }
        if (_closed || !enabled || !active || track != requested) return;
        await transport.volume(_effectiveVolume);
        if (_closed || !enabled || !active) return;
        error = null;
        playing = true;
        // play resolves when playback stops, so it must not block the queue.
        unawaited(transport.play().catchError((Object e) {
          if (!_closed) {
            error = 'Music unavailable. Tap retry.';
            playing = false;
            _notify();
          }
        }));
      } catch (_) {
        error = 'Music unavailable. Tap retry.';
        playing = false;
      } finally {
        loading = false;
        _notify();
      }
    });
  }

  Future<void> get settled => _queue;
  @override
  void dispose() {
    _closed = true;
    unawaited(_interruptions?.cancel());
    unawaited(_noisy?.cancel());
    unawaited(transport.pause().catchError((_) {}));
    unawaited(_queue.whenComplete(transport.dispose).catchError((_) {}));
    super.dispose();
  }
}

final workoutMusicProvider = ChangeNotifierProvider.autoDispose
    .family<WorkoutMusic, WorkoutPlan>((ref, plan) {
  final music = WorkoutMusic(OfflineMusicTransport(), onInterruption: () {
    ref
        .read(workoutPlayerControllerProvider(plan).notifier)
        .pauseForLifecycle();
  });
  final speech = ref.read(workoutSpeechActivityProvider);
  void speechChanged() => music.setSpeaking(speech.value);
  speech.addListener(speechChanged);
  ref.onDispose(() => speech.removeListener(speechChanged));
  speechChanged();
  ref.listen(
      workoutPlayerControllerProvider(plan).select((s) =>
          !s.isPaused &&
          (s.phase == WorkoutPlayerPhase.work ||
              s.phase == WorkoutPlayerPhase.rest ||
              s.phase == WorkoutPlayerPhase.transition)),
      (_, running) => music.updateSession(running),
      fireImmediately: true);
  return music;
});
