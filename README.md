# Streaks

A streak counter for breaking bad habits, with a built-in "talk me out of it"
intervention deck. iOS, SwiftUI, on-device-first. The full spec lives in the handoff
docs, which are kept locally (not committed to this repo).

## Status

**PR #1 — MVP scaffold.** This branch establishes the project so later feature PRs
have somewhere to land. It is intentionally minimal.

Included:
- Xcode project (`Streaks.xcodeproj`), single app target, iOS 17+, SwiftUI.
- **App Group** entitlement (`group.com.jordantam.streaks`) so the future widget
  can share the store.
- **Core Data** stack (`PersistenceController`) with the store in the App Group
  container. Model: `Habit`, `ResetEvent`, `InterventionSession`, `Question`.
- MVVM folder skeleton under `ios_frontend/{App,Models,Views,ViewModels,Utilities}`.
- Derived streak math (`StreakMath`) + `QuestionProvider` seam (§6).
- Placeholder Home screen that builds and runs.

Not yet built (later PRs, per handoff §11): create-habit onboarding, Habit Detail,
swipe-to-slip + undo, the intervention deck, and the WidgetKit extension.

## Getting started

1. Open `Streaks.xcodeproj` in Xcode 16+ (developed against Xcode 26).
2. In **Signing & Capabilities**, select your team and confirm the **App Groups**
   capability is enabled for `group.com.jordantam.streaks`. (The entitlement is
   already wired; enabling the capability needs your Apple Developer account.)
3. Build & run on an iOS 17+ simulator.

## Layout

```
ios_frontend/
  App/          StreaksApp entry point
  Models/       Core Data model + domain enums
  Views/        SwiftUI screens
  ViewModels/   MVVM view models
  Utilities/    App Group, persistence, streak math, question provider
  Resources/    Assets
```

## Conventions

- Do all work on a feature branch; never commit to `main`. Jordan reviews via PR.
- Energy Calendar is **read-only reference** — never written to, never coupled.
