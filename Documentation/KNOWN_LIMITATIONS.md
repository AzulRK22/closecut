# CloseCut Known Limitations

## Current Scope

CloseCut is a local-first SwiftUI app for private movie and series journaling, personal taste history, TMDB-backed discovery, rule-based recommendations, trusted Circle sharing, and local watch-decision games.

The app currently supports:

- Firebase Auth for signed-in user identity
- SwiftData local-first persistence
- Firestore-backed entry sync
- Firestore-backed watchlist sync
- Manual and initial-session cloud refresh
- Personal library and timeline
- Quick Add Past Watches
- TMDB-backed media search, metadata, posters, discovery, and enrichment
- Personal QuickPick
- Want to Watch watchlist
- Multi-Circle sharing
- Circle shared timelines
- Circle reactions and comments
- Local Battle modes

Personal entries remain private by default. Circle sharing is explicit and opt-in per entry.

## What Is Working Today

### Authentication and Session

- Firebase Auth sign-up and sign-in
- User profile creation and loading
- Session gate after authentication
- Onboarding completion tracking
- Initial cloud refresh scoped to the signed-in session

### Entries

- Full entry creation
- Quick Add Past Watches
- Entry editing and Quick Add upgrade flow
- Soft delete
- Local pending sync state
- Entry push sync to Firestore
- Entry pull sync from Firestore
- Conflict-aware pull behavior for pending and failed local changes
- TMDB metadata selection for poster, backdrop, overview, rating, release year, genres, and media type
- Circle sharing selection from the Entry Editor

### Personal Library and Home

- Personal library and timeline
- Timeline sections:
  - Recently watched
  - Stayed with you
  - Rewatch candidates
  - High-rated memories
  - All history
- Library search and browse filters
- Archive summary card
- Metadata enrichment signals
- Quick Add activation prompts
- Low-history QuickPick progress module
- Manual refresh that combines cloud pull and metadata enrichment

### Quick Add

- TMDB result capture
- Seeded/local fallback suggestions
- Manual title capture
- Duplicate prevention
- Quick sentiment
- Approximate watched date
- Upgrade path from Quick Add to full entry

### Discover and TMDB

- Trending this week
- Popular movies
- Popular series
- Personalized discovery from local genre affinity
- Media detail preview
- Save discovered titles to Want to Watch
- TMDB metadata search from Quick Add and Entry Editor

### Want to Watch

- Local watchlist persistence
- Save items from TMDB discovery
- Saved/watched/dismissed status handling
- Mark watched
- Add watchlist item to personal history as a Quick Add entry
- Soft-delete/dismiss items
- Push/pull watchlist sync through Firestore

### QuickPick

- Local, rule-based personal recommendations
- Insufficient-history state
- No-repeat session policy
- Rewatch candidate detection
- Seeded fallback candidates
- TMDB discovery when metadata configuration is available
- Reason strings and confidence labels
- Signals based on mood, tags, genre affinity, intensity, sentiment, rating, and rewatch logic

### Circle

- Circle creation
- Circle join by invite code
- Circle preview before joining
- Circle leave flow
- Circle edit flow
- Circle soft-delete flow
- Circle members retrieval
- Circle activity retrieval
- Multiple Circles per user
- Circle list / hub
- Shared timeline per Circle
- Read-only Circle entry detail
- Circle reactions
- Circle comments
- Firestore rules/index assumptions for Circle social access

### Battle

- Pick for Tonight
- Movie vs Movie head-to-head battle
- Friend Battle sheet
- Circle Battle sheet
- Archive, TMDB, and manual candidate sources
- Local Battle result persistence
- Recent Battle result history
- Local result cleanup

### Settings and Sync

- Profile header
- Limited profile editing
- Sync status summary
- Manual Sync Now
- Retry sync for failed work
- Refresh from cloud
- Pending local entries count
- Queued action count
- Completed sync history count
- Clear completed sync history
- Privacy and local-first explanation
- App version/build information
- Sign out

### Tests

Current automated test coverage includes:

- Duplicate detection
- Entry validation
- Entry search filtering
- Library search pipeline behavior
- QuickPick engine behavior
- Pending action queue behavior
- Entry conflict policy
- Basic UI launch test

## Current Product and Technical Gaps

### Sync and Realtime

- There are no real-time Firestore listeners for entries, watchlist items, circles, reactions, or comments.
- Sync is still mostly manual or session-triggered.
- There is no background sync engine.
- There is no automatic retry scheduler for failed sync actions.
- Circle social data is fetched on view load or refresh, not streamed live.
- Watchlist data is pushed/pulled on refresh, not streamed live.
- Multi-device collaboration is supported through fetch/sync, not real-time updates.

### Circle

