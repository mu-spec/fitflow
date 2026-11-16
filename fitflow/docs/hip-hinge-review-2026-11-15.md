# Hip Hinge review

Status: owner approved and integrated 15 November 2026. Seventeen of 25
animations are approved and integrated. No APK built.

Publication: tools/squat_sample/publish_hinge.py copied the exact approved
composition and poster into the app. Only name and approval metadata changed.
The other 24 animation/poster pairs were hash-verified unchanged. All three
targeted launch25 integration tests passed.

Video follow-up: inspected 12 samples across the owner's 7.29-second recording
(WhatsApp Video 2026-11-15 at 12.40.51 PM.mp4). The prior hip travel produced
about 30 degrees of knee bend and looked squat-like. Reduced hip travel from
55 to 35 source units, limiting the rig knee bend to about 20 degrees, and
torso tilt from 50 to 45 degrees. These are demonstration choices, not universal
clinical angle limits. ACE's Hip Hinge exercise-library guidance supports
slight knee movement and a midway forward lean; its dowel hand position differs
from this app's hands-on-hips variation.
Reference: https://www.acefitness.org/resources/everyone/exercise-library/33/hip-hinge/

The targeted renderer passed after this change. All 80 authored poses also
passed checks for stationary shoes, common head/neck/trunk transforms and an
exactly closed loop. Existing source-contour and fixed-palm checks passed.
Latest preview: build/hinge-review/hip_hinge-video-corrected.gif

The candidate reposes Military Push Ups artwork with translation and rotation.
Head, torso, hands, shorts, shoes and limb contours retain source paths and
part sizes. Arms use the original bent pose at frame 31. The far leg reuses
the original near-leg pieces with a small depth offset. The far arm similarly
reuses the original near-arm contours behind the visible arm. No muscles are
redrawn. The posterior shirt hem is anchored directly to the shorts waistband
throughout the loop, replacing the earlier center-pivot translation offsets.

Revised after owner feedback: hands contact the side of the pelvis below the
waistband; elbow reach is reduced compared with the prior high hand target.
The original clothing trim follows the torso rather than the upper arm, which
removes the stray orange edge. Far-arm layering no longer protrudes over the
back or through the chest. Source proportions and 2.68-second pacing remain.

Hand movement follow-up: the previous independently rotated hand created a
visible wrist bend while standing. The solver now fixes the palm center at the
source hip landmark and solves the elbow, wrist and hand together. The wrist
and palm axes align with the forearm through all 80 authored poses, while the
original hand outline and limb lengths remain intact. Both palms follow their
hip contact instead of sliding independently. This matches the catalog's
hands-on-hips variant; other hip-hinge variants can use different arm positions.

Hands stay at the hips; feet remain planted, shins vertical, knees softly bent
and hips move back while the torso tips forward. One loop lasts 2.68 seconds,
matching the push-up demonstration pace. Workout timing is unaffected.

Validation: source-path equality, rigid transforms, retained thigh length,
vertical shins, continuous posterior waist contact, wrist/hand attachment and
fixed palm-to-hip contact with retained forearm length, plus
unchanged installed animation/poster hashes. The targeted
Flutter render test passed and produced 40 frames and a poster. Contact sheets
were inspected at standing, intermediate and deepest poses. This is a visual
review candidate, not an independently certified exercise-form assessment.

Authoring: tools/squat_sample/build_hinge_review.py
Rendering: tools/squat_sample/render_hinge_test.dart
Packaging: tools/squat_sample/package_hinge_review.py
Preview: build/hinge-review/hip_hinge-review.gif
