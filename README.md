# CloseCut

CloseCut is an iOS app for tracking movies and series through an emotional lens. Instead of acting like a ratings-first catalog, it is built around memory, mood, takeaway, context, and selective sharing.

The current product positioning is simple: **a private emotional journal for movies and series**.

## What CloseCut Does

CloseCut currently supports:

- Email/password authentication with Firebase Auth
- Local-first onboarding with persisted completion state
- A personal watch timeline
- Full entry creation and editing
- Fast capture through `Quick Add`
- Rule-based `QuickPick` recommendations
- Manual and initial cloud sync for entries
- Private `Circle` spaces with invite codes, members, activity, and shared timelines

## Product Focus

CloseCut is designed around a few principles:

- Your private watch history should be useful even before social features exist
- Emotional context matters as much as title metadata
- Sharing should be selective, explicit, and circle-based
- The app should remain useful offline and sync later

## Tech Stack

- `SwiftUI`
- `SwiftData`
- `Firebase Auth`
- `Firebase Firestore`
- `Swift Testing`
- `XCTest / XCUITest`

## Current Feature Set

### Authentication

- Sign up and sign in with email/password
- Firebase-driven auth state handling
- Readable auth error messages

### Onboarding

- Multi-step onboarding
- `Start fresh` flow
- `Add past watches fast` flow into `Quick Add`
- Local persistence with `LocalUserState`

### Timeline

- Personal timeline sorted by watched date
- Full entries and quick-add entries coexist
- Entry detail and edit flows
- Soft delete behavior
- Pending sync indicators

### Entry Editor

Entries can include:

- Title
- Type
- Mood
- Takeaway
- Quote / key moment
- Tags
- Intensity
- Watch context
- Cinema-specific ratings
- Visibility
- Circle sharing targets

### Quick Add

- Seeded local suggestions
- Manual title entry
- Quick sentiment
- Approximate watch date
- Duplicate prevention

### QuickPick

- Local recommendation engine
- Requires minimum history
- Avoids immediate repeats in-session
- Uses rewatch signals plus seeded suggestion candidates
- Includes tests for core recommendation behavior

### Circle

Circle is no longer just a placeholder. The current implementation includes:

- Create Circle
- Join Circle by invite code
- Preview Circle before joining
- Leave Circle
- Edit Circle details
- Delete Circle
- Member list
- Circle activity feed
- Shared Circle timeline for entries explicitly shared to that Circle
- Read-only Circle entry detail view

### Settings and Sync

- Sync status summary
- Manual sync for pending entry changes
- Retry flow for failed sync actions
- Manual refresh from cloud
- Local-first status and pending action visibility
- Version and bundle info

## App Flow

1. `CloseCutApp` bootstraps shared state and the `SwiftData` container.
2. `AppDelegate` configures Firebase and Firestore.
3. `RootView` chooses between auth, profile loading, onboarding, and the main shell.
4. `SessionViewModel` ensures a `UserProfile` exists.
5. `SessionSyncViewModel` runs the initial entry refresh from cloud when needed.
6. `MainTabView` exposes `Timeline`, `Circle`, and `Settings`.

## Architecture

### Core Layers

- `App/`
  App lifecycle, bootstrapping, launch flow
- `Core/Models/`
  Domain models such as `Entry`, `CloseCircle`, `CircleMember`, `CircleActivity`, `UserProfile`
- `Core/Local/`
  `SwiftData` models for local persistence
- `Core/Remote/`
  Firestore DTOs and remote data sources
- `Core/Services/`
  Repositories and domain services
- `Core/Sync/`
  Entry sync, pending action handling, conflict policy
- `Core/UI/`
  Shared UI building blocks and theme
- `Core/Utils/`
  Small app helpers and extensions

### Feature Areas

- `Features/Home`
- `Features/QuickAdd`
- `Features/EntryEditor`
- `Features/EntryDetail`
- `Features/Circle`
- `Features/Settings`
- `Features/Onboarding`

### Recommendation Layer

- `Recommendation/`
  Local recommendation logic for `QuickPick`

## Persistence and Sync

### Local

The app persists local state through `SwiftData`, including:

- Entries
- Comments
- Reactions
- Circles
- Circle memberships
- User profile
- Onboarding state
- Pending sync actions

### Remote

Firestore is currently used for:

- User profile storage
- Entry upload and pull
- Circle documents
- Circle membership documents
- Circle activity feed
- Shared Circle entry fetches

### Sync Model

The sync model is local-first:

- Entries can be created, edited, and deleted locally
- Pending work is queued in `PendingAction`
- `EntrySyncService` pushes local changes and pulls remote entries
- Initial cloud refresh is gated per signed-in user session

## Current Status

### Implemented and usable

- Auth
- Onboarding
- Timeline
- Entry creation/edit/delete
- Quick Add
- QuickPick
- Entry sync
- Circle CRUD and joining
- Circle shared timeline pull
- Sync controls in Settings
- Core unit test coverage for several domains

### Still limited or incomplete

- Reactions and comments are modeled, but not fully shipped in the user-facing flow
- Circle shared entries are read-only from the Circle side
- No real-time listeners yet
- No background sync engine
- Recommendation system is rule-based, not catalog-backed
- Quick Add suggestions are seeded locally, not powered by an external media API

## Tests

The repository already includes focused unit tests for:

- `DuplicateDetector`
- `EntryValidation`
- `QuickPickEngine`
- `PendingActionQueue`
- `EntryConflictPolicy`

UI tests exist, but coverage still appears lightweight compared with core feature scope.

## Getting Started

### Requirements

- Recent `Xcode`
- A valid Firebase project
- Firebase Email/Password auth enabled
- Firestore configured
- A valid `GoogleService-Info.plist` attached to the app target

### Setup

1. Open the project in Xcode.
2. Confirm `GoogleService-Info.plist` belongs to the `CloseCut` target.
3. Enable `Email/Password` under Firebase Authentication.
4. Configure Firestore for the project.
5. Build and run on simulator or device.

## Documentation

Additional project docs live in `Documentation/`:

- `Documentation/KNOWN_LIMITATIONS.md`
- `Documentation/QA_CHECKLIST.md`

## Roadmap Direction

Likely next steps for the project:

- Finish user-facing reactions and comments
- Expand Circle sharing and shared activity around entries
- Add real-time listeners for entries and circles
- Improve sync robustness and background behavior
- Replace seeded media suggestions with a real metadata source
- Deepen automated UI coverage

## Repository Snapshot

```text
CloseCut/
├── Documentation
├── CloseCut/App
├── CloseCut/Core
│   ├── Domain
│   ├── Local
│   ├── Models
│   ├── Remote
│   ├── Services
│   ├── Sync
│   ├── UI
│   └── Utils
├── CloseCut/Features
├── CloseCut/Recommendation
└── CloseCut/Tests
```

## Why This Repo Matters

CloseCut already has a clear identity: it treats viewing history as memory, not just media inventory. The codebase now reflects that with a local-first foundation, emotional metadata, recommendation scaffolding, and a working private-circle model that can grow into a richer shared experience.