- Group QuickPick inside Circle detail is still a placeholder.
- Circle shared timeline depends on explicit entry sharing and remote fetches.
- Circle membership management is intentionally narrow.
- There is no member removal/admin moderation UI beyond owner edit/delete and non-owner leave.
- There are no push notifications for Circle activity, comments, or reactions.
- Battle results are not posted back into Circle spaces.

### QuickPick and Recommendation

- QuickPick is rule-based, not ML-based.
- QuickPick can use TMDB discovery, but it is not a full recommendation catalog.
- There is no watch provider availability integration.
- There is no personalization model beyond local heuristics and available metadata.
- QuickPick does not yet support group-level Circle recommendations.

### Discover, Metadata, and Media

- TMDB features require a valid `TMDB_READ_ACCESS_TOKEN`.
- TMDB metadata quality depends on TMDB availability.
- Poster/backdrop artwork depends on valid TMDB paths.
- Manual entries can still exist without rich metadata.
- Metadata enrichment covers missing metadata during supported refresh flows, but it is not a real-time or background backfill system.
- Discover is not a streaming catalog, watch provider finder, or availability tracker.

### Want to Watch

- Watchlist sync is manual/refresh-driven.
- Watchlist items are private personal data, not shared with Circles.
- Watchlist conversion creates a Quick Add history entry, not a full emotional entry.
- Dismissed/deleted watchlist items are soft-deleted locally/remotely rather than hard removed immediately.

### Account and Profile

- Profile photo upload is not implemented.
- Profile editing is limited.
- Account deletion is not implemented.
- Password reset and email verification flows are not currently surfaced in the app UI.

### Notifications and Background Behavior

- Push notifications are not implemented.
- Background sync is not implemented.
- Offline work remains local until the user syncs or refreshes during a supported session flow.

### Battle

- Battle is currently local/personal.
- Friend Battle and Circle Battle are local decision flows, not remote multiplayer experiences.
- Battle results are local and not synced to Circle spaces.

## Circle-Specific Limitations

- Circle is designed as a trusted sharing layer, not a public social network.
- Circle entries are read-only from the Circle experience.
- Original entry editing and deletion remain controlled from the owner's Personal library.
- Reactions and comments require valid Firestore rules, membership access, and indexes.
- If an entry is no longer shared with a Circle, Circle social interaction becomes unavailable for that Circle context.
- Circle QuickPick is not implemented yet.
- Circle Battle does not persist shared group results yet.

## Sync Expectations

- Unsynced local entry and watchlist changes may show pending sync state.
- Failed sync actions may require manual retry from Settings or the relevant feature refresh.
- Refresh from cloud pulls remote entries for the signed-in user.
- Watchlist refresh pushes local watchlist changes and pulls remote watchlist items.
- Refresh logic should avoid overwriting local pending or failed entry changes.
- Soft-deleted entries should remain hidden from the personal timeline after pull.
- Soft-deleted watchlist items should remain hidden from active watchlist views.
- Circle shared entries may require sync/pull before appearing in Circle timelines.
- Reactions and comments depend on Firestore permission and index configuration.

## Firestore Requirements

The app expects Firestore to support:

- User documents
- Entry documents
- Watchlist item documents
- Circle documents
- Circle member subcollections
- Circle activity subcollections
- Entry reactions subcollections
- Entry comments subcollections
- Collection group membership queries
- Required composite indexes for social queries when filtering by Circle and ordering by creation date

If Firestore rules or indexes are missing, Circle social features and some shared-entry queries may fail with permission or index errors.

## Operational Assumptions

- Firebase Auth must be configured.
- Firestore must be configured.
- Firestore rules must match the current app data model.
- Firestore indexes must be deployed for required queries.
- TMDB read access must be configured for metadata search and discovery.
- `GoogleService-Info.plist` must be included in the app target.
- `Secrets.xcconfig` should provide `TMDB_READ_ACCESS_TOKEN` for builds that use TMDB.
- Local SwiftData schema must include all active local models.
- Initial cloud refresh is session-scoped, not a full real-time sync strategy.

## Next Technical Priorities

Recommended next polish areas:

1. Extract larger stateful views into ViewModels:
   - `CircleViewModel`
   - `CircleDetailViewModel`
   - `SettingsViewModel`
   - `WatchlistViewModel`

2. Add more automated tests:
   - `TimelineSectionBuilder`
   - `QuickPickReasonBuilder`
   - `RewatchRule`
   - `EntryEditorViewModel`
   - Watchlist repository/sync behavior
   - Circle access validation helpers
   - Settings sync summary logic

3. Expand integration-style QA coverage:
   - Discover to Watchlist
   - Watchlist to Quick Add history
   - Entry sharing to Circle social detail
   - Battle candidate selection across archive, TMDB, and manual sources

4. Add real-time or background sync strategy only after the local-first MVP remains stable.
