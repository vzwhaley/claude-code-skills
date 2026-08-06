---
name: mwm-ui-copy
description: Moon Whale Media UI copy conventions — Title Case for every title, button, badge, tab, label and other short "text notifier", plus the ™ / brand-name rule. Use whenever writing or editing user-facing UI text on any platform (web, Android, iOS): page titles, headings, buttons/CTAs, badges/pills/chips, tab labels, field labels, table headers, empty-state titles, menu items, nav/footer links. Also apply during any "full pass" / copy-polish / capitalization review.
---

# Moon Whale Media — UI Copy Conventions

House rules for how short user-facing strings are capitalized and branded. These
apply to **every** Moon Whale Media product on **every** platform — web (Vue/Blade),
Android (Compose), iOS (SwiftUI), and any generated artifact (emails, media kits,
store listings). When in doubt, match these; the user cares about them and has
asked for them repeatedly.

## 1. Title Case — the default for all short UI labels

Every **title, button, badge, tab, label, and other "text notifier"** is written in
standard **Title Case**. This is the single most-requested copy rule.

**Applies to** (short display strings — usually ≤ ~8 words):
- Page / screen titles and `<Head>` / document titles
- Headings and section headers (h1–h4), card titles, eyebrows/kickers
- Buttons, CTAs, links styled as actions
- Badges, pills, chips, tags, status labels, plan names
- Tab labels, menu items, nav links, footer links
- Form field labels, table/column headers
- Empty-state titles, modal titles, toast titles

**Does NOT apply to** (leave in natural sentence case):
- Body paragraphs, descriptions, helper/subtext, tooltips that are full sentences
- Legal clause text, disclaimers
- Dynamic data rendered from variables (names, signs, dates, API content)
- `aria-label`, `alt`, `placeholder`, and other accessibility/attribute strings
- Full conversational questions used as marketing headers *may* stay sentence case
  if they read as a spoken sentence — but a short noun-phrase header is Title Case.

### The Title Case algorithm (follow exactly)

1. **Capitalize the first and last word, always** — regardless of what they are.
2. **Capitalize all major words**: nouns, pronouns, verbs (incl. *Is, Are, Be, Was*),
   adjectives, adverbs. Note **Is / Are / It / Your / My / This / That** are
   capitalized — they trip people up.
3. **Lowercase these minor words when they fall in the middle** of the phrase:
   `a an the` · `and but or nor for yet so` · `as at by for in of off on per to up via with vs`.
4. **Override rule 3** and capitalize a minor word when it is the **first or last
   word**, or comes **immediately after a colon `:` or a dash `— – -`**.
5. **Leave untouched**: `™` and other symbols, emoji, arrows (`→ ✦ ★ ⬇`), ALL-CAPS
   acronyms/abbreviations (PDF, NE, SW, BaZi), and proper names (zodiac signs,
   planets, tarot cards, place names).
6. Contractions keep normal caps: **It's, Let's, You're, That's**.

### Examples (from AstrologerFlow)

| Sentence case ✗ | Title Case ✓ |
|---|---|
| Get started - it's free | Get Started — It's Free |
| already a member? log in | Already a Member? Log In |
| create a free account | Create a Free Account |
| reading for | Reading For |
| lucky colors & numbers | Lucky Colors & Numbers |
| your birth data is private — never sold | Your Birth Data Is Private — Never Sold |
| NE - success & wealth | NE — Success & Wealth |
| sagittarius & capricorn - a radiant match | Sagittarius & Capricorn — A Radiant Match |
| best & worst days forecast | Best & Worst Days Forecast |
| how it works | How It Works |

Edge notes: phrasal-verb particles (*Back Up, Log In, Sign Up*) read best capitalized;
`&` is left as-is (it's a symbol, not the word "and", so words on both sides are
capitalized normally).

## 2. Brand name gets ™ on every user-facing reference

Every visible occurrence of a product name that carries a trademark (e.g.
**AstrologerFlow™**, **NewsroomFlow™**) must include the `™`. This covers page
titles, `og:title` / `twitter:title`, headings, body mentions, share text, email
subjects/bodies, badges, and generated images.

**Do NOT add ™ to** (these are infrastructure / non-display and ™ breaks them):
- Internal identifiers: directory names, config keys, env vars, route names,
  artisan/CLI command names, class names, domains/hostnames.
- HTTP `User-Agent` headers and other protocol strings.
- File/download names (e.g. a generated `Product-Report.pdf`).
- AI system prompts / internal instructions.

Note: in a JSON-LD `<script>` block ™ is JSON-escaped to `™` — that's correct;
tests asserting on brand text there should match a ™-free substring.

See the **`mwm-brand`** skill for the full logo lockup + mandatory
"by moon whale media, llc" tagline rules — this skill governs the *text*, that one
governs the *mark*.

## 3. How to run a "full-pass" capitalization review

When asked to sweep an existing app:
- Target the display strings listed in §1; skip body/prose/dynamic/attribute text.
- On a large web app, parallelize with subagents by page group, each working from
  the §1 algorithm, then review the combined diff for over-capitalized minor words
  (a stray mid-title *The / Of / A / With*) before building.
- Fix shared components once (they recur on many pages), and don't forget per-page
  prop overrides passed into shared components (e.g. a `title="..."` on a sign-in
  gate card).
- Rebuild and run the test suite. Inertia/JSON prop tests rarely break on text, but
  any test asserting a rendered heading or a jsonLd string can — update those.
