---
name: mwm-launch-runbook
description: Scaffold or audit Moon Whale Media pre-launch and operations docs — LAUNCH_CHECKLIST.md, DEPLOYMENT.md, OWNER_OPS.md, owner action-item docx/pdf, legal bundle, store submission kit. Use when preparing a product for launch, writing deploy runbooks, doing a pre-launch audit, or generating owner to-do documents.
---

# Moon Whale Media — Launch & Deploy Runbook

House formats for the operational docs every product ships. Scaffold from these outlines; keep the recurring facts baked in.

## Standing facts (state them in every runbook)

- **Herd (`https://<slug>.test`) is the dev host and is NOT a production server.**
- Production target: Forge/Ploi/Laravel Cloud on Ubuntu + Nginx + PHP-FPM, docroot `public/`, Let's Encrypt.
- **`.app` domains are HSTS-preloaded** — TLS must work before the first load will ever succeed.
- Transactional mail: Postmark or Brevo. Queue worker (database driver) + scheduler must both be running in production.
- NewsroomFlow's Herd link is a **directory junction**, not a symlink — never `Remove-Item -Recurse` a Herd link.

## LAUNCH_CHECKLIST.md (repo root)

Use the FileManagerFlow lettered-critical-path shape:

```
A. Legal counsel review        B. Stripe live keys & products
C. Hosting / domain / SSL      D. Production .env
E. Smoke test                  F. Keystore / signed AAB (if Android)
G. Device QA                   H. Play Console / App Store submission
I. Day-of & week-1 monitoring
Post-launch backlog (NOT blocking v1)
Things to never do
```
For multi-platform products, emoji-tag items by domain: 🌐 web · 💳 billing · 🤖 Android · 🍎 iOS · 🏪 store · 📢 ads. End with an "Already done (no action)" section so the owner sees scope shrink.

## DEPLOYMENT.md (per web app)

Numbered 1–9: Provision → production `.env` (include the full dotenv template inline) → first deploy → queue worker → scheduler → mail provider → ads/affiliate go-live → post-deploy verification → routine redeploys. Optionally 🔴/🟡/🟢 priority-code the sections.

## OWNER_OPS.md

Short (~80 lines): gating model in one paragraph · `.env` config levers · support runbook for the most likely ticket · scheduled housekeeping · abuse watch · "what is deliberately still open".

## Owner action items (docx + pdf pair, repo root)

Generated with the house doc generator (see mwm-doc-generator skill), outline:
```
How To Read This · Legend · What Changed Since the <date> Version
The Critical Path (bare minimum to go live)
<N numbered task sections>
Accounts & Costs At A Glance · Keys & Settings Reference
Already Done — No Action Needed · What I Can Build Next
```

## Legal bundle (`legal/` at repo root)

Clone the FileManagerFlow structure:
- `shared/` — legal & store-readiness checklist, store review notes, website cookie notice
- `android/` — privacy_policy.md, terms_of_use.md, eula.md, permissions & in-app disclosures, Google Play data-safety draft, support & deletion policy, CHANGELOG_FOR_COUNSEL.md
- `ios/` — same set with an App Store privacy-answers draft instead of the Play one

README shape: "not legal advice" disclaimer → How to use (bracketed placeholders; `[Developer Legal Name]` = Moon Whale Media, LLC) → **Assumptions (current v1 shipping state)** as a YES/NO matrix (accounts, cloud sync, billing, analytics, ads, uploads, storage scope) → compliance reference links.

Web legal pages: `/privacy` + `/terms` routes, footer-linked, sitemap priority 0.3. Cookie consent per the mwm-laravel-app skill.

## Store submission (mobile products)

`docs/STORE-SUBMISSION.md` kit: what the apps actually collect (source of truth section first) → Play Data-safety form answers → Apple privacy nutrition label answers → listing copy → asset checklist. If using RevenueCat: dev accounts → store products → RevenueCat config → keys in apps → server webhook → test before shipping.

## Pre-launch audit sweep (when asked to "check if we're ready")

1. Legal pages live + footer-linked + in sitemap; cookie consent gating the ad loader.
2. Ad spacing: every leaderboard has top AND bottom margin (global rule); no ads for Pro users server-side.
3. SEO: meta/OG/canonical server-rendered, sitemap + robots.txt, GA4 consent-mode defaults denied.
4. `.env` production template complete; no dev keys; `checkout_enabled` flipped consciously.
5. Security headers middleware active; HSTS OK on `.app` domains.
6. Android: release signed with real keystore (not the debug fallback warning); versionCode bumped.
7. Media kit + owner action items regenerated if features changed.
