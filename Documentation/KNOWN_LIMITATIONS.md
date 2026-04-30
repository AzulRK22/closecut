# CloseCut MVP Known Limitations

## Current MVP scope
- CloseCut is currently local-first with Firebase Auth and Firestore entry sync.
- Circle is currently a polished placeholder.
- Entries are private by default.
- QuickPick is local and rule-based, not ML-based.
- Manual sync controls remain available in Settings for transparency during MVP testing.

## Not included yet
- Real Circle membership
- Real invite code joining
- Shared Circle feed
- Reactions/comments sync
- Push notifications
- Profile photo upload
- Movie metadata API
- Poster images
- Cross-device real-time listeners
- Full background sync
- App Store production privacy copy

## Expected behavior
- Unsynced local changes may show Pending Sync.
- Refresh from cloud pulls Firestore entries owned by the signed-in user.
- Local pending/failed changes are not overwritten by cloud refresh.
- Deleted entries are soft deleted and hidden from Timeline.
