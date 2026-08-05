---
name: mwm-symfony-app
description: Moon Whale Media house conventions translated to Symfony web apps. Use whenever creating or working on a Symfony project for Moon Whale Media — maps the established Laravel house patterns (branding, ads, consent, SEO, billing, security, testing) onto Symfony best practices.
---

# Moon Whale Media — Symfony App Conventions

No Moon Whale Media product ships on Symfony yet, so this skill maps the battle-tested Laravel house conventions (see the `mwm-laravel-app` skill — read it too when starting a Symfony project) onto idiomatic Symfony. Where Symfony has a native equivalent, use it; don't port Laravel idioms literally.

## Stack defaults

- **Symfony 7.x LTS + PHP 8.3**, structured as a standard Flex app.
- Frontend: match the house feel — **Vue 3 via Symfony UX / Vite** (`vite-bundle` — pentatrion/vite-bundle or symfony/ux-vue), Tailwind 3.x with the house theme tokens (`ink` `#0f172a`, per-brand `brand` ramp, `font-brand: Spantaran` for the tagline only). Fonts from bunny.net, never Google Fonts.
- ORM: Doctrine with migrations (`doctrine/doctrine-migrations-bundle`). Dev DB SQLite or MySQL per product.
- Auth: `security.yaml` form login + `symfony/security-bundle`; rate-limit login/register with `symfony/rate-limiter` (mirror the house throttles: register 6/min, login 10/min). API tokens for mobile apps: prefer an access-token authenticator (`security.access_token`) issuing opaque tokens stored hashed — the functional equivalent of Sanctum.
- Async: **Messenger** with the Doctrine transport (house rule "database queue driver") — but prefer scheduled console commands (`symfony/scheduler`) over async handlers, matching the Laravel habit.
- Console commands namespaced `<appslug>:<verb-noun>`.
- Testing: PHPUnit with `WebTestCase`/`KernelTestCase`; test env uses SQLite in-memory and sync transports.
- Dev host: Herd supports generic PHP apps — `https://<brand>.test` with docroot `public/`. Herd is never a production server.

## What carries over unchanged (brand + money rules)

These are Moon Whale Media rules, not framework rules — enforce them identically:

- **BrandLogo lockup with mandatory "by moon whale media, llc" tagline** (Spantaran, links to moonwhale.media, sibling anchor, superscript ™) — implement as a Twig include (`templates/components/brand_logo.html.twig`) or Vue component depending on the page.
- **Dark ink footer** (`bg-ink`), Support column with Contact / Privacy / Terms / vincentzwhaley.com / moonwhale.media, `© <year> <Brand>™ · by moon whale media, llc · Author: Vincent Z. Whaley`.
- **Ad rules:** server is the source of truth for ad eligibility (`adEligible = !user.isPro()`); Pro responses carry no client/slot IDs. One AdSense slot per page × placement. Leaderboards always get vertical breathing room top AND bottom via margin (or a full-bleed dark band placed outside the content max-width). Loader script injected only after consent.
- **Cookie consent:** banner only for ad-eligible visitors, per-brand localStorage key, decline-friendly, re-openable from a footer link, suppressed when Google CMP is active.
- **Billing ladder:** $4.99/mo, $49.99/yr, $149.99 lifetime. Stripe via `stripe/stripe-php` + webhook controller (Symfony has no Cashier; keep a `config/packages/billing.yaml`-style parameter set with `display_prices` as UI-only and `free_limits` as the gating source of truth).
- **Affiliates:** separate from AdSense, per-network enabled-iff-identifier-set, `rel="sponsored noopener noreferrer"`, Amazon Associates disclosure line, no untagged links ever.
- **SEO:** server-rendered meta + canonical + OG/Twitter + JSON-LD `Organization` (Moon Whale Media, LLC) — easy in Twig, no client-injection caveat. `/sitemap.xml` + `/robots.txt` routes with house priorities (legal 0.3). GA4 with Consent Mode v2 defaults denied before `gtag('js')`.
- **Security headers:** an event subscriber on `kernel.response` adding the same header set as the Laravel `SecurityHeaders` middleware (CSP with nonces — `nelmio/security-bundle` provides this — X-Frame-Options DENY, Referrer-Policy, Permissions-Policy, HSTS when secure).

## Symfony-specific mapping crib

| House pattern (Laravel) | Symfony equivalent |
|---|---|
| `config/<app>.php` + `env()` at leaf | `config/packages/<app>.yaml` parameters + `%env()%` processors, safe defaults |
| `HandleInertiaRequests::share()` | Twig globals via an extension, or a context builder service injected into controllers |
| `routes/console.php` schedule | `symfony/scheduler` `#[AsSchedule]` provider |
| Breeze auth scaffold | `make:auth`-style: `make:user`, `make:registration-form`, form login + verify email |
| Sanctum mobile tokens | access-token authenticator + token entity (hashed), `POST /api/v1/auth/login` |
| Pint | PHP-CS-Fixer with `@Symfony` ruleset |
| Ziggy | `fosjsrouting` only if needed; prefer passing URLs as props |

## Project layout in the monorepo

Same shape as every product: `<Product>/<slug>-web/` for the Symfony app, `build-tools/` for generators, `SESSION_HANDOFF.md` at repo root, media kit at repo root (gitignored). All other skills (mwm-brand, mwm-media-kit, mwm-launch-runbook, mwm-session-handoff) apply unchanged.
