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
- package name `com.fitflow.fitflow` registered and accepted before the first upload
- payment profile only if the account features require it
- public developer contact finalized
- privacy-policy URL hosted and entered (see `PRIVACY_POLICY_PUBLISHING.md`)

`com.fitflow.fitflow` is the current applicationId candidate. It was not renamed. After the first upload, changing it means a different Play listing.

## Icon and artwork — Part 2 blocker

The launcher icons are still the default Flutter logo (blue Flutter mark on black). They are not a FitFlow icon and must be replaced before publication. Do not reuse another app's icon.

Assets that still require final replacement:

- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

There is no adaptive icon XML under `mipmap-anydpi-v26`. Part 2 must supply final launcher and store artwork. This part does not generate artwork.
