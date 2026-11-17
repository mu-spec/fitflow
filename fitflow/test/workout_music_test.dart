import 'package:flutter/material.dart';
import 'package:fitflow/features/workout_player/presentation/workout_music_sheet.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitflow/features/workout_player/application/workout_music.dart';

class FakeMusic implements MusicTransport {
  int plays = 0, pauses = 0, loads = 0;
  double lastVolume = 1;
  bool failLoad = false;
  bool disposed = false;
  Completer<void>? loading;
  @override
  Future<void> load(int track) async {
    loads++;
    if (failLoad) throw StateError("offline decode failure");
    await loading?.future;
  }

  @override
  Future<void> play() async {
    plays++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> volume(double value) async {
    lastVolume = value;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  testWidgets('music settings fit a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final music = WorkoutMusic(FakeMusic(), persist: false);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showWorkoutMusic(context, music),
                    child: const Text('Music'))))));
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    expect(find.text('Workout music'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    music.dispose();
  });

  test('coach speech ducks music then restores chosen volume', () async {
    final backend = FakeMusic();
    final music = WorkoutMusic(backend, persist: false);
    music.setVolume(.6);
    music.setSpeaking(true);
    expect(backend.lastVolume, closeTo(.15, .001));
    music.setSpeaking(false);
    expect(backend.lastVolume, .6);
    music.dispose();
  });
  test('failed audio load stays silent and can retry', () async {
    final backend = FakeMusic()..failLoad = true;
    final music = WorkoutMusic(backend, persist: false);
    music.setEnabled(true);
    music.updateSession(true);
    await music.settled;
    expect(music.error, isNotNull);
    expect(music.playing, false);
    backend.failLoad = false;
    music.retry();
    await music.settled;
    expect(music.error, isNull);
    expect(music.playing, true);
    music.dispose();
  });
  test('focus loss pauses both and focus return does not resume', () async {
    var pauses = 0;
    final backend = FakeMusic();
    final music =
        WorkoutMusic(backend, persist: false, onInterruption: () => pauses++);
    music.setEnabled(true);
    music.updateSession(true);
    await music.settled;
    final playsBeforeInterruption = backend.plays;
    music.audioInterrupted(began: true);
    await music.settled;
    expect(pauses, 1);
    expect(music.active, false);
    expect(music.playing, false);
    music.audioInterrupted(began: false);
    await music.settled;
    expect(backend.plays, playsBeforeInterruption);
    music.dispose();
  });
  test('unplugging headphones pauses both', () async {
    var pauses = 0;
    final backend = FakeMusic();
    final music =
        WorkoutMusic(backend, persist: false, onInterruption: () => pauses++);
    music.setEnabled(true);
    music.updateSession(true);
    await music.settled;
    music.headphonesDisconnected();
    await music.settled;
    expect(pauses, 1);
    expect(music.playing, false);
    music.dispose();
  });
  test('speech completion cannot cancel a system volume reduction', () async {
    final backend = FakeMusic();
    final music = WorkoutMusic(backend, persist: false);
    music.setVolume(.8);
    music.audioInterrupted(began: true, duck: true);
    music.setSpeaking(true);
    music.setSpeaking(false);
    expect(backend.lastVolume, .2);
    music.audioInterrupted(began: false, duck: true);
    expect(backend.lastVolume, .8);
    music.dispose();
  });
  test('music follows pause/resume without reloading the track', () async {
    final backend = FakeMusic();
    final music = WorkoutMusic(backend, persist: false);
    music.setEnabled(true);
    await music.settled;
    expect(backend.plays, 0);
    music.updateSession(true);
    await music.settled;
    expect(backend.plays, 1);
    music.updateSession(false);
    await music.settled;
    expect(music.playing, false);
    music.updateSession(true);
    await music.settled;
    expect(backend.loads, 1);
    expect(backend.plays, 2);
    music.dispose();
  });
  test('pause during loading cannot start delayed audio', () async {
    final backend = FakeMusic()..loading = Completer<void>();
    final music = WorkoutMusic(backend, persist: false);
    music.setEnabled(true);
    music.updateSession(true);
    await Future<void>.delayed(Duration.zero);
    music.updateSession(false);
    backend.loading!.complete();
    await music.settled;
    expect(backend.plays, 0);
    music.dispose();
  });
  test('leaving during loading cannot start audio', () async {
    final backend = FakeMusic()..loading = Completer<void>();
    final music = WorkoutMusic(backend, persist: false);
    music.setEnabled(true);
    music.updateSession(true);
    await Future<void>.delayed(Duration.zero);
    music.dispose();
    backend.loading!.complete();
    await music.settled;
    await Future<void>.delayed(Duration.zero);
    expect(backend.plays, 0);
    expect(backend.disposed, true);
  });
  test('re-selecting the bundled track while paused does not reload it',
      () async {
    final backend = FakeMusic();
    final music = WorkoutMusic(backend, persist: false);
    expect(workoutTracks, hasLength(workoutTrackAssets.length));
    music.setEnabled(true);
    music.updateSession(true);
    await music.settled;
    expect(backend.loads, 1);
    music.updateSession(false);
    music.selectTrack(0);
    await music.settled;
    expect(backend.loads, 1);
    music.updateSession(true);
    await music.settled;
    expect(backend.loads, 1);
    music.dispose();
  });
}
