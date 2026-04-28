# CloseCut

CloseCut is an iOS app for tracking movies and series through an emotional lens. Instead of focusing on ratings-first cataloging, it is built around memory, mood, takeaway, context, and personal watch history.

The current in-app positioning is straightforward: **a private emotional journal for movies and series**.

## Overview

CloseCut currently supports:

- Email/password authentication with Firebase Auth
- A local-first onboarding flow
- A personal timeline of watched titles
- Full entry creation and editing
- A lightweight `Quick Add` flow for past watches
- A foundation for social sharing through `Circle`

The app is already structured to grow into sync, recommendations, and social features without replacing the local core.

## Tech Stack

- `SwiftUI` for UI and navigation
- `SwiftData` for local persistence
- `Firebase Auth` for authentication
- `Firebase Firestore` for remote profile storage and future sync infrastructure
- `Swift Testing` and `XCTest / XCUITest` for test infrastructure

## Product Direction

CloseCut is designed around a few core ideas:

- Track what you watched and when
- Capture how it made you feel
- Save personal context, tags, and standout moments
- Build a private viewing history over time
- Eventually enable selective sharing with a trusted circle

## Current Feature Set

### Authentication

- Sign up and sign in with email and password
- Reactive auth state handling via Firebase
- Human-readable error messages for common auth failures

Key file:
- `CloseCut/CloseCut/Core/Models/AuthService.swift`

### Onboarding

- Multi-step introductory flow
- Two entry paths:
  - `Add past watches fast`
  - `Start fresh`
- Local persistence of onboarding completion through `LocalUserState`

Key files:
- `CloseCut/CloseCut/Features/Onboarding/OnboardingView.swift`
- `CloseCut/CloseCut/Core/Local/LocalUserState.swift`
- `CloseCut/CloseCut/Core/Services/UserStateRepository.swift`

### Home / Timeline

- Local timeline sorted by watched date
- `Timeline` segment for recorded entries
- `QuickPick` segment scaffolded but not implemented yet
- Toolbar entry points for full entry creation and quick add

Key file:
- `CloseCut/CloseCut/Features/Home/HomeView.swift`

### Entry Editor

Entries can include:

- Title
- Type (`movie` or `series`)
- Mood
- Takeaway
- Key moment / quote
- Intensity
- Tags
- Watch context
- Cinema-specific ratings
- Entry visibility

Key files:
- `CloseCut/CloseCut/Features/EntryEditor/EntryEditorView.swift`
- `CloseCut/CloseCut/Features/EntryEditor/EntryEditorViewModel.swift`
- `CloseCut/CloseCut/Core/Services/EntryRepository.swift`

### Quick Add

Fast capture flow for past watches:

- Search across seeded local suggestions
- Add a manual title
- Select quick sentiment
- Select approximate watch date
- Avoid duplicates through `DuplicateDetector`

Key files:
- `CloseCut/CloseCut/Features/QuickAdd/QuickAddViewModel.swift`
- `CloseCut/CloseCut/Core/Domain/DuplicateDetector.swift`

### Entry Detail

The project includes a dedicated entry detail feature with supporting UI for:

- Metadata
- Read-only tags
- Cinema experience values

### Settings

- Basic profile display
- Privacy messaging
- Sign out

### Circle

The domain model and screen exist, but the feature is still in an early placeholder state.

## App Flow

The runtime flow is:

1. `CloseCutApp` bootstraps the app, shared view models, and the `SwiftData` container.
2. `AppDelegate` configures Firebase and Firestore.
3. `RootView` decides whether to show:
   - auth,
   - session/profile loading,
   - onboarding,
   - or the main tab shell.
4. `SessionViewModel` ensures the signed-in user has a `UserProfile`.
5. `LaunchViewModel` reads `LocalUserState` to determine whether onboarding has been completed.
6. `MainTabView` exposes:
   - `Timeline`
   - `Circle`
   - `Settings`

## Architecture

The project is organized by app layer and feature area.

