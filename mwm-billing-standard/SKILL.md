---
name: mwm-billing-standard
description: The Moon Whale Media billing and distribution standard - Pro sold only on the product website via Stripe, server is the single source of Pro, phone apps always free with no purchase UI (server store-billing switch, default off), desktop/extension apps link to the website. Use whenever touching billing, Pro gating, upgrade buttons, pricing, app-store submission, in-app purchase questions, or desktop/app distribution in ANY Moon Whale Media product.
---

# Moon Whale Media — Billing & Distribution Standard

**Version 1 · adopted 2026-09-27 · applies to every Moon Whale Media product**
(AstrologerFlow, CoderStudyFlow, FileManagerFlow, IdentiFlow, MyEmergencyScreen,
NewsroomFlow, SocialStashFlow, TabFlow, The Cardback Cantina, and every new one).

One sentence: **one Pro account, bought once on the product's website, that
works everywhere — and every app is a free download.**

This is a product/engineering standard, not legal advice. Store rules change;
confirm the store-review notes below at each submission.

---

## 1. The five rules

1. **The website is the only place Pro is sold.** Stripe (Laravel Cashier) on
   `<product>.app/pricing`. No in-app purchase anywhere: no StoreKit, no
   Google Play Billing, no RevenueCat.
2. **The server is the single source of truth for Pro.** Every client (web,
   Android, iOS, desktop, browser extension) asks the product's own API whether
   the signed-in user is Pro. A purchase on the website unlocks Pro on every
   device at the next sign-in or refresh.
