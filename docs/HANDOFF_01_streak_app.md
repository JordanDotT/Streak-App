# HANDOFF_01 — Streaks

> A streak counter for breaking bad habits / battling addiction, with a built-in
> "talk me out of it" intervention flow. Passive day-counter **and** a
> times-resisted counter + swipe-card reflection deck + home-screen widget.
> iOS, SwiftUI, on-device-first.

---

## 0. Repo & workflow (read first)

- **Repo:** `/Users/jordantam/Documents/streaks_app` (GitHub remote already set up).
- **Branching is a hard rule.** Do **all** work on a dedicated feature branch off
  `main` (e.g. `feature/mvp-scaffold`, or one branch per handoff). **Never commit
  directly to `main`.** Jordan reviews and merges via PR — this is a
  human-in-the-loop workflow.
- **Energy Calendar is read-only reference only.** Claude Code may *read* the
  Energy Calendar project to crib the swipe-deck pattern, but must **never write
  to it** and must not couple the two projects (no shared package, no shared
  source). The deck is **re-implemented fresh** in this repo. If Jordan wants the
  EC deck used as a visual reference, he'll supply its local path; otherwise build
  the deck from scratch.

## 1. Concept

Two jobs, one app:

1. **Counter.** Track how long the user has gone without doing the thing they're
   trying to quit (e.g. impulse spending), *and* how many times they've resisted.
   The main screen answers: *"How many days clean am I?"* and *"How many times have
   I resisted?"*
2. **Preventative measure.** When the user is *tempted*, they open the app, hit a
   prominent button, and get walked through a deck of swipeable reflection cards
   designed to talk them out of it. At the end they either resist (streak
   continues, resist logged) or give in (streak resets).

The spending example is the canonical use case, but the app is habit-agnostic.

## 2. Core user loop

```
open app ─► see streak: "12 days clean · resisted 8 times"
              │
              ├─ (passive) do nothing → day counter keeps ticking up
              │
              └─ tempted → tap "Talk me out of it"
                             │
                             ▼
                   swipe through reflection cards
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
              "I'll pass"        "I gave in"
          (resist logged +      (→ slip: swipe-to-reset
           lightly celebrated,   with undo; day count → 0,
           day streak continues) resist tally survives)
```

## 3. Tech stack & conventions

- **SwiftUI**, iOS 17+ (modern WidgetKit + Lock Screen widgets).
- **CoreData** for persistence (consistent with Energy Calendar; not SwiftData).
- **MVVM**, feature-organized under canonical paths:
  `ios_frontend/{Models,Views,ViewModels,Utilities}`.
- **On-device-first.** No backend, no LLM in MVP. Questions = bundled static bank +
  user-defined (see §6). LLM generation is deferred behind a clean seam.
- **App Group** from day one so the widget can read streak data.
- **Bundle ID:** suggested `com.jordantam.streaks` (editable — but settle it before
  wiring the App Group `group.com.jordantam.streaks…`, since renaming it later
  touches the widget). Display name is "Streaks" and can change freely anytime.

## 4. MVP scope

**In:**
- Track a **single habit** for MVP (name + optional category + start date), but
  model it as a first-class entity with relationships so **multiple habits are a
  later UI addition, not a migration** (see §7).
- Passive day-counter (days since last reset, derived).
- **Times-resisted counter** (count of "I'll pass" outcomes, survives resets).
- "Talk me out of it" intervention deck (swipe cards) → resist / gave-in outcome.
- Slip logging as a **swipe with undo** (no confirmation modal — see §5.4).
- Longest-streak tracking + a simple reset history log.
- Home-screen widget showing the streak (small + medium).
- Bundled default question bank per category + user-defined custom questions.

**Out (future, do not build yet):**
- Apple Watch app / complications.
- LLM-generated questions.
- Notifications / reminders.
- Multi-habit UI (data model is ready for it; UI is not built yet).
- iCloud sync, accounts, anything server-side.

## 5. Screens & flows

### 5.1 Home
- MVP: focused on the single tracked habit. Big day count + secondary
  "resisted N times" stat.
- Primary CTA: **"Talk me out of it."**
- (Layout should tolerate a future list of habits without a rewrite.)

### 5.2 Habit Detail
- Large day counter ("X days clean").
- Times-resisted counter.
- Longest streak, displayed as `max(longestStreakDays, currentStreakDays)` so an
  in-progress record streak isn't undercounted. (`longestStreakDays` is only
  recomputed at slip time — §5.4.)
- Reset history (dates of past slips) — a simple list for MVP; a GitHub-style
  heatmap is a nice-to-have you already have a pattern for.
- Buttons: **Talk me out of it**, **Edit questions**. (Slip is a swipe, §5.4.)

### 5.3 Intervention deck ("Talk me out of it")
- **Re-implement the Tinder-style swipe deck** (reference Energy Calendar's, build
  fresh here). Each card = one reflection prompt; swipe to advance.
- Cards drawn from this habit's question set (defaults + custom). Consider seeding
  one *stakes* card: "You're 12 days in — reset to zero?"
