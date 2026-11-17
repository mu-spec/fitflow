/// Single source of truth for the hosted documents the app links to.
///
/// Google Play requires a publicly reachable privacy-policy URL. The HTML that
/// must be served at [privacyPolicyUrl] lives in `docs/privacy-policy.html`.
/// If the page is hosted somewhere else, change the constant here only — the
/// Privacy Policy screen reads it, so nothing else needs updating.
///
/// Default: GitHub Pages served from the repository `docs/` folder, which makes
/// `docs/privacy-policy.html` available at the URL below.
abstract final class PrivacyPolicyLinks {
  static const String privacyPolicyUrl =
      'https://mu-spec.github.io/fitflow/privacy-policy.html';
}
