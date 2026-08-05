---
name: mwm-media-kit
description: Generate or regenerate a Moon Whale Media product media kit (.docx + .pdf pair at repo root) with the house section outline, screenshot tour, and logo band. Use when the user asks for a media kit, press kit, or to refresh product screenshots/marketing docs for any product.
---

# Moon Whale Media — Media Kit Generator

Every product ships `<Product>_Media_Kit.docx` + `.pdf` **at the monorepo root**, gitignored. Core rule: **one content structure renders both deliverables so they can never drift; never hand-edit the .docx.** Generators are versioned in `build-tools/` (they "used to live in Claude session scratchpads and were lost twice" — always commit them).

Every generator header carries a **SOURCE OF TRUTH** line naming the doc to update first (e.g. `SESSION_HANDOFF.md`, a feature guide). Update that doc, then regenerate.

## Two proven lineages — reuse whichever the project already has

### Lineage A — Python + puppeteer (AstrologerFlow, CoderStudyFlow)
- `build-tools/media-kit/shoot.js` (puppeteer-core against the live Herd site, `fullPage: true`, `deviceScaleFactor: 1.5`) → `out/*.png` + `out/captions.json` (`{order, captions}`). Pages declared as `[name, url, caption]` tuples split into `GUEST_PAGES` / `MEMBER_PAGES`.
- **Pre-seed the cookie-consent localStorage key before any page script runs** so the banner doesn't overlay every shot; hide dev "Your Ad Here" placeholders.
- `build_kit.py` — python-docx for the DOCX + an HTML twin printed via headless Chrome for the PDF, from the same constants.
- `seed_demo.php` — idempotent fictional demo account (John Doe) for member-page shots.
- `verify.js` — renders the kit back to PNG and counts real `/Type /Page` PDF objects; `file x.pdf` lies about page count.

### Lineage B — pure PowerShell OOXML (FileManagerFlow, SocialStashFlow)
- `build-tools/generate-media-kit.ps1`, descended from `~/.claude/templates/docx_pdf_generator.ps1` (and the `mwm-doc-generator` skill). Raw OOXML zip (no Word COM) + headless Chrome print-to-PDF. Params `-OutDir`, `-SkipPdf`, `-SkipDocx`. Block kinds: `logo|title|subtitle|meta|h1|h2|h3|p|note|table|gallery`; inline `**bold**`, backtick code, `[text](url)`.
- Screenshots in `build-tools/media-kit-assets/`, `image1.png` reserved for the logo lockup. A `$Gallery` manifest maps captions → file lists; missing files warn-and-skip; unlisted files land under a catch-all caption so nothing is silently lost.
- Script file must be **UTF-8 with BOM**; author with ASCII quotes only (PS 5.1 treats curly quotes as string delimiters).

## The house section outline

```
[logo band]  ·  Title "<Product>™ Media Kit"  ·  Subtitle
Meta (prepared date · Moon Whale Media, LLC · domain · scope statement)
1. About <Product>™
2. Fast Facts                      (2-col table: Product/Company/Platform/Price/…)
3. <Product-specific mechanic>     (e.g. The Privacy Model / How Stashing Works)
4. The Free Plan — Every Feature In Full
5. The Pro Plan — Every Feature In Full
6. Plans & Pricing
7. Platform Availability
8. Privacy, Security & Trust
9. Brand & Style Guidelines        (Title Case headings, sentence case body)
10. Links & Contact
11. The Website — A Visual Tour    (data-driven gallery; each caption starts a new page)
```
Press-oriented variants add: a legal DISCLAIMER on the cover, a BOILERPLATE paragraph "for press use", and "What Makes X Different".

## Hard-won traps (do not re-learn)

1. **Tall captures:** full-page screenshots can be 180+ inches tall — slice into page-shaped tiles (cache in `out/.sliced/`), cap ~3 tiles per page.
2. **Blank PDF tour:** Chrome prints before big PNGs decode — `--virtual-time-budget=120000` + `--run-all-compositor-stages-before-draw` are required.
3. **Logo on white:** the site lockup is light-on-dark; pre-compose it onto a dark band (`logo_band.ps1`/`logo_band.js`) or the wordmark vanishes. The `-Og` switch on `logo_band.ps1` regenerates the site OG image from the same lockup.
4. **Typography:** author in plain ASCII; convert ` -- `→em-dash and straight→curly quotes at render time (`typo()` helper), never in source.
5. Validate output structurally: PDF page count via `/Type /Page` objects, `.docx` must list all five OOXML parts and exceed ~3 KB.
6. The lockup in the kit ALWAYS includes the "by moon whale media, llc" tagline (see mwm-brand skill).

## For a brand-new product

Copy the nearest generator (Lineage B is the more portable starting point), change the brand constants + `$Gallery`/page tuples, add the kit filenames to `.gitignore`, and commit the generator under `build-tools/`.