- End of deck → outcome:
  - **"I'll pass"** → log an `InterventionSession` with `outcome = resisted`,
    increment the times-resisted counter, show a quick affirming screen + haptic.
    Day streak untouched.
  - **"I gave in"** → slip (§5.4).

### 5.4 Slip (reset) — swipe + undo
- **No confirmation modal.** Slipping is a **swipe action** that immediately resets
  the day count to 0 and appends a `ResetEvent`.
- An **undo snackbar** persists for a few seconds so a fat-finger is recoverable.
- On confirm (snackbar timeout), update longest streak if the ended streak beat it.
- The **times-resisted tally is unaffected** by a slip — only the day count resets.
- Same slip path is reached from the deck's "I gave in" and any standalone slip
  affordance.

### 5.5 Onboarding / create habit
- Name (e.g. "Impulse spending"), category (cosmetic for MVP — see §7),
  start date (defaults to now).
- No prompts are seeded; the user adds their own from Habit Detail. The deck's
  empty state (§6) covers a habit with zero prompts.

## 6. Question bank

- **User-defined prompts only for MVP.** No bundled default bank. Each prompt is a
  short reflection the user writes to talk *themselves* out of giving in. Questions
  are per-habit, editable from Habit Detail. CRUD + ordering.
- Deck = that habit's user-defined questions (plus the optional seeded *stakes*
  card, §5.3).
- **Empty state:** a brand-new habit has no prompts, so the deck shows a friendly
  "add your first prompt" empty state rather than blocking habit creation.
- **Deferred:** bundled category defaults **and** LLM-generated questions. Put a
  `QuestionProvider` protocol in front of the deck so either source can be added
  later without reworking it. MVP ships one implementation: a CoreData-backed
  provider returning the habit's custom questions.

## 7. Data model (CoreData)

- **Habit**: `id`, `name`, `category`, `createdAt`, `currentStreakStart`,
  `longestStreakDays`. (First-class + relationships so multiple habits work later.)
- **ResetEvent**: `id`, `habit` (relationship), `date`, optional `note`.
- **InterventionSession** (core, not optional): `id`, `habit` (relationship),
  `date`, `outcome` (`resisted` | `gaveIn`). Times-resisted = count of `resisted`
  sessions for the habit.
- **Question**: `id`, `habit` (relationship, **non-nullable** — every prompt belongs
  to a habit; no category-level rows in MVP), `text`, `isUserDefined` (always `true`
  for MVP), `sortOrder`.

`Habit.category` is retained but **cosmetic for MVP** — it no longer drives a default
question bank (§6); nothing reads it yet. Kept for the future default-bank / LLM seam.

Both headline numbers are **derived**, not stored: day count =
`today − currentStreakStart` (calendar days); times-resisted = count of resisted
sessions. Store the CoreData stack in the App Group container.

## 8. Widget (WidgetKit)

- Reads the shared App Group store.
- **Small:** big day number + habit name (option to show times-resisted instead).
- **Medium:** day streak + times-resisted + longest / a short encouragement line.
- **Lock Screen accessory** (circular/inline) is a cheap iOS 17 add — nice if easy.
- Timeline refreshes at the day boundary (midnight) so the day count rolls over.
- MVP targets the single habit — **defer the App Intents habit-picker** until
  multi-habit UI exists.

## 9. Future roadmap (not this handoff)

- **Apple Watch:** glanceable streak, a complication, and a quick "tempted" tap
  that runs a short pause/breathing micro-intervention.
- **LLM-generated questions** via the `QuestionProvider` seam.
- **Notifications:** optional daily encouragement or user-set "risky time" nudges.
- **Multi-habit UI** on top of the already-multi-ready model.
- **Stats:** resisted-vs-slipped over time, streak history charts.

## 10. Locked decisions

1. **Name:** "Streaks" (display name; bundle ID `com.jordantam.streaks`, editable).
2. **Habits:** single-habit UI for MVP; model supports many for later.
3. **Counting:** passive elapsed-days (no daily check-in) **plus** a times-resisted
   metric that survives resets.
4. **Slip friction:** swipe-to-reset with an undo snackbar; no confirmation modal.
5. **Resists:** "I'll pass" is logged and lightly celebrated; feeds times-resisted.
6. **Workflow:** all work on a feature branch, never on `main`; Energy Calendar is
   read-only reference, never written to.
7. **Questions:** user-defined prompts only for MVP — no bundled default bank.
   `Question.habit` is non-nullable; deck empty-state covers a habit with no prompts.
8. **Longest streak:** recomputed only at slip time; Habit Detail shows
   `max(longestStreakDays, currentStreakDays)`.

## 11. Suggested first steps for Claude Code

1. Create a feature branch off `main` (e.g. `feature/mvp-scaffold`). Do everything
   there; open a PR for Jordan to review.
2. Scaffold the project + App Group + CoreData stack under
   `ios_frontend/{Models,Views,ViewModels,Utilities}`.
3. Habit model + create-habit onboarding + Home (derived day count + resist count).
4. Habit Detail + swipe-to-slip with undo + reset history.
5. Intervention deck (fresh swipe deck) → resist logging + celebration; wire the
   default + custom question banks behind a `QuestionProvider` protocol.
6. WidgetKit extension (small + medium) reading the shared store.
