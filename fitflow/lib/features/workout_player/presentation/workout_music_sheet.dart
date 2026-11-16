import 'package:flutter/material.dart';
import '../application/workout_music.dart';

Future<void> showWorkoutMusic(BuildContext context, WorkoutMusic music) =>
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
            child: AnimatedBuilder(
                animation: music,
                builder: (context, _) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Workout music',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Background music'),
                              subtitle: const Text(
                                  'Plays with your workout. Pauses when you pause.'),
                              value: music.enabled,
                              onChanged: music.setEnabled),
                          const SizedBox(height: 12),
                          for (var i = 0; i < workoutTracks.length; i++)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                            color: music.track == i
                                                ? Colors.blue
                                                : Colors.black12)),
                                    leading: Icon(music.track == i
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off),
                                    title: Text(workoutTracks[i]),
                                    subtitle: Text(i == 0
                                        ? 'Electronic drive · 128 BPM'
                                        : 'Club energy · 140 BPM'),
                                    onTap: () => music.selectTrack(i))),
                          const SizedBox(height: 8),
                          Text(
                              'Music volume · ${(music.level * 100).round()}%'),
                          Slider(
                              value: music.level, onChanged: music.setVolume),
                          Text(music.error ??
                              (music.loading
                                  ? 'Loading music…'
                                  : music.playing
                                      ? 'Playing'
                                      : music.enabled
                                          ? 'Ready — resume your workout to play'
                                          : 'Music off')),
                          if (music.error != null)
                            TextButton(
                                onPressed: music.retry,
                                child: const Text('Retry music')),
                          const SizedBox(height: 16),
                          const Text(
                              'Instrumental tracks by Kevin MacLeod (incompetech.com). Licensed under Creative Commons Attribution 4.0. Available offline.',
                              style: TextStyle(fontSize: 12)),
                          const SelectableText(
                              'creativecommons.org/licenses/by/4.0/',
                              style: TextStyle(fontSize: 12)),
                        ])))));
