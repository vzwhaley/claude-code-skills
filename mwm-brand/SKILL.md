---
name: mwm-brand
description: Moon Whale Media branding rules and asset-rendering recipes — logo lockup with mandatory "by moon whale media, llc" tagline, Spantaran font, BrandLogo components, OG images, favicons, app icons. Use whenever creating or regenerating any logo, wordmark, brand header, share image, favicon, or launcher icon for any Moon Whale Media product on any platform.
---

# Moon Whale Media — Brand & Asset Rendering

## The lockup (non-negotiable)

The official lockup for EVERY product is: **product mark + "`<Product>`™" wordmark + "by moon whale media, llc" signature line in the Spantaran font**. The tagline is NOT optional — it appears everywhere: web UI, generated email/logo images, media kits, OG images. Never ship a mark-only or wordmark-only version.

- Wordmark convention: compound name split across two colors — first word(s) in ink, last word in the brand accent (e.g. "CoderStudy" ink + "Flow" blue), with superscript ™.
- The tagline links to `https://moonwhale.media` on the web and uses `class="font-brand"` (Spantaran).
- Spantaran is used ONLY for the tagline/signature — body text stays system/default fonts.

## Where assets live (per product convention)

- Web font: `<slug>-web/public/fonts/Spantaran.ttf`
- Android font: `<slug>-android/app/src/main/res/font/spantaran.ttf`
- iOS font: `<ios-app>/App/Spantaran.ttf`
- `BrandLogo` component: `BrandLogo.vue` (web, props: `variant: 'light'|'dark'`, `iconClass`, `tagline: Boolean` **default true — never set false**, `href`), `BrandLogo.kt` (Compose Canvas), `BrandLogo.swift` (SwiftUI) — **logos are drawn in code, not shipped as bitmaps**, visually identical to the launcher/app icon.
- Composed lockup PNGs and render scripts live in `build-tools/` (e.g. `build-tools/media-kit/logo_band.ps1`, `build-tools/generate-og-image.ps1`).

## Rendering recipes (hard-won — do not re-learn)

### Screenshot a lockup HTML to transparent PNG (headless Chrome)

1. **Use legacy `--headless`, NOT `--headless=new`** — the new headless yields a blank ~1.4 KB transparent frame even with `--virtual-time-budget`.
2. **Embed Spantaran as a base64 `data:` URI in `@font-face`** — `file://` font subresources don't load reliably in headless.
3. Working flags:
   ```
   chrome --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=2
     --default-background-color=00000000 --screenshot=out.png
     --window-size=W,H --user-data-dir=<tmp> <file-uri>
   ```
4. The site lockup is light-ink-on-dark; embedded raw on a white page the wordmark vanishes — pre-compose it onto a dark band first (that's what `logo_band.*` scripts do).

### OG / share images

1200×630, dark brand band + full lockup + short value line. See `NewsroomFlow/build-tools/generate-og-image.ps1` for a working PowerShell recipe.

### Favicons

`generate-favicons.ps1` pattern: favicon.svg → headless Chrome → 180/96/32 PNGs → assemble `favicon.ico`.

### Android launcher / app icons

- Prefer **vector adaptive icons** (`mipmap-anydpi-v26/ic_launcher.xml` + vector foreground/background + `<monochrome>` layer) — no PNG ladder needed.
- For a 1024×1024 store icon, pure PowerShell + `System.Drawing` works with no ImageMagick (see `NewsroomFlow/build-tools/generate-android-icon.ps1`: brand gradient + monogram).

## House visual style

- Dark "ink" footers on websites (see the shared footer pattern across products).
- Platform theme tokens (Compose `Theme.kt`, SwiftUI `Brand.swift`) mirror the product website's Tailwind palette **by hex**, with the source noted in a comment (e.g. `// mirrors text-indigo-600 from the web app`).
- Company boilerplate: "Moon Whale Media, LLC" — copyright lines read `© <year> Moon Whale Media, LLC`.
