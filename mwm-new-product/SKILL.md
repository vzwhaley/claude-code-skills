---
name: mwm-new-product
description: Bootstrap a brand-new Moon Whale Media product monorepo — directory layout, Laravel (or Symfony) web app, optional Android/iOS clients, SESSION_HANDOFF, launch checklist, build-tools, branding, .claude config. Use when the user says "new product", "new app", "start a new project", or wants to scaffold another Moon Whale Media property.
---

# Moon Whale Media — New Product Scaffolder

Bootstraps a product the way all eight existing ones are shaped. Ask the user only for: **product name**, **one-line concept**, **brand accent color**, **which clients** (web-only vs web+android+ios), and **web framework** (Laravel default; Symfony on request). Everything else has a house default.

## Monorepo layout (create at `~/Herd/MOON_WHALE_MEDIA/<Product>/`)

```
<Product>/
├── .claude/launch.json          # php artisan serve --port=<unique port — check other projects' launch.json to avoid collisions>
├── .gitignore                   # media kits, keystore.properties, *.sql dumps, out/
├── <slug>-web/                  # Laravel app (see mwm-laravel-app) or Symfony (see mwm-symfony-app)
├── <slug>-android/              # only if requested (see mwm-android-app)
├── <slug>-ios/                  # only if requested (see mwm-ios-app)
├── build-tools/                 # generators only — "NOT the build system"; README stating that charter
│   └── README.md
├── SESSION_HANDOFF.md           # house skeleton (see mwm-session-handoff)
├── LAUNCH_CHECKLIST.md          # house skeleton (see mwm-launch-runbook)
└── README.md
```

Naming: product `<Name>Flow`-style title; repo `vzwhaley/<kebab-slug>`; web dir `<kebab-slug>-web`; Android package + iOS bundle `com.moonwhale.<shortname>`; Herd site `https://<slug>.test`.

## Scaffold order

1. **Git + GitHub**: `git init` at product root, single repo for the whole monorepo, remote `git@github.com:vzwhaley/<slug>.git`, branch `main`. Push after every commit (standing rule).
2. **Web app** (`laravel new` via composer, then Breeze Inertia+Vue): apply the full mwm-laravel-app convention set — Tailwind house theme (`ink`, `brand` ramp, `font-brand`), BrandLogo + SiteFooter + ContactDrawer + ConsentBanner, SecurityHeaders middleware, AdSlot + `config/adsense.php`, `config/billing.php` with the $4.99/$49.99/$149.99 ladder and `free_limits`, SEO head + sitemap + robots, legal `/privacy` + `/terms` placeholders, `phpunit.xml` sqlite/:memory:/sync. Copy `Spantaran.ttf` into `public/fonts/` from any existing product.
3. **Herd**: `herd link <slug>` + `herd secure <slug>` from the web dir; unique `artisan serve` port in `.claude/launch.json` for the preview browser.
4. **Mobile clients** (if requested): scaffold per mwm-android-app / mwm-ios-app, wired to the web app's Sanctum API (`/api/v1/...`, `GET /api/config`, web-handoff endpoint).
5. **Docs**: SESSION_HANDOFF.md (§0 = "initial scaffold" session), LAUNCH_CHECKLIST.md skeleton, README with the one-line concept.
6. **Brand assets**: favicon.svg + favicons, OG image (1200×630 dark band + lockup **with tagline**), adaptive launcher icon — recipes in mwm-brand. Media kit and legal bundle come later via mwm-media-kit / mwm-launch-runbook.

## House rules to bake in from commit one

- The lockup always carries "by moon whale media, llc" (Spantaran). ™ on the product name.
- Ads: server-side ad-eligibility (`!isPro()`), one slot per page×placement, leaderboards with top+bottom margin, loader only after consent.
- Fonts from bunny.net. Dark ink footer. Support column links (Contact drawer, Privacy, Terms, vincentzwhaley.com, moonwhale.media).
- `SESSION_DRIVER=database`, `CACHE_STORE=database`, `QUEUE_CONNECTION=database`.
- Commit prefixes `Web:|Android:|iOS:|Apps:`; commit messages via `git commit -F <file>` on Windows.
- First commit message: `Scaffold <Product> monorepo (web/android/ios skeleton, house conventions)`.
