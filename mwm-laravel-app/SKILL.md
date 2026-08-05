---
name: mwm-laravel-app
description: Moon Whale Media house conventions for Laravel web apps (Laravel 13, Inertia + Vue 3, Tailwind, Breeze). Use whenever creating a new Laravel app or working on any *-web project — covers stack, BrandLogo/footer, AdSlot + consent, SEO, billing, security headers, config/env conventions, and testing.
---

# Moon Whale Media — Laravel Web App Conventions

Proven conventions shared by the eight Moon Whale Media Laravel apps. Follow them for every new Laravel project unless the user says otherwise.

## Stack defaults

- **Laravel 13 + PHP 8.3, Inertia 2 + Vue 3, Tailwind 3.x, Vite, Ziggy, Pint.** No Blade UI (Blade only for the `app.blade.php` root shell), no Livewire. Fonts from `https://fonts.bunny.net` — never Google Fonts.
- **Auth: Laravel Breeze** (Inertia+Vue), with house throttles added: `throttle:6,1` on register/password, `throttle:10,1` on login. Socialite (Google/Apple/Discord) optional, gated on `filled(config('services.<x>.client_id'))` and surfaced via a `socialProviders` Inertia prop.
- **DB:** MySQL or SQLite per product; always `SESSION_DRIVER=database`, `CACHE_STORE=database`, `QUEUE_CONNECTION=database`.
- **Testing:** PHPUnit (house default), `phpunit.xml` env: `DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`, `QUEUE_CONNECTION=sync`.
- **Scheduling:** artisan commands namespaced `<appslug>:<verb-noun>`, scheduled in `routes/console.php` (never a Kernel), with `->withoutOverlapping()` on recurring work and `->runInBackground()` on heavy jobs. Prefer scheduled commands over queued jobs unless truly async.
- Dev host is **Herd**: `APP_URL=https://<brand>.test`. Herd is never a production server.

## Tailwind theme (every app)

```js
fontFamily: {
  sans:  ['Figtree', ...defaultTheme.fontFamily.sans],
  display: [per-brand],
  brand: ['Spantaran', 'Figtree', ...],   // ONLY for "by moon whale media, llc"
},
colors: {
  ink:   { DEFAULT: '#0f172a', soft: '#1e293b' },   // shared dark ink
  brand: { 50…900 },                                // per-app accent ramp
},
plugins: [forms]
```

## Shared components (copy from CoderStudyFlow / NewsroomFlow as reference)

### BrandLogo.vue
Props: `variant: 'light'|'dark'`, `iconClass` (default `h-12 w-auto`), `tagline: Boolean` (default `true` — keep it true everywhere), `href`. Structure: `flex items-center gap-3` → icon Link → wordmark (`font-display text-2xl font-bold tracking-tight`, brand-colored suffix word, superscript `™`) → tagline `by <a href="https://moonwhale.media" class="font-brand">moon whale media, llc</a>`. **Invariant: the credit `<a>` is a sibling, never nested inside the home `<Link>`.**

### Dark ink SiteFooter.vue
`<footer class="bg-ink text-white">`, `max-w-7xl px-4 py-14` grid `lg:grid-cols-[1fr_2.4fr]`: `<BrandLogo variant="dark" />` + blurb, then 4 link columns (Product · Resources · Account · Support). Support always contains Contact, Privacy Policy, Terms of Service, `https://vincentzwhaley.com`, `https://moonwhale.media`. Bottom bar: `© {{ year }} <Brand>™ · by moon whale media, llc. All rights reserved. · Author: Vincent Z. Whaley`. Contact is a **drawer** (`ContactDrawer.vue`, `useForm` with a `company` honeypot posting `route('contact.store')`) — the support email never appears as a plain string in markup.

### Layout order
`SiteLayout.vue` ends with `<SiteFooter /> → <ContactDrawer /> → <ConsentBanner />`, and starts with a "Skip to main content" link + `<main id="main-content" tabindex="-1" class="flex-1 focus:outline-none">`.

## Ads (AdSlot) — the money rules

- **Server is the source of truth.** In `HandleInertiaRequests::share()`:
  ```php
  $adEligible = ! ($user && $user->isPro());
  'adsense' => [
    'shows_ads' => $adEligible,
    'client'    => $adEligible ? config('adsense.client') : null,
    'slots'     => $adEligible ? config('adsense.slots')  : [],
    'use_google_cmp' => (bool) config('adsense.use_google_cmp'),
  ],
  ```
  Pro users receive no client/slot IDs, so ads are structurally unrenderable.
