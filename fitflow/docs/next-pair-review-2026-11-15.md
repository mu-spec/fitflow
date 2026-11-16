# Reverse Lunge and Pike Push-Up previews

Approved and integrated 15 November 2026. Twenty of 25 animations are now
approved and integrated. No APK built.

tools/squat_sample/publish_next_pair.py copied the exact approved compositions
and posters, including the latest pike back revision. All other 23 asset/poster
pairs were hash-verified unchanged. Reverse Lunge playback now specifies two
repetitions per loop. Three launch25 integration tests and the targeted
Reverse Lunge pacing/pause test passed. Earlier review notes below record the
development history, not the current publication status.

Pike back revision: reduced and offset the shorts joint overlap masks so they
no longer make a large root cap above the waist. Adjusted the torso from the
overly vertical orientation to a shallower inverted-V posture, preserving the
original rigid source parts. The palm target was moved slightly to keep the
original arm lengths reachable. Reverse Lunge is unchanged.
The Pike-only renderer passed after successful regeneration. Four rendered
poses retain 11 or more pixels of hair-to-hand-baseline clearance; fixed palm
and shoe positions and exact loop closure passed. Latest review GIF:
build/next-pair-review/pushup_pike-back-revised.gif. No app assets were replaced.

Reference-video revision: inspected samples through the owner's 20.10-second
8.03.38 PM Reverse Lunge recording and 6.92-second 8.00.36 PM Pike Push-Up
recording. Reverse Lunge now uses a longer backward step, greater controlled
descent and higher hip-level palm contacts. Rear foot travel finishes before
the lowering phase; the character returns upright before changing sides.
Pike Push-Up now shifts the hips/shoulders farther forward during the descent,
with more visible elbow flexion and the head moving forward of the hands.
These changes follow the reference movement while retaining the previously
requested 2.68-second repetition pace and original source parts.

The targeted renderer passed. Key poses from both repetitions were inspected.
Additional asset checks passed for loop closure, fixed pike palms/feet and
stationary lunge feet during each lowering/raising phase. Neither preview
replaces an installed app asset yet.
Latest GIFs: lunge_reverse-reference-matched.gif and
pushup_pike-reference-matched.gif in build/next-pair-review.

Both candidates reuse Military Push Ups source paths and original part sizes.
No muscle paths are redrawn. Original bent-arm artwork is reposed at joints.
Rounded overlap masks on original shorts copies connect the thigh and pelvis
without exposed square clipping edges. These masks affect the visible overlap;
the underlying source artwork is unchanged.

Reverse Lunge steps back, lowers, rises and returns before switching legs.
Hands stay near the hips and the trunk stays upright. Its two-repetition loop
lasts 5.36 seconds. On future integration set repetitionsPerLoop to 2 for
lunge_reverse, preserving the shared 2.68-second repetition pace.

Pike Push-Up keeps both palms and feet planted with hips elevated. Head depth
was adjusted after the first render. The loop lasts 2.68 seconds.

Validation: builder verifies original source paths, unit-length rigid pose
transforms and unchanged installed asset hashes. The targeted renderer passed
after revisions and produced 40 frames plus a poster per candidate. Contact
sheets were inspected, including both lunge sides and the pike bottom pose.
These previews await owner review; no independent trainer certification claimed.

Authoring: tools/squat_sample/build_next_pair_review.py
Rendering: tools/squat_sample/render_next_pair_test.dart
Previews: build/next-pair-review/lunge_reverse-review.gif and
build/next-pair-review/pushup_pike-review.gif
