# CloseCut Known Limitations

## Current Scope

CloseCut is a local-first SwiftUI app for private movie and series journaling, personal watch history, rule-based recommendations, and trusted sharing through Circles.

The app currently supports:

- Firebase Auth for signed-in user identity
- SwiftData local-first persistence
- Firestore-backed entry sync
- Manual and initial-session cloud refresh
- Personal Timeline
- Quick Add Past Watches
- TMDB-backed metadata search
- Personal QuickPick
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
- TMDB metadata selection for poster, overview, rating, release year, genres, and media type
- Circle sharing selection from the Entry Editor

### Timeline and Home

- Personal Timeline
- Timeline sections:
  - Recently watched
  - Stayed with you
  - Rewatch candidates
  - High-rated memories
  - All history
- Archive summary card
- Metadata enrichment signals
- Quick Add activation prompts
- Low-history QuickPick progress module

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

- Personal random pick battle
- Movie vs Movie head-to-head battle
- Local Battle result persistence
- Recent Battle result history
- Local result cleanup

### Settings and Sync

- Profile header
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
- QuickPick engine behavior
- Pending action queue behavior
- Entry conflict policy
- Basic UI launch test

## Current Product and Technical Gaps

### Sync and Realtime

- There are no real-time Firestore listeners for entries, circles, reactions, or comments.
- Sync is still mostly manual or session-triggered.
- There is no background sync engine.
- There is no automatic retry scheduler for failed sync actions.
- Circle social data is fetched on view load or refresh, not streamed live.
- Multi-device collaboration is supported through fetch/sync, not real-time updates.

### Circle

- Group QuickPick inside Circle detail is still a placeholder.
- Friend Battle and Circle Battle are not implemented yet.
- Circle shared timeline depends on explicit entry sharing and remote fetches.
- Circle membership management is intentionally narrow.
- There is no member removal/admin moderation UI beyond owner edit/delete and non-owner leave.
- There are no push notifications for Circle activity, comments, or reactions.

### QuickPick and Recommendation

- QuickPick is rule-based, not ML-based.
- QuickPick can use TMDB discovery, but it is not a full recommendation catalog.
- There is no watch provider availability integration.
- There is no personalization model beyond local heuristics and available metadata.
- QuickPick does not yet support group-level Circle recommendations.

### Metadata and Media

- TMDB metadata search is implemented, but metadata quality depends on TMDB availability.
- Poster/backdrop artwork depends on valid TMDB paths.
- Manual entries can still exist without rich metadata.
- There is no automatic metadata backfill for older manual entries unless the user edits them.

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
- Social Battle modes are future-facing.
- Battle results are local and not synced to Circle spaces.

## Circle-Specific Limitations

- Circle is designed as a trusted sharing layer, not a public social network.
- Circle entries are read-only from the Circle experience.
- Original entry editing and deletion remain controlled from the owner’s Personal Timeline.
- Reactions and comments require valid Firestore rules, membership access, and indexes.
- If an entry is no longer shared with a Circle, Circle social interaction becomes unavailable for that Circle context.
- Circle QuickPick is not implemented yet.
- Circle Battle and Friend Battle are not implemented yet.

## Sync Expectations

- Unsynced local entry changes may show pending sync state.
- Failed sync actions may require manual retry from Settings.
- Refresh from cloud pulls remote entries for the signed-in user.
- Refresh logic should avoid overwriting local pending or failed entry changes.
- Soft-deleted entries should remain hidden from the personal timeline after pull.
- Circle shared entries may require sync/pull before appearing in Circle timelines.
- Reactions and comments depend on Firestore permission and index configuration.

## Firestore Requirements

The app expects Firestore to support:

- User documents
- Entry documents
- Circle documents
- Circle member subcollections
- Circle activity subcollections
- Entry reactions subcollections
- Entry comments subcollections
- Collection group membership queries
- Required composite indexes for social queries when filtering by Circle and ordering by creation date

If Firestore rules or indexes are missing, Circle social features may fail with permission or index errors.

## Operational Assumptions

- Firebase Auth must be configured.
- Firestore must be configured.
- Firestore rules must match the current app data model.
- Firestore indexes must be deployed for required queries.
- TMDB read access must be configured for metadata search and discovery.
- `GoogleService-Info.plist` must be included in the app target.
- Local SwiftData schema must include all active local models.
- Initial cloud refresh is session-scoped, not a full real-time sync strategy.

## Next Technical Priorities

Recommended next polish areas:

1. Extract larger stateful views into ViewModels:
   - `CircleViewModel`
   - `CircleDetailViewModel`
   - `SettingsViewModel`

2. Move truly shared UI components to `Core/UI/Components`:
   - Entry poster thumbnail
   - Detail section card
   - Detail info row
   - Shared status chips where appropriate

3. Add more automated tests:
   - `TimelineSectionBuilder`
   - `QuickPickReasonBuilder`
   - `RewatchRule`
   - `EntryEditorViewModel`
   - Circle access validation helpers
   - Settings sync summary logic

4. Add real-time or background sync strategy only after the local-first MVP remains stable.
