# Illustrated athlete authoring

Optional **development tools** only; there is no Node, Python or network
runtime dependency in Flutter. The generated images are locally modified
illustrations using the approved character from
`assets/animations/bodyweight_squat.json`, itself adapted from Dinh Bui Xuan's
LottieFiles [Jumping squats](https://lottiefiles.com/free-animation/jumping-squats-9hzVV8Ohi6).
All outputs using that artwork are derivative works under the Lottie Simple
License in `assets/animations/illustrated_athletes/NOTICE.md`. Neither Dinh
Bui Xuan nor the upstream pose author created, reviewed or endorsed them.

`extract_character.cjs` renders transparent components of the original squat
character at a grounded frame and extracts 85 whole-squat frames. The Python
builder retargets these character parts to side-view joint rigs, narrows body
segments across their axes without moving joint endpoints, and tapers the hip.
The slim silhouette is inspired by the Jumping Jack reference, but it is not
a direct extraction of the Jumping Jack body. Props are drawn separately.
The rig builder produces 37 looping WebPs and nine single-frame holds. The
squat tools produce five other full-character WebPs, including the chair.
Side-view limbs
and weights may overlap; hand grips and details are approximate. Isometric
holds deliberately do not loop a different exercise. Form and intermediate
poses must be reviewed by a qualified fitness professional before release.
The builder rejects joints more than 4 cm below its floor, checks wall-push-up
wrist contact and checks support during selected standing marches; these are
geometric sanity checks, not a form or safety certification.

## Pose attribution

The joint solver `oef_render.py` is from Open Exercise Figures, pinned to
`a0574d54baaf23f5784dfdebd5c65f6a87fd5194`; its copyright and MIT-0 terms
are in `LICENSE-MIT-0.txt`. Poses in `rigs/` and the previous
`tools/open_exercise_figures/` rigs are either locally authored or adapted from
that project's CC0 1.0 figures. CC0 notice and legal text are in
`assets/animations/open_exercise_figures/`. Retargeted images also incorporate
the Lottie artwork and therefore are provided under the Lottie Simple License.

Merged, locally modified source figure IDs, for reproducibility:

| Output | CC0 figure source / local change |
| --- | --- |
| `dead_bug`, `bridge_glute`, `bridge_single_leg` | `0276`, `3013`, `3645` |
| `squat_split_static`, `calf_raise`, `reverse_crunch` | `2368`, `1373`, `0872`; smaller reverse-crunch curl |
| `mountain_climbers`, `bridge_march`, `flutter_kicks`, `leg_raise`, `fast_feet` | `0630`, `3561`, `0459`, `0865`, `3196`; add intermediate planted-foot poses for mountain climbers |
| `squat_goblet_kettlebell`, `squat_goblet_dumbbell`, `squat_knee_drive` | `0534`; draw specified separate weights, or omit the weight and alternate knee drives |
| `lunge_forward`, `shoulder_tap` | `3470`, `3699`; local alternating-side copies |
| `deadlift_kettlebell`, `squat_split_bulgarian`, `dip_chair`, `scapular_pullup` | `0300`, `0410`, `1399`, `0688`; change equipment, leg positions, and bar position; reduce scapular travel |
| `plank_forearm`, `hamstring_stretch_standing` | `pulse-0003`, `1511`; choose/adjust a single hold pose |
| `bird_dog`, `plank_reach`, `donkey_kick`, `pushup_wall`, `march_in_place`, `high_knees`, `standing_knee_raise`, `mountain_climber_standing` | Local side-view pose rigs under `tools/open_exercise_figures/` |
| `good_morning`, `hip_hinge`, `hip_hinge_single_leg`, `lunge_reverse`, `row_bent_over_dumbbell` | Previous locally adapted rigs; reverse lunge includes an alternating copy |
| `superman`, `row_resistance_band`, `plank_knee`, `wall_sit`, `hollow_hold`, `single_leg_stand`, `hip_flexor_stretch`, `childs_pose`, `butt_kicks`, `row_towel`, `dead_hang_pullup_bar` | Newly authored side-view pose rigs and props |

`slim_squat_art.py` narrows transparent whole-body squat frames smoothly
through the torso and legs while preserving the head and the floor-contact area;
this is separate from the joint-based retargeting. `squat_chair` composites the
result over a chair and wall. Bodyweight Squat has a 2.5-second cycle. Partial
Squat uses source frames 9–15; Tempo Squat uses 9–30 with three seconds down,
a one-second pause and one second up; Squat Pulse loops 24–29.

## Rebuild

Install Node.js, Python 3, Pillow with animated WebP, NumPy and a working
headless Chromium (Puppeteer's pinned dependency downloads Chromium). From
the app root:

```sh
cd tools/illustrated_athletes
npm install
node extract_character.cjs character_parts
python3 build_squats.py character_parts
python3 build_character_rigs.py character_parts --workers 2
python3 test_slim_squat_art.py
```

The builders write 480×480 assets into
`assets/animations/illustrated_athletes/`. Browser and WebP versions may alter
pixels slightly. Generated `frames/`, `character_parts/` and `node_modules/`
are not source files. The two JSON animations are downloaded from the credited
source pages; the Jumping Jack shoe image was embedded for offline use.
