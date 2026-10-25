# Home Workout icon generation

Built-in imagegen, 25 October 2026. Mechanical output sizing with System.Drawing; no CLI fallback or added dependency.

Final prompt:

> Use case: logo-brand. Create a polished original Android app icon for Home Workout. Square full-bleed opaque slate background #202526, one bold centered citrus #D4E779 symbol combining a simple house roof with a horizontal dumbbell beneath it, balanced elegant geometric rounded strokes, instantly legible at tiny launcher size. Minimal premium fitness identity. Flat clean graphic, no gradients, no mockup, no lettering, no words, no badges, no border, no rounded outer corners, no external shadow. Keep the complete symbol within the central 60 percent of the square for safe Android icon masking. 1024 by 1024.

Project outputs: `docs/release/artwork/play_store_icon.png` and `assets/images/branding/home_workout_icon.png`, both 512×512. Launcher densities are 48/72/96/144/192px. Native logo is 432px at xxxhdpi with adaptive-mask inset. Launch text is separate, keeping the app icon text-free.
