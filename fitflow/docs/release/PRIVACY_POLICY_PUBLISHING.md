# Publishing the Home Workout (FitFlow) privacy policy

Google Play requires a privacy-policy **URL** that is publicly reachable, not
geofenced, not behind a login, and served as a webpage. A screen inside the app does
not satisfy that requirement, and neither does a file inside this repository — the
page has to be hosted.

The page itself is finished: **`docs/privacy-policy.html`**. It is a single static
file with no JavaScript, no cookies, no external fonts, images or analytics, so it
looks and behaves the same on any host.

## The app links to it

`lib/features/settings/data/privacy_policy_links.dart` holds the single URL constant:

```dart
static const String privacyPolicyUrl =
    'https://mu-spec.github.io/fitflow/privacy-policy.html';
```

`PrivacyPolicyScreen` shows that address as selectable text and an
**“Open full policy in browser”** button (opened with `url_launcher` in the system
browser). If you host the page somewhere else, edit that one constant and rebuild —
nothing else references the URL.

## Three fields to fill in before you publish

`docs/privacy-policy.html` carries three uppercase tokens. They are deliberately
obvious so an unfinished page cannot pass quietly:

| Token | Replace with | Appears in |
| --- | --- | --- |
| `DEVELOPER_NAME` | your name or publishing entity | header block |
| `CONTACT_EMAIL` | a working privacy contact address | header block + “Contact us” (also inside the `mailto:` links) |
| `PUBLIC_URL` | the address the page is served from | header block + “This page” row |

Also confirm `Effective date` and `Last updated` (currently 16 November 2026). Delete
the amber “Before publishing” box at the top of the page once the tokens are gone —
it is already hidden when the page is printed.

## Hosting on GitHub Pages (free, static, no build step)

1. Replace the three tokens in `docs/privacy-policy.html` and delete the amber box.
2. Commit and push to `main`.
3. Repository → **Settings → Pages → Build and deployment**:
   - Source: **Deploy from a branch**
   - Branch: **`main`**, folder: **`/docs`** → **Save**
4. Wait for the deployment banner, then open
   **`https://mu-spec.github.io/fitflow/privacy-policy.html`** — this is exactly the
   URL compiled into the app, so no code change is needed if you use this host.
5. Verify in a private window and, if possible, from a different network: the page
   must load with no login and no cookie banner.

Any static host works instead (Cloudflare Pages, Netlify, Firebase Hosting, your own
domain). Point `privacyPolicyUrl` at it and rebuild.

## Play Console

- Paste the hosted URL into **App content → Privacy policy**.
- Keep the page consistent with the **Data safety** answers in
  `docs/release/play_data_safety.md` and the health declaration in
  `docs/release/play_health_declaration.md`.
- Keep the in-app screen (`PrivacyPolicyScreen`) as the offline summary: it is
  accurate and contains no placeholder tokens, but it is not the Play-required URL.
- If the contact address or entity name changes, update the hosted page **before**
  submitting the next release. A dead or mismatched policy URL is a common cause of
  review rejection.