### Core Layers

- `App/`
  App lifecycle, app entry point, root navigation, launch gating
- `Core/Models/`
  Domain models such as `Entry`, `UserProfile`, `Circle`, `Reaction`, `Comment`
- `Core/Local/`
  `SwiftData` models for offline/local persistence
- `Core/Remote/`
  Firestore DTOs and path helpers
- `Core/Services/`
  Repositories and session-related logic
- `Core/UI/`
  Shared components, state containers, and theme primitives
- `Core/Utils/`
  Utility extensions and small helpers

### Feature Modules

- `Features/AppShell`
- `Features/Circle`
- `Features/EntryDetail`
- `Features/EntryEditor`
- `Features/Home`
- `Features/Onboarding`
- `Features/QuickAdd`
- `Features/Settings`

## Data Model and Persistence

### Local Storage

The `SwiftData` model container currently includes:

- `LocalEntry`
- `LocalReaction`
- `LocalComment`
- `LocalCircle`
- `LocalUserProfile`
- `LocalUserState`
- `PendingAction`

That structure strongly suggests a local-first architecture prepared for:

- offline usage
- deferred sync
- sync status tracking
- pending action handling

### Remote Storage

Firestore support currently exists for:

- app configuration bootstrapping
- remote `UserProfile` read/write
- DTO definitions for `Entry`, `Comment`, `Reaction`, `Circle`, and `UserProfile`

Important limitation:

The repository layer does not yet expose a complete bidirectional sync engine for entries, comments, reactions, or circles. The groundwork exists, but the implementation is not complete.

## Project Status

### Implemented or clearly working

- Firebase authentication
- Local onboarding state
- User profile creation/ensure flow
- Local timeline rendering
- Entry creation and editing
- Quick add flow
- Shared UI theme and reusable components

### Incomplete or still under construction

- Real `Circle` functionality
- Recommendation logic for `QuickPick`
- Full content sync beyond profile creation/update
- Meaningful automated test coverage

## Repository Structure

```text
CloseCut/
├── CloseCut/App
├── CloseCut/Core
│   ├── Domain
│   ├── Local
│   ├── Models
│   ├── Remote
│   ├── Services
│   ├── UI
│   └── Utils
├── CloseCut/Features
│   ├── AppShell
│   ├── Circle
│   ├── EntryDetail
│   ├── EntryEditor
│   ├── Home
│   ├── Onboarding
│   ├── QuickAdd
│   └── Settings
└── CloseCut/Tests
```

## Getting Started

### Requirements

- A recent version of `Xcode` with support for `SwiftUI`, `SwiftData`, and `Swift Testing`
- A valid Firebase project
- `Email/Password` enabled in Firebase Authentication
- A configured Firestore database
- A valid `GoogleService-Info.plist` included in the app target

### Setup

1. Open the project in Xcode.
2. Confirm `GoogleService-Info.plist` is attached to the `CloseCut` app target.
3. Enable `Authentication > Email/Password` in Firebase.
4. Create or connect a Firestore database.
5. Build and run on a simulator or device.

## Testing

The repository already includes the base test targets for:

- `Swift Testing`
- `XCUITest`

Current limitation:

The existing test files are still templates and do not yet cover the core business logic.

High-value test targets would be:

- `EntryRepository`
- `DuplicateDetector`
- `LaunchStateResolver`
- onboarding flow logic
- auth flow behavior

## Roadmap

Reasonable next steps for the project are:

- Implement real sync for `Entry`, `Reaction`, `Comment`, and `Circle`
- Replace seeded `Quick Add` suggestions with a real content source
- Build out the actual `Circle` social experience
- Add reliable unit and UI test coverage
- Implement real recommendation behavior for `QuickPick`

## Why This Project Is Interesting

CloseCut already has a distinct product angle. It is not just another watchlist or rating app. The existing architecture also reflects that intent well: local-first data, emotional metadata, progressive onboarding, and a clear path toward richer social and recommendation features.
