# HANDOFF_02 — Streaks MVP core loop

> Progress handoff for the work delivered on branch **`mvp-core`** (off `main`).
> Continues [`HANDOFF_01_streak_app.md`](HANDOFF_01_streak_app.md). Covers §11 steps
> 1–5 of the original handoff; the WidgetKit extension (step 6) is the remaining piece.

---

## 1. What shipped

Two branches of work, both off `main`:

**Scaffold (already on `main`)**
- `Streaks.xcodeproj` (hand-authored — no xcodegen/tuist/brew on the machine), single
  app target, iOS 17+, SwiftUI.
- App Group entitlement `group.com.jordantam.streaks`.
- Core Data stack (`PersistenceController`) with the store in the App Group container.
  Model: `Habit`, `ResetEvent`, `InterventionSession`, `Question` (class-definition
  codegen — entity classes are generated, no hand-written NSManagedObject subclasses).
- MVVM layout under `ios_frontend/{App,Models,Views,ViewModels,Utilities,Resources}`.
- `CLAUDE.md` with the repo conventions (see §5).

**Core app loop (branch `mvp-core`, this handoff)**
- **Onboarding** (§5.5): name + category + start date → creates the habit.
- **Routing**: `ContentView` shows onboarding when no habit exists, else Home, via a
  `@FetchRequest` so it swaps automatically on create.
- **Home** (§5.1): live day count, "resisted N times", tap-through to Detail,
  "Talk me out of it" CTA.
- **Habit Detail** (§5.2): day count, times-resisted, longest streak displayed as
  `max(stored, current)`, reset history, links to the deck and the prompt editor.
- **Swipe-to-slip + undo** (§5.4): swipe the "I slipped" row → day count resets to 0
  and a `ResetEvent` is logged immediately; a 5-second **undo snackbar** can roll it
  back. No confirmation modal. Longest streak is only promoted on confirm, so an undo
  leaves the record untouched.
- **Intervention deck** (§5.3): fresh Tinder-style `SwipeCard` stack (Energy Calendar
  was reference only — never read/written here). Seeds a stakes card when a streak is
  on the line. **"I'll pass"** logs an `InterventionSession(resisted)` + celebration +
  success haptic; **"I gave in"** routes into the same slip path. Empty state when the
  habit has no prompts.
- **Prompts** (§6): user-defined only for MVP — full CRUD + drag-to-reorder, fronted by
  the `QuestionProvider` protocol seam.

## 2. Architecture notes

- **`HabitRepository`** (`Utilities/`) is the single choke point for every Core Data
  mutation — create habit, slip/confirm/undo, log resist, question CRUD, derived
  counts. View models stay thin and the streak rules live in one testable place.
- **Derived, never stored** (§7): day count = `today − currentStreakStart` and
  times-resisted = count of `resisted` sessions. `StreakMath` holds the pure functions
  (also reusable by the future widget).
- **`SlipController`** owns the optimistic-slip + undo-window state machine and is
  hosted by any screen that can trigger a slip (Home, Habit Detail); `slipSnackbar`
  is the shared overlay.
- **`QuestionProvider`** has one implementation today (`CoreDataQuestionProvider`).
  A bundled-default or LLM source can be added later behind it without touching the deck.

## 3. Verification

- `xcodebuild -scheme Streaks -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` →
  **BUILD SUCCEEDED** (clean).
- Installed + launched on the iOS 26 simulator: app runs, onboarding renders, no crash
  — exercising the real Core Data / App Group container / routing paths.
- Not automated end-to-end (no UI-automation tool for the simulator in this
  environment); the deeper deck/slip interactions were verified by construction + build,
  not by scripted taps.

## 4. Not done yet

- **WidgetKit extension** (handoff §11 step 6): small + medium showing the day count /
  times-resisted, reading the shared App Group store. Adds a **second Xcode target** —
  its own branch/PR. `AppGroup` + `StreakMath` are already widget-ready.
- Deferred by original scope: Apple Watch, LLM prompts, notifications, multi-habit UI,
  iCloud/sync. See HANDOFF_01 §9.

## 5. Conventions (also in `CLAUDE.md`)

- **Never commit to `main`.** Work on a branch; review/merge via PR. Don't push without
  Jordan's go-ahead.
- **Branch names: plain kebab-case, no prefix** (`mvp-scaffold`, `mvp-core`,
  `widget`). No `feature/` / `fix/` prefixes.
- **Commit messages: brief plain summary line, no `feat:` / `fix:` type prefixes.**
- **Energy Calendar is read-only reference** — never written to, never coupled.

## 6. Running it

1. Open `Streaks.xcodeproj` in Xcode 16+ (developed against Xcode 26).
2. Signing & Capabilities → select your Team; confirm **App Groups** is enabled for
   `group.com.jordantam.streaks`. (Entitlement is wired; enabling the capability needs
   your Apple Developer account. Simulator runs work without it.)
3. Pick an iOS 17+ simulator and Run (⌘R). First launch shows onboarding.

## 7. Suggested next step

Branch `widget` off `main` (after `mvp-core` merges) and build the WidgetKit extension:
add the extension target to the project, share `AppGroup` + `StreakMath` + a lightweight
read of the primary habit, and provide small + medium (+ optional Lock Screen) families
with a midnight timeline refresh (§8 of HANDOFF_01).
