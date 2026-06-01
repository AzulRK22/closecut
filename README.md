# CloseCut

CloseCut is a local-first iOS app for keeping a private, emotional watch journal for movies and series. It treats viewing history as memory: mood, context, takeaway, quote, rewatch signal, and selective sharing matter as much as title metadata.

The current product shape is: **a private taste library with TMDB discovery, QuickPick recommendations, Want to Watch, trusted Circles, and local watch-decision games.**

## What CloseCut Does

CloseCut currently supports:

- Email/password authentication with Firebase Auth
- Session/profile preparation and onboarding persistence
- A personal library and timeline for watched movies and series
- Full entry creation, editing, soft delete, and Quick Add upgrade flows
- TMDB-backed media search, posters, metadata selection, discovery, and enrichment
- `Quick Add` for fast past-watch capture
- Rule-based `QuickPick` recommendations from local history and optional TMDB discovery
- Private `Want to Watch` watchlist with local-first sync
- Private `Circle` spaces with invite codes, shared timelines, members, activity, comments, and reactions
- Local `Battle` modes for choosing what to watch
- Manual/session-triggered Firestore sync for entries and watchlist items
- Focused unit tests plus a basic UI launch test

## Product Principles

- Personal entries are private by default.
- Sharing is explicit, opt-in, and Circle-based.
- The app remains useful offline and syncs later.
- Recommendations should explain themselves through visible signals.
- The archive should help the user decide, not just store history.

## Tech Stack

- `SwiftUI`
- `SwiftData`
- `Firebase Auth`
- `Firebase Firestore`
- Firebase packages included in the Xcode project: `FirebaseAnalytics`, `FirebaseAuth`, `FirebaseCrashlytics`, `FirebaseFirestore`, `FirebaseFunctions`, `FirebaseStorage`
- TMDB API for metadata, search, trending/popular rails, and discovery
- `XCTest` / `XCUITest`

## Main App Flow

1. `CloseCutApp` creates the shared app services and the SwiftData model container.
2. `AppDelegate` configures Firebase and Firestore.
3. `RootView` routes between auth, profile loading, onboarding, and the signed-in app shell.
4. `SessionViewModel` prepares or restores the signed-in user's profile.
5. `LaunchViewModel` resolves onboarding completion.
6. `SessionSyncViewModel` runs the initial cloud refresh once per signed-in session.
7. `MainTabView` exposes `Personal`, `Discover`, `Circle`, `Battle`, and `Settings`.

## Feature Set

### Authentication and Onboarding

- Email/password sign up and sign in
- Firebase-driven auth state handling
- User profile creation/loading after sign in
- Multi-step onboarding
- `Start fresh` and `Add past watches fast` onboarding exits
- Local onboarding state in `LocalUserState`

### Personal Library

- Timeline sections for recently watched, memorable entries, rewatch candidates, high-rated memories, and all history
- Search and browse filters for type, shared state, Quick Add status, and entries that need more detail
- Sorting by timeline relevance, title, and release year
- Poster/backdrop display from TMDB metadata with local fallbacks
- Refresh flow that combines cloud pull and missing-metadata enrichment

### Entry Editor and Detail

Entries can include:

- Title, type, watched date, mood, and visibility
- Takeaway, key moment/quote, tags, and intensity
- Home/cinema watch context
- Cinema-specific audio, screen, and comfort ratings
- TMDB external metadata: poster, backdrop, overview, rating, release year, genres, and media type
- Circle sharing targets
- Pending/failed sync state

### Quick Add

- Fast capture of past watches
- TMDB search entry point
- Seeded/local fallback suggestions
- Manual title entry
- Quick sentiment and approximate watched date
- Duplicate prevention
- Upgrade path from Quick Add entry to full entry

### Discover and TMDB

- Trending this week
- Popular movies
- Popular series
- `Because of your taste` discovery from local genre affinity
- Media detail sheet with poster and metadata
- Save discovered titles to `Want to Watch`
- Requires `TMDB_READ_ACCESS_TOKEN` to load remote TMDB content

### Want to Watch

