# Home Workout icon generation

Built-in imagegen, 25 October 2026. Mechanical output sizing with System.Drawing; no CLI fallback or added dependency.

Final prompt:

> Use case: logo-brand. Create a polished original Android app icon for Home Workout. Square full-bleed opaque slate background #202526, one bold centered citrus #D4E779 symbol combining a simple house roof with a horizontal dumbbell beneath it, balanced elegant geometric rounded strokes, instantly legible at tiny launcher size. Minimal premium fitness identity. Flat clean graphic, no gradients, no mockup, no lettering, no words, no badges, no border, no rounded outer corners, no external shadow. Keep the complete symbol within the central 60 percent of the square for safe Android icon masking. 1024 by 1024.

Project outputs: `docs/release/artwork/play_store_icon.png` and `assets/images/branding/home_workout_icon.png`, both 512×512. Launcher densities are 48/72/96/144/192px. Native logo is 432px at xxxhdpi with adaptive-mask inset. Launch text is separate, keeping the app icon text-free.

## 18 November 2026 — approved icon (male + female, house, dumbbell)

The older citrus-symbol icon above is superseded by the approved artwork:
two fitness models, a house symbol and a dumbbell, no text.

Source of truth: `docs/release/artwork/play_store_icon.png` (the approved
512x512 export, unmodified). It is a rounded-square composition on a white
canvas; nothing inside the squircle is redrawn, recoloured or re-proportioned.

Everything launched from it is reproducible with
`python3 tools/media/build_launcher_icons.py`:

| Output | Size | Notes |
| --- | --- | --- |
| `res/mipmap-<density>/ic_launcher.png` | 48 / 72 / 96 / 144 / 192 | Legacy icon, white canvas replaced by the icon's own dark field so there are no white corners. |
| `res/mipmap-<density>/ic_launcher_round.png` | 48 / 72 / 96 / 144 / 192 | Same artwork inside a dark disc with a circular alpha mask. |
| `res/mipmap-<density>/ic_launcher_foreground.png` | 108 / 162 / 216 / 324 / 432 | Adaptive foreground, artwork at 73/108 of the canvas, transparent outside. |
| `res/mipmap-<density>/ic_launcher_background.png` | 108 / 162 / 216 / 324 / 432 | Adaptive background, dark green radial field (#0E221D to #06120F). |
| `assets/images/branding/home_workout_icon.png` | 512 | Flutter splash artwork, squircle on transparency, unchanged frame and characters. |

Safe-area measurement: on the approved artwork the outermost key element (the
dumbbell's lower corners) sits at 49% of the artwork width from the centre, so
73/108 is the largest foreground scale that keeps both heads, the house symbol
and the dumbbell inside the 72 dp safe circle. Scaling up further clips the
dumbbell on circular launcher masks.

Play listing icon: `docs/release/artwork/play_store_icon.png` is the approved
512x512 PNG as delivered (RGB, 363 KB, under the 1 MB Play limit) and is never
used as an Android launcher resource.

Splash: Android 12+ keeps the transparent `windowSplashScreenAnimatedIcon` from
`values-v31/styles.xml`, and the native starting window stays a flat
`launch_background_color`. The single brand mark is the icon above, painted by
the existing Flutter splash. No native logo is added, so there is no duplicate
or competing splash.

