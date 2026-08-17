# Streaks — working conventions

Guidance for Claude Code when working in this repo.

## Branches
- **Never commit directly to `main`.** Do all work on a dedicated branch; Jordan
  reviews and merges via PR (human-in-the-loop). Don't push without asking.
- **Branch names are plain kebab-case with no prefix.** Name them after the work:
  `mvp-scaffold`, `habit-detail`, `intervention-deck`, `swipe-slip-undo`.
- **Do not** prefix branches with `feature/`, `fix/`, `chore/`, etc.

## Commit messages
- **A brief, plain summary line** describing what changed, e.g.
  `Scaffold Streaks MVP project` or `Add Habit Detail screen and reset history`.
- **Do not** use Conventional Commits / type prefixes (`feat:`, `fix:`, `chore:`,
  `refactor:`, etc.).
- Keep it short — a one-line summary is enough. Add a body only when a change
  genuinely needs explanation.

## Reference projects
- **Energy Calendar is read-only reference only** — may be read to crib patterns
  (e.g. the swipe deck), but never written to and never coupled (no shared
  package/source). Re-implement fresh here.

## Handoff docs
- **Handoffs never go on GitHub.** They live in the repo's `handoffs/` directory, which
  is **gitignored** — local-only, never committed.
- A results/summary doc for a handoff shares that handoff's number, not a new one:
  `HANDOFF_01_results.md` summarizes `HANDOFF_01`.

## Project layout
- SwiftUI, iOS 17+, Core Data, MVVM. Source under
  `ios_frontend/{App,Models,Views,ViewModels,Utilities,Resources}`.
- Full spec: the HANDOFF_01 handoff doc (kept locally in `handoffs/`, gitignored).
