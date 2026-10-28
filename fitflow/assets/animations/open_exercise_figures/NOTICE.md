# Open Exercise Figures — exercise demonstrations

These figures use [Open Exercise Figures](https://github.com/AbanoubAmir/open-exercise-figures), by Abanoub Amir and contributors, pinned to commit `a0574d54baaf23f5784dfdebd5c65f6a87fd5194`. The publisher dedicates the animation and figure files to the public domain under **CC0 1.0**; the upstream rendering code is under MIT-0. See [LICENSE-CC0.txt](LICENSE-CC0.txt), the [source license](https://github.com/AbanoubAmir/open-exercise-figures/blob/a0574d54baaf23f5784dfdebd5c65f6a87fd5194/LICENSE-CC0.txt), and [upstream README](https://github.com/AbanoubAmir/open-exercise-figures/blob/a0574d54baaf23f5784dfdebd5c65f6a87fd5194/README.md). Credit is not required but is included here for traceability. The publisher permits commercial use and offline bundling.

The local file name before `.webp` is the app's exact exercise ID. The first group is copied unchanged from upstream `animations/<source-id>.webp`:

| Home Workout exercise ID | Upstream ID | Upstream name | Note |
| --- | --- | --- | --- |
| `squat_partial` | `3221` | Half Knee Bends | Shallow squat |
| `dead_bug` | `0276` | Dead Bug | Opposite arm and leg |
| `bridge_glute` | `3013` | Low Glute Bridge On Floor | |
| `bridge_single_leg` | `3645` | Single Leg Bridge With Outstretched Leg | Free leg extended |
| `squat_split_static` | `2368` | Split Squats | Stationary stance |
| `calf_raise` | `1373` | Bodyweight Standing Calf Raise | Wall shown for optional balance |
| `reverse_crunch` | `0872` | Reverse Crunch | |
| `mountain_climbers` | `0630` | Mountain Climber | |
| `bridge_march` | `3561` | Glute Bridge March | |
| `flutter_kicks` | `0459` | Flutter Kicks | |
| `leg_raise` | `0865` | Lying Leg-Hip Raise | The source artwork depicts straight-leg raises with hips down, without the hip lift mentioned in its title |
| `fast_feet` | `3196` | Quick Feet Run | Small alternating steps |
| `squat_goblet_kettlebell` | `0534` | Kettlebell Goblet Squat | |

The following loops were authored or adapted locally using the same upstream renderer; source figures and reproducible build instructions are in `tools/open_exercise_figures/`. The upstream author did not review or endorse these changes.

| Home Workout exercise ID | Source and local change |
| --- | --- |
| `jumping_jacks` | Adapted `3224` Jack Jump: added a planted wide stance and airborne transitions |
| `squat_tempo` | Adapted `3533` bodyweight squat frames: three seconds down, one-second pause, about one second up |
| `squat_pulse` | Adapted `3533` bodyweight squat frames: short pulses at the bottom |
| `lunge_reverse` | Adapted `2368` split-squat pose into a step-back and return |
| `good_morning` | Adapted `0044` good morning: removed barbell and limited hinge range |
| `hip_hinge` | Adapted `0044` good morning: removed barbell, adjusted arm and hinge positions |
| `hip_hinge_single_leg` | Adapted `1757` single-leg deadlift: removed dumbbell and raised free foot |
| `row_bent_over_dumbbell` | Adapted `0293` dumbbell bent-over row: torso set closer to the catalog's 45-degree hinge; both arms overlap in side view |
| `bird_dog`, `donkey_kick`, `plank_reach` | New local poses on the upstream mannequin rig; bird dog and plank reach alternate sides |
| `pushup_wall` | New local wall-press poses with hands at the wall and body moving as a line |
| `high_knees`, `standing_knee_raise`, `march_in_place`, `mountain_climber_standing` | New local alternating-knee poses; the player retains its existing separate march pilot |

The publisher notes that these programmatically drawn mannequins are approximate, particularly for twists, grips, and some sideways movements. The local adaptations are also approximate and have **not been reviewed by a fitness professional**. They are visual aids, not a substitute for the app's written form cues or a trainer's assessment. Obtain qualified form review before a production release. The drawings do not control workout durations, repetitions, or timing.
