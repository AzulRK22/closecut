# CloseCut Known Limitations

## Current Scope

- CloseCut is local-first and syncs entries manually or during initial session refresh.
- Firebase Auth and Firestore are required for the network-backed parts of the app.
- Personal entries remain private by default.
- Circle sharing is explicit and opt-in per entry.
- `QuickPick` is local and rule-based.

## What Is Working Today

- Entry push sync to Firestore
- Entry pull sync from Firestore
- Pending action tracking for entry sync
- Circle creation, join, leave, edit, delete
- Invite code preview and join flow
- Circle members and activity retrieval
- Circle shared timeline pull and read-only viewing

## Current Product and Technical Gaps

- Reactions and comments are modeled but not fully delivered as an end-to-end feature
- Circle timeline entries are read-only from the Circle experience
- There are no real-time Firestore listeners for entries or circles
- There is no background sync engine
- Sync controls are manual and user-visible in Settings
- `QuickPick` uses seeded candidates and local heuristics, not a live catalog
- `Quick Add` does not use a movie metadata API
- Poster artwork and rich title metadata are not integrated
- Profile photo upload is not implemented
- Push notifications are not implemented

## Circle-Specific Limitations

- Circle membership is available, but the broader social layer is still intentionally narrow
- Shared Circle entries depend on explicit sharing and remote fetches, not live collaboration
- Group QuickPick inside Circle detail is still a placeholder
- Reactions/comments inside Circle are still marked as future-facing in the UI

## Sync Expectations

- Unsynced local entry changes may show pending sync state
- Failed sync actions may require manual retry from Settings
- Refresh from cloud pulls remote entries for the signed-in user
- Refresh logic is defensive and should avoid overwriting local pending or failed entry changes
- Soft-deleted entries should remain hidden from the personal timeline after pull

## Operational Assumptions

- Firestore rules and indexes must be configured correctly for the app to behave as expected
- Invite code uniqueness depends on Firestore availability during Circle creation
- Initial cloud refresh is session-scoped, not a full real-time sync strategy
