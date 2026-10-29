# Exercise motion pilot — 28 October 2026

> **Historical / withdrawn:** The user rejected the Forge Leg Raise after seeing this pilot. The local project has been restored to the audited pre-Forge configuration; this document describes an earlier experiment, not currently installed Forge assets or an approved solution. The historical pilot source ZIP is not currently present in this workspace.

## Scope and honesty

This is a small, zero-cost implementation pilot, not a finished 88-exercise
library. It replaces **two** rejected illustrated mappings with new candidate
motion clips. The original user-preferred **Jumping Jacks** remains unchanged.
The new clips use the same clothed 3D Forge Motion character as each other,
but they are not the same 2D artwork as Jumping Jacks. All remaining 56
previously rejected mapped exercises still use their prior candidates by
default; 29 others continue to use existing photo fallbacks. The temporary
`FITFLOW_JUMPING_JACK_ONLY` flag still makes everything except Jumping Jacks
use photos, including these two pilots.

Neither the new clips nor the rest of the app have received qualified
fitness-professional form review. Visual inspection and app tests cannot prove
a safe individual range, loading, anatomical alignment or user preference.
These clips are candidates for evaluation, not certified coaching guidance.

## How the two sources were checked

The app catalog and its equipment requirements were compared to the actual
32-frame motion, not to the Forge `map.json` substitutions. Both source
camera angles were examined for these movements, and **every frame** of the
selected angle was visually inspected. A few source clips were rejected for
obvious mismatches or artifacts, including the Forge glute bridge (head
intersects/disappears into the mat), mountain climber (knees drop to the
floor), calf raise (dumbbells), and static lunge (narrow foot placement in
the alternative angle). Other clips have not been accepted just because they
share this character.

| FitFlow ID | Source and fit | Visible limits |
| --- | --- | --- |
| `squat_bodyweight` | `squat_bw_m_b`, second camera angle. With no equipment, the feet stay in place while hips and knees flex and the figure returns to standing. Both legs and shoes are visible in this angle. | Camera perspective and shadows do not establish load on the whole foot or precise three-dimensional knee-to-toe tracking. Character anatomy and depth have not been reviewed by a professional. |
| `leg_raise` | `leg_raise_m`, first camera angle. Lying on a mat, the figure raises the extended legs toward vertical and lowers them, with arms beside the hips. A mat is a surface, not a required piece of workout equipment. | The angle cannot prove sustained lower-back contact or a safe range for an individual. Hands and legs partially overlap. Not professionally reviewed. |

Both are **unverified candidates**, not passes. The checked Forge goblet
squat uses a different dumbbell grip from the catalog; it was not assigned.
The same-artist Lottie Lunge was also considered, but it uses a different
character from the user's preferred Jumping Jack, so it was not introduced
as a same-body replacement. In particular, no clips were automatically
assigned by name and no video was filmed by the user.

## Asset and code changes

The public CC0 source is recorded in `assets/animations/forge_motion/NOTICE.md`.
Each source's 32 cropped sprite frames are re-encoded in order as a 640 × 640
animated WebP (75 ms per frame; 2.4 seconds per loop). The images are not
redrawn, pose-warped, or motion-retargeted. Re-encoding is lossy. No workout
instructions, equipment, prescriptions, actions or session clocks were changed.

The existing shared Flutter media widget handles visibility, pausing, app
lifecycle, reduced motion and image-error photo fallback. For the two 3D
files, decoding can retain up to the source's 640-pixel width and the
letterbox uses a dark studio background. The same Flutter registry is used in
the library and player; when the Jack-only safeguard is enabled, its photo
fallback takes priority.

The audit JSON was updated to point to the two new assets and to record their
actual hashes, 32-frame counts and limitations. The older artwork remains on
disk and was not destructively replaced; its baseline observations are
historical. `MOTION_AUDIT.md` retains the remaining per-exercise findings.

## Reproduction and checks

`tools/forge_motion/build_pilot.py` downloads hash-checked sprite sheets from
a pinned media commit and repacks them with Pillow. It does not require
Blender or introduce runtime network access. The app bundles the resulting
files and shows both the Lottie and Forge license notices offline.

Tests cover exact registry assignments, asset decoding and frame timing,
on-screen playback, pause/resume, lifecycle, reduced motion, photo fallback,
credits, the existing Jack-only safeguard, and workout-state independence.
Flutter analysis, 70 focused Flutter tests, 3 additional Jack-only gate tests,
and 5 Python tests passed in this environment. An additional broad UI run was
stopped after 36 tests had passed while the next file was loading; that full
run was not completed. The packaged copy also passed 11 focused Flutter tests
and the audit checks. There was no Android APK or physical-device test. These
are technical checks, not form certification.
