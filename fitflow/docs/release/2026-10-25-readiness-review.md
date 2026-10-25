# Home Workout — release review, 25 October 2026

This is a local source/artifact review, not Play approval or a complete policy certification. No APK/AAB was built, no Gradle command was run, and no Play Console submission was made. Protected Gradle/signing files were not changed.

## APK actually examined

- `build/app/outputs/flutter-apk/app-release.apk`: 31,361,616 bytes, modified 25 October 2026 at 13:28 local time.
- SHA-256: `094753960B4BF699ACAA8571817C048D53569725B102C61178D603D211806349`.
- Package `com.fitflow.fitflow`, version 1.0.0 (1), label Home Workout, minimum API 24, target/compile API 36.
- `apksigner verify --verbose --print-certs`: valid APK Signature Scheme v2, one RSA-2048 signer with a custom certificate, not the standard Android debug certificate. v1/v3/v4 absent; v2 verification succeeds for this minimum API. This does not prove Play App Signing enrollment or an upload-key match for an existing listing.
- Public certificate SHA-256: `37fa4ab49cff09ec4f9297c8c771f9c548edb7404457a7c8da4236458a066662`.
- This pre-existing APK does not contain this milestone's changes. The installed phone APK cannot be identified from the repository alone.

## Technical findings

| Check | Result |
| --- | --- |
| Target API | API 36 meets the published new-app/update requirement checked on this date. |
| 16 KB ZIP alignment | `zipalign -c -P 16 4 …/app-release.apk`: exit 0. |
| Native ELF LOAD alignment | All five packaged libraries have LOAD alignment >=16,384: arm64 libapp/libflutter 65,536; datastore counter on arm64/armeabi-v7a/x86_64 16,384. |
| 16 KB runtime / final bundle | Not tested. Alignment is necessary, not proof of runtime compatibility. Check the final AAB/Play-generated APKs and run on a 16 KB device/emulator. |
| ABI packaging | Review required: only arm64 has libflutter.so and libapp.so. The other two advertised ABIs contain only the datastore plugin. Do not assume this APK supports 32-bit ARM or x86_64. The final bundle must contain complete Flutter libraries for every distributed ABI. |
| Manifest | allowBackup=false, extractNativeLibs=false, debuggable not enabled. Permissions: notifications, reboot recovery, vibration and package-scoped receiver permission. No Internet, ads ID, camera, microphone, location, broad-storage or exact-alarm permission. |
| Data/SDKs | Existing dependency manifest and focused source search show no app ads/analytics/network client. Device-selected TTS may use an online engine; user-selected backup destinations may be cloud-backed. No dependencies added. |

References: [target API](https://support.google.com/googleplay/android-developer/answer/11926878), [16 KB checks/runtime testing](https://developer.android.com/guide/practices/page-sizes).

## Artwork

- `docs/release/artwork/play_store_icon.png`: 512×512, 32-bit RGBA PNG, sRGB chunk present, 235,316 bytes; opaque full square without an outer rounded mask, external shadow, rankings, prices, badges or lettering.
- Same generated house/dumbbell artwork for Flutter splash, five legacy launcher densities, adaptive launcher foreground and Android splash. Android applies the launcher mask; foreground padding protects the symbol.
- App asset: `assets/images/branding/home_workout_icon.png`. Native launch text reuses Home Workout / Workouts that adapt to you.
- Built-in imagegen followed by mechanical PNG sizing using System.Drawing. Prompt in `artwork/icon-generation.md`.
- Native XML was validated, but launcher masking/native splash still need device review after the user's build. No claim of trademark clearance or Play approval.

[Official Play icon specification](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).

## Publication items still open

1. **Public privacy policy:** `docs/privacy-policy.html` is an unpublished template. Its brand now matches Home Workout, but developer/legal entity, contact email, effective date and public URL remain placeholders. Complete and host it, then enter the URL in Play Console. The in-app policy cannot replace the required public URL.
2. **Health declaration:** complete Health and fitness → Activity and Fitness. Review the store description's non-medical disclaimer and reminder to consult a healthcare professional for medical advice. The in-app policy states general fitness/non-medical use; this review does not certify health claims.
3. **Data Safety:** review the existing worksheet against the live form, including TTS and user-exported backup caveats. No forms/account settings were submitted or verified.
4. **Distribution:** signed AAB, Play App Signing/upload-key match, complete ABI packaging, 16 KB runtime test and Play pre-launch report remain unverified. Increment version code for later uploads as applicable.
5. **Account/listing:** developer verification/contact, content rating, target audience, ads/app-access answers, feature graphic, screenshots and listing claims remain Console checks. The app has no account creation or login requirement.
6. **Testing access:** for personal developer accounts created after 13 November 2023, check the closed-test requirement (12 continuously opted-in testers for 14 days) and production-access application.

Sources: [health/privacy policy](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en), [Health declaration](https://support.google.com/googleplay/android-developer/answer/14738291), [personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465).

## Validation

- Focused onboarding/assessment/preparation/startup run: 63 tests passed, including all eight steps and ten movement choices, viewport-sized backdrop assertions, both themes, 1×/2× text and short layouts.
- After adding splash scroll/branding coverage: 34 focused preparation/splash/routing/recovery tests passed.
- Preparation tests verify monotonic progress, no 100%/Home before six seconds, persisted levels and completion before navigation. Splash/preparation layout sizes include 360×640, 360×800 and 412×915.
- Scoped Dart analysis: no issues. No full suite, screenshots, media revalidation or app build.
