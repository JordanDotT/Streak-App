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

## Project layout
- SwiftUI, iOS 17+, Core Data, MVVM. Source under
  `ios_frontend/{App,Models,Views,ViewModels,Utilities,Resources}`.
- Full spec: `docs/HANDOFF_01_streak_app.md`.
