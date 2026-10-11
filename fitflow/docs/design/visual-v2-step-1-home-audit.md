# Visual V2 / Step 1 — Home audit before implementation

Baseline: published `85a298530ebc260142d8f5a8925d6e23db43ac2a`, verified against GitHub main and the entire clean source tree. This is a new visual direction, not a functionality pass.

## Findings

- **Hierarchy / anchor:** Home's page title, white workout card and plain supporting text have similar visual weight. The generated workout has no distinctive visual identity. Its title, target, explanation and administrative-looking mode row form a long text stack.
- **Layering:** the existing off-white page, white bordered hero and uncontained supporting sections provide little distinction between the recommendation, real setup and movement focus. The single card does not feel like tangible workout content.
- **Personalization:** all actual setup values are hidden behind a generic disclosure. There is little visible evidence of personalization until it is opened.
- **Focus:** the ordered movement data is rendered as a dot-separated sentence rather than a deliberate set of training tags.
- **Rhythm / action:** the CTA is accessible and functional, but visually competes with the mode/settings row and similarly styled text. The section counts read like a footer rather than workout composition.
- **Brand:** the existing teal palette is sound; a deep emerald emphasis and mint contrast can be derived from its semantic roles without changing other features.

## Foundation and constraints inspected

Existing FitFlow semantic palette/theme extension, role-based typography (40px display / 28px page / 22px section / 16px card), spacing scale, 20px card and 12px control radii, 120/200/320ms motion tokens, capped layouts, native bar/rail and its persistent four branches. Existing Home/dashboard/mode tests, Part 2 responsiveness/native CTA tests, and bounded Part 6 route matrix remain the behavioral contract. Loading/error/missing-profile/no-plan handling already provides honest recovery; these are not functional defects to reinvent.

## Planned visual direction

An emerald workout hero with one restrained gradient, a static original flowing-track motif, large truthful duration and compact metadata, a mint Preview CTA, integrated mode strip and labelled real section composition. A quieter tinted page and differentiated supporting surface will establish depth. Expose goal/environment as compact real setup facts, with the remaining existing values retained in the Built for you disclosure. Convert current ordered focus labels to noninteractive tags. Preserve native navigation styling unless captures establish a need; no floating navigation.

V2 roles will be an **opt-in adapter over the existing semantic palette**, not a competing/global theme. Reusable hero/support/metadata treatments only as needed by Home. No fonts, palette, routing, state, generation, eligibility, persistence or other feature redesign. No fake metrics, exercise media, external images or looping animation.

## Verification plan

Home Light/Dark at all eight requested sizes and 1×/2× text; explicit mode/CTA/disclosure/semantics/contrast/reduced-motion checks. Actual production Home captures with TEST fixtures, outside the repository. Analyze, focused Home/design/accessibility tests, full serial tests using bounded per-width entry points, and diff check. Physical Android/Oppo appearance, font rasterization, TalkBack, insets/keyboard and smoothness remain pending.
