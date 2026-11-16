# Final animation batch - 16 November 2026

22 of 25 refined animations are approved and integrated. Bird Dog shoes now follow the calf/ankle transform; Doorway Row and Bird Dog were published with matching posters. Other 23 asset pairs remained unchanged during publication.

Remaining review candidates: Dead Bug, Cat-Cow, Reverse Snow Angel. Files and GIFs: build/final-three-review.

**PUBLISHED 16 November 2026.** The owner supplied the three approved review GIFs
(420x482 review packaging, 40 frames; 5360 ms for Dead Bug, 2680 ms for the other
two). Those GIFs are pixel-identical to the vector candidates rendered from this
script (mean absolute error 0.02, i.e. GIF palette noise only), so the vector
compositions were published instead of the low-resolution GIFs, matching the
other 22 exercises. `tools/squat_sample/publish_final_three.py` wrote
`assets/animations/launch25/{dead_bug,cat_cow,reverse_snow_angel}.json` plus their
720x720 posters, set `meta.review_only = false` and `meta.approved = 2026-11-16`,
and hash-verified that the other 22 motion/poster pairs were unchanged.
`repetitionsPerLoop` already read 2 / 1 / 1, and the published source durations are
exactly 5.36 s / 2.68 s / 2.68 s, so no registry or pacing change was needed and
no playback stretching is applied at runtime.

Original Military Push Ups paths are reused with rigid limb transforms. Cat-Cow additionally bends the original shirt path between fixed hip and shoulder endpoints to show spinal motion; do not claim its shirt path is byte-identical. Dead Bug alternates opposite limbs over 5.36 seconds. The other loops last 2.68 seconds, matching the app reference pace. Reverse Snow Angel uses an oblique side-art projection; review the readability of the outward arm sweep before publication.

Validation: complete-loop Flutter render; existing launch25 animation tests (3) passed; loop seams checked. No APK built.
