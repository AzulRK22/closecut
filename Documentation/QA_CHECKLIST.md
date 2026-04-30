# CloseCut QA Checklist

## 1. Fresh Install / Launch
- [ ] App launches without crash
- [ ] App shows auth screen when signed out
- [ ] App supports dark mode consistently
- [ ] No debug UI appears in Home
- [ ] Loading states look intentional

## 2. Authentication
- [ ] User can sign in
- [ ] User profile is created/loaded
- [ ] User can sign out
- [ ] Sign out returns to auth screen
- [ ] Sign in again restores session correctly

## 3. Onboarding
- [ ] New user sees onboarding
- [ ] Continue navigation works
- [ ] Skip routes to Home
- [ ] Start fresh routes to Home
- [ ] Add past watches fast opens Quick Add
- [ ] Onboarding does not repeat after completion

## 4. Quick Add Past Watches
- [ ] Quick Add opens from Home lightning button
- [ ] Suggested titles appear
- [ ] User can add a suggested title
- [ ] Quick Add card appears in Timeline
- [ ] Quick Add badge appears on card
- [ ] Duplicate title does not create duplicate entry
- [ ] Quick sentiment appears on card when available
- [ ] Rough watched date appears when available

## 5. New Entry
- [ ] New Entry opens from plus button
- [ ] Save is disabled without required fields
- [ ] Title is required
- [ ] Mood is required
- [ ] User can create a movie entry
- [ ] User can create a series entry
- [ ] Home context works
- [ ] Cinema context shows cinema fields
- [ ] Tags are cleaned/lowercased/deduped
- [ ] Max tags validation works
- [ ] Dirty cancel shows discard confirmation
- [ ] Saved entry appears in Timeline

## 6. Timeline
- [ ] Empty state shows Add past watches
- [ ] Empty state shows Log a new watch
- [ ] Low-history module appears with 1–2 entries
- [ ] Low-history progress updates
- [ ] Recently watched appears with entries
- [ ] Quick Add and Full Entry cards coexist
- [ ] Pending Sync badge appears on unsynced entries
- [ ] Synced entries do not show Pending Sync
- [ ] Deleted entries do not appear

## 7. Entry Detail
- [ ] Tapping a card opens Detail
- [ ] Detail shows title, type, mood, date, visibility
- [ ] Takeaway appears when available
- [ ] Empty takeaway copy works for Quick Add
- [ ] Tags appear when available
- [ ] Intensity appears
- [ ] Cinema ratings appear only when relevant
- [ ] Actions menu opens
- [ ] Edit/Add details opens editor
- [ ] Delete confirmation appears

## 8. Quick Add → Full Entry Upgrade
- [ ] Quick Add Detail button says Add details
- [ ] Editor title says Add details
- [ ] Helper copy appears
- [ ] User can add mood/takeaway/tags
- [ ] Save details converts sourceType to fullEntry
- [ ] Quick Add badge disappears after upgrade

## 9. Delete Entry
- [ ] Delete entry removes it from Timeline
- [ ] Delete creates pending sync state
- [ ] Sync now sends deletedAt to Firestore
- [ ] Deleted Firestore entry is not restored into Timeline
- [ ] Deleted entry remains hidden after refresh from cloud

## 10. QuickPick
- [ ] Shows insufficient history with fewer than 3 entries
- [ ] CTA opens Quick Add
- [ ] Secondary CTA opens New Entry
- [ ] Shows suggestion with 3+ entries
- [ ] Suggestion has reason string
- [ ] Show me another changes suggestion when possible
- [ ] Already watched seed is not recommended as Watch Next
- [ ] QuickPick works offline with local data

## 11. Settings
- [ ] Profile card appears
- [ ] Sync status card appears
- [ ] Sync now appears when there are pending changes
- [ ] Retry sync appears when failed actions exist
- [ ] Refresh from cloud appears
- [ ] Privacy section appears
- [ ] Offline-first section appears
- [ ] Pending local entries count is accurate
- [ ] Queued actions count is accurate
- [ ] Completed sync actions count is accurate
- [ ] Clear completed sync history works
- [ ] Version/build appears
- [ ] Sign out works

## 12. Firestore Push Sync
- [ ] New Entry syncs to Firestore
- [ ] Quick Add syncs to Firestore
- [ ] Edit syncs to Firestore
- [ ] Delete syncs deletedAt to Firestore
- [ ] sourceType quickAdd is stored correctly
- [ ] sourceType fullEntry is stored correctly
- [ ] ownerId matches Firebase Auth UID
- [ ] Sync success message appears

## 13. Firestore Pull Sync
- [ ] Refresh from cloud pulls entries
- [ ] Auto refresh pulls entries after login
- [ ] Fresh install + login restores synced entries
- [ ] Remote deleted entries stay hidden
- [ ] Local pending entries are not overwritten by pull
- [ ] Firestore index works for ownerId + updatedAt query

## 14. Offline-first
- [ ] App opens offline
- [ ] New Entry can be created offline
- [ ] Quick Add can be created offline
- [ ] Edit can be saved offline
- [ ] Delete can be performed offline
- [ ] Pending Sync appears offline
- [ ] Settings shows pending local entries
- [ ] Reconnect + Sync now pushes changes
- [ ] No local data loss after force quit

## 15. Conflict Policy
- [ ] Local pending entry is not overwritten by cloud refresh
- [ ] Remote newer synced entry updates local
- [ ] Local newer synced entry is kept
- [ ] Remote deleted entry applies when local is synced
- [ ] Failed local entry is not overwritten by pull

## 16. Tests
- [ ] Unit tests pass
- [ ] DuplicateDetector tests pass
- [ ] EntryValidation tests pass
- [ ] QuickPickEngine tests pass
- [ ] PendingActionQueue tests pass
- [ ] EntryConflictPolicy tests pass
- [ ] UI smoke test passes or UI tests are intentionally minimal

## 17. Release Readiness
- [ ] Bundle ID is correct
- [ ] Version is correct
- [ ] Build number is incremented
- [ ] Signing team is correct
- [ ] GoogleService-Info.plist target membership is correct
- [ ] Firestore rules are published
- [ ] App archives successfully
- [ ] No obvious console spam in normal happy path
