# Home Workout icon generation

## History

The first icon (25 October 2026) was a citrus `#D4E779` house-plus-dumbbell
symbol on slate `#202526`. It is superseded and no longer shipped.

The approved icon (18 November 2026) is two fitness models in black and
neon-green sportswear on a light green field, no text, no house, no dumbbell.
Everything below describes that artwork.

## Source of truth

`docs/release/artwork/play_store_icon.png` — the approved 512×512 export, byte
for byte as delivered (RGB, ~356 KB, under the Play 1 MB limit).

It is the Play Store listing icon and is **never** used as an Android launcher
resource. It is a rounded-square composition on a white canvas; nothing inside
the squircle is redrawn, recoloured or re-proportioned.

All launcher and splash resources are reproducible with

```
python3 tools/media/build_launcher_icons.py     # writes the 21 launcher PNGs + splash plate
python3 tools/media/make_mask_check.py          # writes the visual check sheet
```

## Measurement that drives the layout

Measured on the 512 px artwork with the white canvas and the artwork's own green
field keyed out (green enclosed by the black sportswear — the neon accents —
is kept):

| Measurement | Value |
| --- | --- |
| Model silhouettes bounding box | x 19–498, y 63–497 |
| Widest-point radius of the silhouettes (crossed forearms) | 297 px = **57.9%** of the artwork width |
| Both heads | 43% of the artwork width from the centre |
| Background field, centre → rim | `#9DFB6A` → `#48E61D` |
| Rebuilt plate edge (what a full-bleed icon ends on) | `#51E621` |

Adaptive foreground scale: **62/108** of the canvas (36 dp radius ÷ 0.579 ≈ 62 dp),
so both faces, both heads, the torsos and the crossed arms stay inside the
72 dp safe area of every launcher mask.

## Outputs

| Output | Size | Notes |
| --- | --- | --- |
| `res/mipmap-<density>/ic_launcher.png` | 48 / 72 / 96 / 144 / 192 | Legacy icon (API 25 and below). White canvas keyed out and the artwork's own field grown outwards, so the icon is full-bleed and has no white corners and no pale halo. |
| `res/mipmap-<density>/ic_launcher_round.png` | 48 / 72 / 96 / 144 / 192 | Same full-bleed plate inside a circular alpha mask (`android:roundIcon`). |
| `res/mipmap-<density>/ic_launcher_foreground.png` | 108 / 162 / 216 / 324 / 432 | Adaptive foreground: the two models only, at 62/108 of the canvas, transparent everywhere else. |
| `res/mipmap-<density>/ic_launcher_background.png` | 108 / 162 / 216 / 324 / 432 | Adaptive background: the artwork's own green rebuilt as a radial gradient (`#9DFB6A` centre → `#48E61D` rim), so the models sit in the light they were drawn with. |
| `assets/images/branding/home_workout_icon.png` | 512 | Flutter splash plate: the same artwork, opaque, full-bleed, no white canvas. |
| `docs/release/artwork/launcher-mask-check.png` | 902×760 | Check sheet: adaptive layers under four masks plus the 66 dp keyline, legacy sizes at real scale, round variant, splash mock. |
| `docs/release/artwork/splash-preview.png` | 720×1280 | Splash mock-up at 360×640 dp @2×: plate 156 dp on `#E3FBDD`, title, tagline, accent bar. |

Nothing else carries the old citrus symbol: `res/mipmap-anydpi-v26/ic_launcher.xml`
and `ic_launcher_round.xml` both point at the `ic_launcher_background` /
`ic_launcher_foreground` pair above, and the unreferenced white wordmark
`splash_branding.png` (both `drawable-xxxhdpi` and `drawable-night-xxxhdpi`) was
removed.

## Splash

* Pre-Android 12: the native starting window is a flat
  `@color/launch_background_color` (`#E3FBDD`), no native logo — the Flutter
  splash paints the single brand mark, so there is no size jump between the
  system window and the app.
* Android 12+: `values-v31/styles.xml` and `values-night-v31/styles.xml` keep
  `windowSplashScreenBackground` = `#E3FBDD` and the transparent
  `@drawable/splash_transparent`, for the same reason.
* Flutter splash (`lib/features/splash/splash_screen.dart`): the 512 px plate at
  156 dp, rounded 32 dp, centred inside `SafeArea` on a pale tint of the
  artwork's own green (`#E3FBDD` = `#48E61D` mixed 85% towards white). Title
  `#15251A`, tagline `#3F5B45`, accent bar `#48E61D`, dark system bar icons.
  Timing (`AppConstants.splashDelay`), routing, loading and the recovery body
  are untouched.
* Both `values/colors.xml` and `values-night/colors.xml` use the same light
  green, because the brand splash is light in dark mode too — no dark flash
  before the first Flutter frame.