3. **Phone apps are always free downloads** on Google Play and the App Store,
   and never sell anything: no prices, no "Upgrade", no "Go Pro", no links to
   pricing or checkout — unless the product's server switch for that store is
   turned on (section 4). Locked features say so in neutral words ("Pro
   feature") without telling the user where to buy it.
4. **Desktop apps and browser extensions are distributed from the website /
   extension store** and MAY link to the website to upgrade (no store sits in
   between, so nobody takes a cut).
5. **Pro is promoted outside the phone apps**: the website, emails (free
   allowance used up, trial ending, feature news), desktop apps, social media.
   Store rules do not govern those.

## 2. Plans (identical in every product)

| Plan | Price | Stripe env |
|---|---|---|
| Free | $0 | — |
| Monthly Pro | $4.99 / month | `STRIPE_PRICE_PRO_MONTHLY` |
| Yearly Pro | $49.99 / year | `STRIPE_PRICE_PRO_ANNUAL` |
| Lifetime Pro | $149.99 once | `STRIPE_PRICE_PRO_LIFETIME` |
| Team (only products with teams) | per seat / month | `STRIPE_PRICE_TEAM_SEAT` |

- Display names are exactly **Free, Monthly Pro, Yearly Pro, Lifetime Pro**
  (Spanish where the product is bilingual: Gratis, Pro mensual, Pro anual,
  Pro de por vida).
- A free trial on Monthly/Yearly is optional per product (`STRIPE_TRIAL_DAYS`).
- Stripe is the price source of truth; `config/billing.php` `display_prices`
  are for the UI only.
- Lifetime is a one-time Stripe payment recorded as `pro_lifetime_at` (or the
  product's equivalent) and revoked by the refund webhook.

## 3. Distribution

| Client | Where users get it | Price | Can it link to buying Pro? |
|---|---|---|---|
| Website | `<product>.app` | Free + Pro | Yes — it is the store |
| Android | Google Play | **Free** | **No** (switch off) |
| iOS / iPadOS | App Store | **Free** | **No** (switch off) |
| Desktop (Windows / macOS / Linux) | Download from the website; auto-updates (`electron-updater`) | Free download (a product may make the desktop app Pro-only, as FileManagerFlow does) | Yes |
| Browser extension | Chrome Web Store / Firefox Add-ons | Free | Yes |

**Desktop signing (required before launch):** Windows — a code-signing
certificate (SSL.com eSigner EV, or Microsoft Azure Trusted Signing); macOS —
Developer ID signing + notarization with the same Apple Developer account used
for iOS; Linux — AppImage / .deb from the website. No Mac App Store or
Microsoft Store listing.

**Accounts (company-owned, as Moon Whale Media, LLC):** Apple Developer
Program ($99/yr, needs a D-U-N-S number), Google Play Console ($25 once),
Stripe, Windows code-signing. Nothing else.

## 4. The store billing switch (every product with phone apps)

Rules change (US court orders in 2025 already allow some external links), so
every product can re-enable purchase links **per store, from the server,
without an app update**:

```php
// config/billing.php
'app_purchase_links' => [
    'android' => (bool) env('APP_PURCHASE_LINKS_ANDROID', false),
    'ios' => (bool) env('APP_PURCHASE_LINKS_IOS', false),
],
```

- Both default **false** and stay false unless Moon Whale Media deliberately
  decides otherwise for every product at once (universal standard).
- The app config endpoint (`GET /api/v1/config`, or the product's existing
  config endpoint) takes `?platform=android|ios` and returns:
  - `capabilities.purchase_links` — true only when that platform's switch is
    on (false for a missing or unknown platform);
  - `capabilities.manage_billing` — true only for an existing **web**
    subscriber, so they can still reach Stripe's portal to manage or cancel
    (managing is not selling).
- **App view:** website pages the apps open (Privacy, Terms, Help) carry
  `?from=app&platform=android|ios`. An `AppViewMode` middleware marks that
  browser session (2 h) while the switch is off: the shared Inertia prop
  `appView` hides every Pricing link and upgrade prompt, and `/pricing` +
  checkout redirect home. Opening the site directly is unaffected.
- Reference implementation: **IdentiFlow** — `config/billing.php`,
  `app/Http/Controllers/Api/ConfigController.php` (`purchaseLinks()`,
  `appLink()`), `app/Http/Middleware/AppViewMode.php`,
  `tests/Feature/Api/StoreBillingSwitchTest.php`,
  `tests/Feature/AppViewModeTest.php`; Android `Session`/`UpgradePrompt`;
  iOS `Session`/`Components.swift` (commits f2b7838, d51b135, c7a7f91, d41ced5).

## 5. What each client must do

**Web (Laravel):**
- Cashier + `config/billing.php` with the plans above, `app_purchase_links`,
  and the config-endpoint capabilities.
- `AppViewMode` middleware and the `appView` shared prop.
- Upgrade emails and the Free-limit messages link to `/pricing`.
- No store webhooks (RevenueCat / App Store Server Notifications / Play RTDN)
  and no receipt-verification endpoints.

**Android and iOS:**
- Read `capabilities.purchase_links` / `manage_billing` from the config
  endpoint (send `platform=`), refresh on sign-in and when the app returns to
  the foreground; treat a missing value as **false**.
- `purchase_links == false`: hide every Upgrade / Go Pro button, pricing card,
  price, and link to the website's pricing or checkout; locked features show
  neutral text. The web-handoff "open the website signed in" flow may still be
  used for account pages, never for checkout.
- "Manage Billing" only when `manage_billing` is true.
- Add `?from=app&platform=…` to every website URL the app opens.
- No billing SDKs or permissions: remove RevenueCat, `billing-ktx`,
  `com.android.vending.BILLING`, StoreKit product code, and IAP products.
- Pro features, ad removal and limits all follow the server's answer.

**Desktop and extensions:** "Upgrade to Pro" opens the website (signed in via
web handoff where available). Desktop builds are signed/notarized and
auto-update from the website's release feed.

## 6. Store submission notes

- **App Store:** free app, no in-app purchases. Review note: *"<Product> is a
  free companion app to the <Product> web service. The app contains no
  purchasing and no calls to action to purchase outside the app (App Review
  Guideline 3.1.3(f)). Accounts that subscribe on our website can use their
  existing subscription in the app."* Provide a demo Pro account.
- **Google Play:** free app, no in-app products; Payments policy — the app
  only lets users access a subscription purchased elsewhere and does not lead
  users to an outside payment method.
- Account deletion stays available inside every app (Apple 5.1.1(v), Google
  Play account-deletion policy).
- If a reviewer insists on in-app purchase for one app, the fallback is to add
  it for that app only (RevenueCat → one webhook into the same server-side Pro
  record, `pro_source` = apple/google). It is not needed while the rules above
  are followed.

## 7. Per-product checklist

- [ ] Plans, names and prices match section 2.
- [ ] `app_purchase_links` + config capabilities + `AppViewMode` (products with phone apps).
- [ ] Apps hide all purchase UI when `purchase_links` is false; Manage Billing gated on `manage_billing`.
- [ ] No IAP code, SDKs, permissions, webhooks or store products anywhere.
- [ ] Upgrade emails / Free-limit messages point at `/pricing` on the website.
- [ ] Desktop / extension upgrade links go to the website; desktop builds signed + notarized.
- [ ] LAUNCH_CHECKLIST, DEPLOYMENT, OWNER_OPS, legal bundle and store-submission docs describe this model.
- [ ] Tests cover the switch (off hides links; on shows them; manage_billing only for web subscribers).

---

Canonical copy: `C:\Users
Canonical copy: `C:\Users\vzwhaley\Herd\MOON_WHALE_MEDIA\MWM_BILLING_AND_DISTRIBUTION_STANDARD.md` (keep the two identical).
