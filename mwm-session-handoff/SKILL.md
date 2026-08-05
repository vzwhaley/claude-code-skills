---
name: mwm-session-handoff
description: Create or refresh a Moon Whale Media project's SESSION_HANDOFF.md in the house format. Use at the end of a significant work session, when the user says "update the handoff", "write the session handoff", or before wrapping up a session that changed a project's state.
---

# Moon Whale Media — SESSION_HANDOFF.md Writer

Every Moon Whale Media product keeps a `SESSION_HANDOFF.md` at the repo root (MyEmergencyScreen keeps it in `docs/`). It is the first thing read in a new Claude Code session. The mature skeleton (from FileManagerFlow / NewsroomFlow) is the standard — follow it exactly.

## The skeleton

```markdown
# <Product>™ — Session Handoff

**Last updated:** YYYY-MM-DD (one-line what-changed → see §N)
**Repo:** `vzwhaley/<slug>` (GitHub) · local: `C:\Users\vzwhaley\Herd\MOON_WHALE_MEDIA\<Proj>`
**Branch:** `main` — in sync with `origin/main` at **`<sha>`** — **working tree CLEAN.**

> Paste this whole file as your first message in a new Claude Code session,
> or just say "read SESSION_HANDOFF.md".

## 0. ⭐ LATEST SESSION (YYYY-MM-DD) — <theme>
   ### Dependencies — CVE/audit status per ecosystem   (only if touched)
   ### The serious bugs found & fixed
   ### Verified green
   ### Known-open (deliberate, tracked)
## 0a / 0b. EARLIER SESSIONS (condensed, newest first)
## 1. What <Product> is          (one para per client: web / android / ios; domains; dev .test host)
## 2. Current status             (commit table: | Commit | What landed |)
## 3. What's LEFT for development (code)
## 4. What's LEFT to SHIP v1 — operational (needs YOU / credentials)
## 5. How to work in this repo (build/test/git rules)
## 6. Locked decisions — do NOT re-litigate without explicit direction
## 7. Key files & docs to read first in a new session
## 8. Loose ends / notes
## 9. Suggested first message for the new session
```

## Rules for each section

- **Header**: always refresh the sha, date, and clean/dirty state at write time — run `git log -1 --format=%h` and `git status` first; never guess.
- **§0**: demote the previous §0 into a condensed §0a/§0b block (newest first). Keep a running **"Hard-won gotchas (do not re-learn these)"** subsection — environment traps, case-sensitivity bites, emulator URL quirks. Never delete existing gotchas.
- **§5** always covers the same six things: PowerShell-vs-WSL tool choice, per-platform build commands, preview/Herd URL, git rules (push after every commit; use `git commit -F <file>` because PS 5.1 mangles double quotes; commit-message prefixes `Web:|Android:|iOS:|Apps:`), emulator base URLs (`10.0.2.2` Android / `localhost` iOS), and case-sensitivity warnings.
- **§6 Locked decisions** is an anti-re-litigation contract: brand string with ™, tier pricing, naming/slug rules, deliberate exceptions. Only ADD to it; removing an entry requires the user's explicit say-so.
- **§9** is a menu of 5–7 copy-pasteable next-session prompts matching §3/§4 items.

## When updating (most common case)

1. Read the existing file fully first — preserve its locked decisions, gotchas, and condensed history.
2. Write the new §0 from what actually happened this session (bugs fixed, what was verified green, what's deliberately open).
3. Update header sha/date, §2 commit table, and prune §3/§4 items that are now done.
4. Keep total length sane: condense sessions older than ~3 into one-liners.
