# Moon Whale Media — Claude Code Skills

Personal Claude Code skills shared across all projects and machines. This directory **is** `~/.claude/skills` — Claude Code auto-discovers every `<skill-name>/SKILL.md` here in every project.

## Skills

| Skill | What it's for |
|---|---|
| `mwm-new-product` | Bootstrap a new Moon Whale Media product monorepo (web + optional android/ios, docs, branding) |
| `mwm-laravel-app` | Laravel 13 + Inertia/Vue house conventions — BrandLogo, footer, AdSlot, consent, SEO, billing, security |
| `mwm-symfony-app` | The same house conventions mapped onto Symfony 7 |
| `mwm-android-app` | Kotlin + Compose + M3 conventions — signing, Sanctum API client, theming, ads |
| `mwm-ios-app` | SwiftUI + XcodeGen conventions — Keychain tokens, StoreKit 2, SPM-minimal policy |
| `mwm-brand` | Logo lockup rules (mandatory tagline), Spantaran, OG images, favicons, icons + rendering gotchas |
| `mwm-ui-copy` | UI copy conventions — Title Case for every title/button/badge/label + the ™ brand-name rule |
| `mwm-media-kit` | Regenerate a product's docx+pdf media kit with the house outline and screenshot tour |
| `mwm-doc-generator` | Any docx+pdf deliverable pair — OOXML + headless Chrome recipe (template included) |
| `mwm-launch-runbook` | LAUNCH_CHECKLIST / DEPLOYMENT / OWNER_OPS / legal bundle / store submission scaffolds + pre-launch audit |
| `mwm-session-handoff` | Create/refresh SESSION_HANDOFF.md in the house §0–§9 skeleton |

## Setup on a new machine (Mac or Windows)

```bash
# If ~/.claude/skills doesn't exist yet:
git clone git@github.com:vzwhaley/claude-code-skills.git ~/.claude/skills
```

If `~/.claude/skills` already exists with content, clone elsewhere and merge, or:

```bash
cd ~/.claude/skills
git init && git remote add origin git@github.com:vzwhaley/claude-code-skills.git
git fetch origin && git checkout -f -b main origin/main
```

## Keeping machines in sync

- After editing a skill on either machine: `git add -A && git commit -m "..." && git push`
- On the other machine: `git -C ~/.claude/skills pull`
- Skills are read at session start — restart/new Claude Code session to pick up changes.

## Conventions for editing

- One skill = one directory with a `SKILL.md` (frontmatter: `name`, `description`). The `description` drives auto-triggering — keep it specific about *when* to use the skill.
- Supporting assets (templates, scripts) live inside the skill's directory (e.g. `mwm-doc-generator/template/`).
- Windows-specific and Mac-specific guidance is called out inline in each skill rather than split into separate skills.