- Private watchlist stored locally in `LocalWatchlistItem`
- Save titles from Discover/TMDB
- Filter by saved, watched, and dismissed states
- Mark items watched
- Convert watchlist items into Quick Add history entries
- Soft-delete/dismiss items
- Push/pull Firestore sync through `WatchlistSyncService`

### QuickPick

- Local recommendation engine in `Recommendation/`
- Requires at least three history entries
- Avoids immediate repeats in a session
- Can recommend rewatch candidates or seeded watch-next candidates
- Can use TMDB discovery when metadata and token configuration are available
- Produces reason strings, confidence labels, and signal pills from mood, tags, genres, sentiment, intensity, ratings, and rewatch logic

### Circle

- Create Circle
- Join Circle by invite code
- Preview Circle before joining
- Leave Circle
- Owner edit/delete flows
- Multiple Circles per user
- Circle list/hub
- Member and activity feeds
- Shared timeline per Circle
- Read-only detail view for shared entries
- Selective sharing from the Entry Editor
- Circle reactions and comments backed by Firestore subcollections
- Group QuickPick placeholder in Circle detail

### Battle

- `Pick for Tonight` from archive entries, TMDB results, or manual ideas
- Movie-vs-movie head-to-head decisions
- Friend Battle and Circle Battle sheets
- Shortlist editing and random pick flow
- No-repeat behavior where possible
- Local battle result persistence in `LocalBattleResult`
- Recent result history and local cleanup
- Battle results are local and are not synced to Circle spaces yet

### Settings and Sync

- Profile header and limited profile editing
- Sync status summary
- Manual `Sync Now`
- Retry failed pending work
- Refresh from cloud
- Pending local entry count and queued action count
- Completed sync history count and cleanup
- Local-first privacy explanation
- App version/build information
- Sign out

## Architecture

### App

- `CloseCut/App`
  App lifecycle, Firebase bootstrap, root routing, launch gate, and SwiftData model registration.

### Core

- `CloseCut/Core/Config`
  App constants and environment values.
- `CloseCut/Core/Domain`
  Domain models for auth, entries, watchlist, circles, social data, sync payloads, profile, and battle results.
- `CloseCut/Core/Local`
  SwiftData persistence models.
- `CloseCut/Core/Remote`
  Firestore paths, DTOs, and remote data sources.
- `CloseCut/Core/Repositories`
  Local-first read/write APIs for entries, circles, watchlist, profile, user state, and battle results.
- `CloseCut/Core/Services`
  Auth, session, Circle, invite-code, and metadata enrichment services.
- `CloseCut/Core/Sync`
  Pending action queue, conflict policy, entry sync, watchlist sync, and session sync.
- `CloseCut/Core/External/TMDB`
  TMDB client, endpoints, models, repository, image URL builder, and genre mapper.
- `CloseCut/Core/UI`
  Shared theme, typography, colors, layout constants, and reusable components.
- `CloseCut/Core/Utils`
  Small extensions and build helpers.

### Features

- `Features/Home`
  Personal library, timeline, search/browse pipeline, and QuickPick entry points.
- `Features/QuickAdd`
  Fast past-watch capture and preview/add components.
- `Features/Entries`
  Entry editor, detail screens, metadata, sharing, context, and validation UI.
- `Features/Discover`
  TMDB rails, media detail sheet, and watchlist handoff.
- `Features/Watchlist`
  Want to Watch UI, filters, cards, and actions.
- `Features/Circle`
  Circle hub, detail, presets, invite/join/create/edit sheets, social views, and Circle QuickPick placeholder.
- `Features/Battle`
  Battle modes, sheets, helpers, candidate mapping, no-repeat policy, and result UI.
- `Features/Settings`
  Profile, sync, archive health, system status, and app/support settings.
- `Features/Onboarding`
  Onboarding and auth presentation.

### Recommendation

- `CloseCut/Recommendation`
  Rule-based QuickPick engine, suggestion candidates, rewatch rules, no-repeat policy, and reason builder.

## Persistence and Sync

### Local SwiftData Models

The active SwiftData schema includes:

- `LocalEntry`
- `LocalCircle`
- `LocalCircleMembership`
- `LocalUserProfile`
- `LocalUserState`
- `PendingAction`
- `LocalBattleResult`
- `LocalWatchlistItem`

### Firestore Collections

The app expects Firestore support for:

