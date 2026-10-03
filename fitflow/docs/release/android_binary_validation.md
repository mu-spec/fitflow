# Android binary validation

No APK or AAB was built in this milestone. Nothing below is a claim that a release artifact already passes.

## 16 KB page-size readiness

Google Play requires modern 64-bit compatibility, including devices that use 16 KB memory pages.

Source audit of this repository:

- FitFlow's own Android code has no `jniLibs` directory and no project-bundled `.so` files.
- Direct plugins (`shared_preferences`, `flutter_local_notifications`, `flutter_timezone`, `flutter_tts`, `file_picker`) are platform channel plugins. Their locked Android implementations contain no `.so` files and no Android `CMakeLists.txt`. Desktop example CMake files are not packaged into the Android app.
- The Flutter engine still packages `libflutter.so` (and related engine libraries) into a real release build. That library is produced by the Flutter SDK and NDK, not by this repository.
- `compileSdk` and `targetSdk` are 36. `ndkVersion` remains the Flutter SDK default so the build uses the NDK Flutter expects. Do not guess a different NDK here.

This does **not** prove 16 KB alignment. Alignment can only be checked on a built release artifact.

## Part 2 checks — run locally, after the user creates an upload key

Do not run these in an environment that has no upload key. A missing `android/key.properties` must fail the release task instead of signing with the debug key.

```text
cd fitflow
flutter build appbundle --release
```

Expected output:

```text
build/app/outputs/bundle/release/app-release.aab
```

Then, on a machine with Android SDK build-tools and, if needed, bundletool:

```text
# Confirm the AAB exists and is not a debug-signed APK publication artifact.
dir build\app\outputs\bundle\release\app-release.aab

# Package and SDK values from the merged release manifest.
# Android Studio: Build > Analyze APK/AAB, or:
# aapt dump badging after converting the bundle to APKs.

# 16 KB alignment of extracted native libraries.
# Official check used for APKs generated from the bundle:
zipalign -c -P 16 -v 4 path\to\extracted.apk

# ELF alignment of engine libraries (expect 2**14):
llvm-objdump -p path\to\lib\arm64-v8a\libflutter.so | findstr LOAD
```

Also generate a universal or arm64 APK set from the AAB only as a verification artifact. Do not upload an APK as the Play publication file.

Reject the artifact if:

- `libflutter.so` or any plugin `.so` has a LOAD alignment below 16 KB
- the merged manifest re-enables `android:allowBackup="true"`
- the merged manifest adds a permission that this audit did not accept
- the signer is the debug certificate

## Play App Signing

- Enroll the app in Google Play App Signing.
- The upload key signs the AAB the developer uploads.
- Play re-signs the distribution artifact with the app signing key.
- The upload keystore, `key.properties`, and passwords stay off Git.
- Losing or exposing the upload key is handled in Play Console key management, not by committing a new secret.
