# Publishing the FitFlow privacy policy

The in-app Privacy Policy screen is not enough for Google Play.

Play requires a privacy-policy URL that is:

- publicly accessible
- active
- not geofenced or login-walled
- a webpage, not only a file inside this repository

`docs/privacy-policy.html` is a static template with no JavaScript, cookies, or external trackers. It can be hosted on GitHub Pages or another static host **after** the TODOs are replaced.

## Not published yet

This repository does not claim that a public policy URL exists. The following facts are unknown to the repository and must be supplied by the developer before Part 2 publication:

- developer / legal entity name
- privacy contact email
- public privacy-policy URL
- effective date

Do not ship placeholder tokens in the Play Console form or in the in-app screen. The in-app screen already avoids those tokens and points users to the developer contact associated with the published app.

## Before the first production release

1. Replace every `TODO` in `docs/privacy-policy.html`.
2. Host the finished HTML at a stable public HTTPS URL.
3. Open that URL in a private browser window, including from a network outside the developer's usual region, and confirm it loads without a login.
4. Enter that URL in Play Console and keep it matching the in-app explanation.
5. If the contact email or entity name changes, update the hosted page before submitting the release.