- `users`
- `entries`
- `watchlistItems`
- `circles`
- Circle subcollections: `members`, `activity`
- Entry social subcollections: `reactions`, `comments`
- Collection group queries over Circle memberships

### Sync Model

The sync model is local-first:

- Entries and watchlist items can be created, edited, and deleted locally.
- Local work is queued in `PendingAction`.
- Entry sync pushes pending work and pulls remote entries.
- Watchlist sync pushes pending watchlist work and pulls remote watchlist items.
- Conflict policy protects pending or failed local changes from being overwritten by remote pulls.
- Initial cloud refresh is scoped to the signed-in user session.

## Current Limitations

- No real-time Firestore listeners yet.
- No background sync engine.
- No automatic retry scheduler for failed sync actions.
- Circle social data is loaded/refreshed, not streamed live.
- Group QuickPick inside Circle detail is still a placeholder.
- Circle entries are read-only from the Circle side; original editing stays in Personal.
- Battle results are local and not synced to Circle spaces.
- Recommendations are rule-based, not ML-based.
- TMDB discovery is not a full availability or provider catalog.
- Profile photo upload, account deletion, password reset, and email verification flows are not surfaced in the app UI.
- Push notifications are not implemented.

## Getting Started

### Requirements

- Recent Xcode
- iOS simulator or device
- A Firebase project
- Firebase Email/Password auth enabled
- Firestore configured with rules and indexes that match the current data model
- A valid `GoogleService-Info.plist` attached to the `CloseCut` target
- A TMDB API read access token for search/discovery features

### Setup

1. Open `CloseCut.xcodeproj` in Xcode.
2. Add `GoogleService-Info.plist` to the `CloseCut` app target.
3. Enable Email/Password in Firebase Authentication.
4. Configure Firestore collections, rules, and any required composite indexes for Circle social queries.
5. Copy `Secrets.example.xcconfig` to `Secrets.xcconfig`.
6. Set `TMDB_READ_ACCESS_TOKEN` in `Secrets.xcconfig`.
7. Confirm `CloseCut.xcconfig` is included in the active build configuration.
8. Build and run the `CloseCut` scheme.

`Secrets.xcconfig` is intentionally local-only and should not be committed.

## Tests

The repository includes tests for:

- `DuplicateDetector`
- `EntryValidation`
- `EntrySearchFilter`
- `LibrarySearchPipeline`
- `QuickPickEngine`
- `PendingActionQueue`
- `EntryConflictPolicy`
- Basic app launch through `CloseCutUITests`

Run the `CloseCut` test target from Xcode, or use `xcodebuild test` with an available iOS simulator.

## Documentation

Additional project docs live in `Documentation/`:

- `Documentation/KNOWN_LIMITATIONS.md`
- `Documentation/QA_CHECKLIST.md`

## Repository Snapshot

```text
CloseCut/
├── CloseCut.xcodeproj
├── CloseCut.xcconfig
├── Secrets.example.xcconfig
├── Documentation
│   ├── KNOWN_LIMITATIONS.md
│   └── QA_CHECKLIST.md
└── CloseCut
    ├── App
    ├── Assets.xcassets
    ├── Core
    │   ├── Config
    │   ├── Domain
    │   ├── External
    │   ├── Local
    │   ├── Remote
    │   ├── Repositories
    │   ├── Services
    │   ├── Sync
    │   ├── UI
    │   └── Utils
    ├── Features
    │   ├── AppShell
    │   ├── Battle
    │   ├── Circle
    │   ├── Discover
    │   ├── Entries
    │   ├── Home
    │   ├── Onboarding
    │   ├── QuickAdd
    │   ├── Search
    │   ├── Settings
    │   └── Watchlist
    ├── Recommendation
    └── Tests
```

## Roadmap Direction

Useful next steps:

- Add real-time listeners for entries, circles, comments, and reactions.
- Add background sync and scheduled retry behavior.
- Finish group QuickPick for Circles.
- Decide whether Battle should become shareable/synced.
- Add password reset, email verification, account deletion, and richer profile editing.
- Add push notifications for Circle activity.
- Expand automated UI coverage around onboarding, Quick Add, Entry Editor, Circle, Discover, and Battle.