- `config/adsense.php`: `client` (env `ADSENSE_CLIENT`), `use_google_cmp`, `slots => ['home_top' => env('ADSENSE_SLOT_HOME_TOP'), …]` — **one slot per page × placement** for separate reporting. Blank client ⇒ dashed dev placeholder ("Your Ad Here", `Sample placement · Leaderboard · 728 × 90`).
- AdSlot component: `role="complementary" aria-label="Advertisement"`, an "Advertisement" micro-label above, an upsell line ("Remove Ads — Upgrade To Pro" → `/pricing`) below, mode state machine `'hidden'|'live'|'placeholder'`, and `ensureScript(client)` that lazily appends the adsbygoogle loader with a per-app marker attribute — **only after consent**.
- **Spacing (global user rule):** banner/leaderboard slots always get vertical breathing room top AND bottom, via **margin not padding** (fixed-height border-box swallows padding). Two house dialects:
  - **Full-bleed dark band** (current preference for page-level bands): placed OUTSIDE the page max-width wrapper — `<div class="w-full border-y border-white/10 bg-slate-800 py-8">` with an inner `mx-auto max-w-3xl` wrapper (`min-h-[90px]` leaderboard / `max-w-[336px] min-h-[250px]` rectangle). Padding is fine here because the band itself isn't fixed-height.
  - **Component-owned margin** for in-content slots: wrapper `my-6`/`my-8` baked into AdSlot itself, never removable per-page.

## Cookie consent

- `ConsentBanner.vue`/`CookieConsent.vue` + a module-singleton composable (`useConsent`) with a per-brand localStorage key (e.g. `csf_ad_consent`). The **AdSense loader is injected only after Accept** — never emitted in `app.blade.php`.
- Show only to ad-eligible visitors; suppress entirely when `use_google_cmp` is true (no double banner). Re-openable from a footer "Cookie Preferences" link via a custom window event (`<prefix>:open-cookie-settings`).
- If consent affects Google: `window.adsbygoogle.requestNonPersonalizedAds = granted ? 0 : 1` + Consent Mode v2 `gtag('consent','update',…)`.
- Style: dark ink bottom bar (`fixed inset-x-0 bottom-0 z-[60] bg-ink text-white`) or floating white card; buttons Decline/Accept (choose decline-friendly defaults).

## SEO / analytics

- Server-rendered meta in `app.blade.php` from an Inertia `meta` prop: title, description, canonical, full OG + Twitter `summary_large_image` (1200×630), `theme-color #0f172a`, JSON-LD `@graph` with an `Organization` node for Moon Whale Media, LLC (`https://moonwhale.media`) + `WebSite` node. Optionally a client `SeoHead.vue` — but keep a server-side mirror (`config/seo.php`) because JS-less crawlers never see Inertia-injected tags.
- Title callback in `app.js`: `title => \`${title} - ${appName}\`` — components pass the bare title.
- `/sitemap.xml` route (priority: home 1.0, hubs 0.9, content 0.7–0.8, legal 0.3 yearly) + dynamic `/robots.txt` pointing `Sitemap:` at `route('sitemap')`.
- GA4 only, gated `@if (config('analytics.ga_id'))`, with **Consent Mode v2 defaults (all denied) declared BEFORE `gtag('js')`** and `send_page_view: false` (SPA navigations emit their own via a `useAnalytics` composable that no-ops when gtag is absent). Event vocabulary: `sign_up`, `paywall_view`, `begin_checkout`, `trial_start`, `purchase`.

## Security headers

`app/Http/Middleware/SecurityHeaders.php`: `Vite::useCspNonce()`, `script-src 'self' 'nonce-…'` (+ Google ad domains only when a client is configured), `style-src 'unsafe-inline'` + `fonts.bunny.net`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()`, COOP, HSTS when secure.

## Billing & monetization

- **Stripe + Cashier.** `config/billing.php`: `prices` (env `STRIPE_PRICE_PRO_{MONTHLY,ANNUAL,LIFETIME}`), `display_prices` (UI only — Stripe is truth), `free_limits` (the single source of truth for feature gating), `checkout_enabled` pre-launch flag. **House price ladder: $4.99/mo, $49.99/yr, $149.99 lifetime** — identical family-wide on purpose.
- Cashier webhook route named `cashier.webhook`. RevenueCat webhook (mobile IAP → web entitlement) only when the product has mobile IAP: header-authenticated `POST /api/revenuecat/webhook`, app sets RevenueCat `appUserID` to the local user id.
- **Affiliates are a separate layer from AdSense:** `config/affiliate(s).php` with per-network `enabled` flags that are true iff the tracking identifier env is set — never ship an untracked/untagged link; dashed placeholder until the tag exists. Links `rel="sponsored noopener noreferrer"`, with the mandatory disclosure line "As an Amazon Associate, <Brand> earns from qualifying purchases." Affiliate panels use the full-bleed dark band style.

## Mobile API (when the product has apps)

Sanctum personal access tokens: `POST /auth/login` (`throttle:10,1`) → `$user->createToken($device_name)->plainTextToken`; register `throttle:6,1`. Cross-cutting endpoints: `GET /api/config` (ad config — Free gets AdMob unit IDs, Pro gets `ads.show=false`), `POST /api/auth/web-handoff` (single-use 5-minute token so "Upgrade to Pro" lands on the site logged in). Path convention for new apps: `/api/v1/...`.

## Config / env style

- One eponymous domain config per app (`config/<appslug>.php`) plus the recurring set: `adsense.php`, `admob.php`, `billing.php`, `affiliate(s).php`, `analytics.php`, `features.php`.
- Style: heavy header comment blocks explaining *why*, `env()` only at the leaf, safe defaults so the app boots with zero keys, and an explicit stub/demo mode for local dev.
- Legal routes `/privacy` + `/terms` (LegalController or Inertia closures), footer-linked, in sitemap at 0.3.
