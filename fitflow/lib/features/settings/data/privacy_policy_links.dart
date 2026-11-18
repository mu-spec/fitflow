/// Single source of truth for the hosted documents the app links to.
///
/// Google Play requires a publicly reachable privacy-policy URL. The policy is
/// published at GitHub Pages under the `home-workout-privacy` project site; the
/// HTML source lives in `docs/privacy-policy.html` in this repository.
///
/// Change the constant here only — every Privacy Policy entry point in the app
/// (the Settings tile and the in-app summary screen) reads this value.
abstract final class PrivacyPolicyLinks {
  static const String privacyPolicyUrl =
      'https://mu-spec.github.io/home-workout-privacy/';
}
