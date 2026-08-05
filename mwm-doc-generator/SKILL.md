---
name: mwm-doc-generator
description: Generate .docx + .pdf document pairs (reports, action lists, guides) using the proven Moon Whale Media recipe — raw OOXML zip for Word, headless Chrome print-to-pdf for PDF, never Word COM. Use whenever producing a Word document or PDF deliverable on Windows or Mac for any project.
---

# Moon Whale Media — .docx + .pdf Pair Generator

The proven, deterministic recipe for producing Word + PDF deliverables. **Never drive Word via COM — it hangs nondeterministically in headless agent environments.**

## The recipe

1. **`.docx` → write Office Open XML directly.** A .docx is a ZIP of XML: `[Content_Types].xml`, `_rels/.rels`, `word/document.xml`, `word/styles.xml`, `word/_rels/document.xml.rels`. Zip with UTF-8 **without** BOM entries. Colors are RRGGBB; sizes are half-points (11pt → `22`); indents in twips (0.25" → `360`).
2. **`.pdf` → headless Chrome/Edge `--print-to-pdf` from styled HTML** authored from the SAME content structure, so the two can never drift:
   ```
   chrome --headless=new --disable-gpu --no-sandbox --user-data-dir=<tmp>
     --no-pdf-header-footer --print-to-pdf="<out.pdf>" "<file-uri>"
   ```
   Use `@page { size: letter; margin: 1in; }`. (Note: `--headless=new` is fine for print-to-pdf; transparent *screenshots* need legacy `--headless` — see mwm-brand.)
3. Output both files to the **current project root** (never Downloads), gitignore large/generated artifacts.

## On Windows: use the saved template

`template/docx_pdf_generator.ps1` in this skill directory (mirrored at `~/.claude/templates/docx_pdf_generator.ps1`). It has a `$blocks` content array (title/subtitle/meta/h1-h3/p/b/code/link-p/table), inline `**bold**` / backtick / `[text](url)` markup, and renders both outputs in one pass. Copy it to scratch, edit `$baseName`/`$docsDir`/`$blocks`, run via `powershell.exe -ExecutionPolicy Bypass -NoProfile -File`.

### Windows/PS 5.1 traps (each cost real time once)
1. Wrap the Chrome call — it writes "N bytes written" to **stderr on success**, which kills a `$ErrorActionPreference='Stop'` script after the PDF exists. Validate by file existence + size, never `$?`.
2. **Never pipe an array-of-pairs through `Sort-Object`** — PS unwraps single-item arrays and you get an infinite loop. Use a scalar if-chain or `[pscustomobject]` rows.
3. Emit `Write-Output "CHECKPOINT: ..."` between phases (the harness may background the run; checkpoints stream to the .output file).
4. Prefer `Bash → powershell.exe -File script.ps1` over the PowerShell tool for long scripts.
5. Sanity-check outputs: `file out.pdf` says "PDF document"; `unzip -l out.docx` lists all 5 parts; a .docx under ~3 KB is malformed.
6. PS 5.1 treats **curly quotes as string delimiters** — replace U+2018/2019 → `''` and U+201C/201D → `"` before running, and save the .ps1 as UTF-8 **with BOM** or non-ASCII mangles.

## On Mac

Same recipe, different plumbing: build the .docx with **python-docx** (or the same raw-OOXML zip via Python `zipfile`), and print the PDF with headless Chrome at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` (same flags). The `build_kit.py` lineage in AstrologerFlow/CoderStudyFlow `build-tools/media-kit/` is a working python-docx reference.

## Content conventions

- Keep .docx and .pdf content generated from one source structure — never hand-edit either output.
- Author in plain ASCII; convert ` -- ` → em-dash and straight → curly quotes at render time.
- Moon Whale Media docs carry the brand lockup (with tagline) when they're outward-facing — see mwm-brand.
