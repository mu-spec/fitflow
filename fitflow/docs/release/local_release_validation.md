# Local release validation

Run these steps on the developer machine after the upload key exists. Do not run `flutter build appbundle` in Arena. This document does not build a binary.

## 1. Create the upload key outside Git

1. Create an upload keystore with Android Studio or `keytool`. Do not commit the `.jks` / `.keystore` file.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Fill `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
4. Confirm `git status` does not list `key.properties` or the keystore.

If `key.properties` is missing, `bundleRelease` and `assembleRelease` fail with an explicit message. They must not sign with the debug key.

## 2. Quality gate

From the Flutter project directory (`fitflow/`):

```text
flutter clean
flutter pub get
flutter analyze
flutter test --concurrency=1
```

`flutter analyze` should report 0 issues. Tests should pass with no omitted files.

## 3. Build the Play artifact

```text
flutter build appbundle --release
```

Publication format is an `.aab`, not an APK. The AAB is not directly installable. Install a Play-generated APK from an internal testing track instead of treating the AAB as an APK.

Locate:

```text
build\app\outputs\bundle\release\app-release.aab
```

## 4. Inspect the artifact

Confirm:

- package name `com.fitflow.fitflow` (register this exact id in Play Console before the first upload)
- versionName `1.0.0`
- versionCode `1`
- minSdk `24`
- targetSdk `36`
- compileSdk `36`
- label `FitFlow`
- signer is the upload certificate, not the Android debug certificate
- merged release permissions are only the intentional ones (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`) plus any plugin permission reviewed in `data_safety_audit.md`
- `android:allowBackup` is false and the backup rule resources are present
- native libraries pass the 16 KB checks in `android_binary_validation.md`

Useful local commands, adjusted to the installed SDK build-tools path:

```text
keytool -printcert -jarfile build\app\outputs\bundle\release\app-release.aab
```

If `keytool` cannot read the AAB signature directly, use Android Studio's App Bundle explorer or `jarsigner -verify -verbose -certs` on the bundle.

## 5. Smoke test on an internal track

After Play generates an installable build from the AAB:

- open Settings and the in-app Privacy Policy
- create and restore a manual backup
- enable a reminder and confirm it does not require an exact alarm
- start a workout and confirm voice coaching still speaks
- pause and resume the player
- confirm no account, ad, or sync screen appears

## 6. Still manual before production

- host the privacy policy and enter the public URL
- replace launcher icons and store artwork
- choose a distinctive Play title
- complete developer verification, package registration, IARC, target audience, Data Safety, and Health Apps declaration
- enroll in Play App Signing
