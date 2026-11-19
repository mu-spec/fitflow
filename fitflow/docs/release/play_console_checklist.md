# Play Console declaration checklist

Arena cannot complete account-level Play Console actions. Nothing in this list is marked done.

## Ads

V1 contains no ads and no ad SDK. Declare that the app does not contain ads.

## App access

No login or account is required. The core app is accessible without review credentials. Do not provide a fake test login.

## Account deletion

Not applicable. FitFlow has no account creation. Do not add an account-deletion URL.

## Health Apps

Declare **Health and fitness → Activity and Fitness**. See `play_health_declaration.md`. Do not select "no health features."

## Data Safety

Use `play_data_safety.md` and `data_safety_audit.md`. Do not submit assumed answers. Candidate: FitFlow does not collect or share user data with its own server or an ads/analytics SDK, with the TTS and user-export caveats documented there.

## Content rating

Complete the IARC questionnaire in Play Console from the real app behavior. Do not hardcode an age rating in the Android manifest or Dart code.

## Target audience

The developer must choose the target age groups in Play Console. Do not mark the app as designed for children unless that is an explicit product decision. This repository does not make that choice.

## Category

Candidate store category: **Health and Fitness**. Confirm in Play Console. This is not a medical-device category.

## Store listing

- In-app brand: FitFlow
- Tagline already used in the product: Workouts that adapt to you.
- The Play store title must be finalized in Part 2.
- Several fitness apps already use FitFlow branding. The final store title should be more distinctive than the bare name FitFlow.
- This document does not make a trademark conclusion.

## App access, signing, and package

- First publication artifact is an Android App Bundle (`.aab`), not an APK.
- Use Google Play App Signing for the production app.
- The developer creates and protects a separate upload key. That key never goes into Git.
- Play manages the distribution signing key.
- If the upload key is lost or exposed, use Play's upload-key reset / key-management workflow. Do not generate a replacement key in this repository.

## Developer verification and package registration

Manual checks the developer must complete in Play Console. Not done here:

- developer identity verified
- contact details current
- package name `com.muspec.fitflow` registered and accepted before the first upload
- payment profile only if the account features require it
- public developer contact finalized
- privacy-policy URL hosted and entered (see `PRIVACY_POLICY_PUBLISHING.md`)

`com.muspec.fitflow` is the current applicationId candidate. It was not renamed. After the first upload, changing it means a different Play listing.

## Icon and artwork

Resolved. The default Flutter logo is gone; the launcher icons and the store
listing icon are the approved artwork (two fitness models on a light green
field), and nothing here is a placeholder any more.

| Item | Where | State |
| --- | --- | --- |
| Legacy launcher icons, API 25 and below | `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (48/72/96/144/192 px) | Approved artwork, full-bleed, no white corners |
| Round launcher icons (`android:roundIcon`) | same folders, `ic_launcher_round.png` | Approved artwork in a circular mask |
| Adaptive icon, Android 8+ | `mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` | Present. Foreground = the two models at 62/108 dp, background = the artwork's own radial green field (`#9DFB6A` → `#48E61D`) |
| Play Store listing icon | `docs/release/artwork/play_store_icon.png` | The approved 512×512 PNG, byte-identical to the delivered upload; upload this file as the store icon |
| Splash | `assets/images/branding/home_workout_icon.png` + `values/colors.xml` `launch_background_color` `#E3FBDD` | Approved artwork on the pale brand green |

Regenerate every launcher asset with `python3 tools/media/build_launcher_icons.py`
and the visual check sheet with `python3 tools/media/make_mask_check.py`. Details
and measurements: `docs/release/artwork/icon-generation.md`.

Remaining store-listing work is Play Console only: phone/tablet screenshots,
feature graphic and the short/full description. This repository does not generate
them.
