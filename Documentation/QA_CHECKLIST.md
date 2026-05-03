# CloseCut QA Checklist

## 1. Fresh Install / Launch

- [ ] App launches without crashing
- [ ] Signed-out user lands on auth
- [ ] Loading states render cleanly
- [ ] Home, Circle, and Settings match the dark visual system
- [ ] No debug-only UI leaks into the happy path

## 2. Authentication

- [ ] User can create an account
- [ ] User can sign in
- [ ] User profile is created or restored
- [ ] User can sign out
- [ ] Signing out resets session state cleanly
- [ ] Signing back in restores the expected user state

## 3. Onboarding

- [ ] New user sees onboarding
- [ ] Continue navigation works
- [ ] Skip completes onboarding
- [ ] Start fresh routes to main app
- [ ] Add past watches fast opens Quick Add
- [ ] Onboarding does not repeat after completion

## 4. Quick Add

- [ ] Quick Add opens from Home
- [ ] Seeded suggestions appear
- [ ] Manual title entry works
- [ ] User can add a suggested title
- [ ] Duplicate prevention works
- [ ] Quick sentiment is stored when selected
- [ ] Approximate watched date is stored when selected
- [ ] Quick Add result appears in Timeline

## 5. Entry Creation and Editing

- [ ] New Entry opens from the plus button
- [ ] Save stays disabled without required fields
- [ ] Title validation works
- [ ] Mood validation works
- [ ] User can create movie and series entries
- [ ] Home context works
- [ ] Cinema context reveals cinema-specific fields
- [ ] Tags are cleaned, deduped, and lowercased
- [ ] Dirty-dismiss confirmation appears
- [ ] Saved entry appears in Timeline
- [ ] Existing entry can be edited
- [ ] Visibility and Circle sharing selections persist correctly

## 6. Timeline

- [ ] Empty state appears correctly with no entries
- [ ] Timeline renders mixed quick-add and full entries
- [ ] Pending sync badge appears on pending entries
- [ ] Synced entries do not show pending state
- [ ] Deleted entries disappear from the main timeline
- [ ] Entry cards open detail

## 7. Entry Detail

- [ ] Detail shows title, type, mood, date, and visibility
- [ ] Takeaway appears when available
- [ ] Quick Add empty-state copy appears when expected
- [ ] Tags render when available
- [ ] Intensity renders
- [ ] Cinema ratings appear only when relevant
- [ ] Actions menu opens
- [ ] Edit / Add details opens the editor
- [ ] Delete confirmation appears

## 8. Quick Add to Full Entry Upgrade

- [ ] Quick Add detail offers Add details
- [ ] Editor title reflects upgrade flow
- [ ] User can add emotional details
- [ ] Saving upgrades the source type to full entry
- [ ] Quick Add badge disappears after upgrade

## 9. Delete Entry

- [ ] Deleting removes the entry from Timeline
- [ ] Delete produces pending sync state
- [ ] Sync sends deleted state to Firestore
- [ ] Deleted remote entry is not restored into Timeline

## 10. QuickPick

- [ ] Fewer than 3 entries shows insufficient history state
- [ ] CTA to Quick Add works
- [ ] CTA to New Entry works
- [ ] 3 or more entries generate a suggestion
- [ ] Suggestion includes a reason string
- [ ] Refresh avoids immediate repeats when alternatives exist
- [ ] Already watched seeded candidates are not suggested as new watch-next items
- [ ] QuickPick works offline from local history

## 11. Circle Creation and Join

- [ ] User can open Circle action sheet
- [ ] User can create a Circle
- [ ] Circle appears in the Circle list after creation
- [ ] Invite code is shown in Circle detail
- [ ] Invite code can be copied
- [ ] User can preview a Circle by invite code
- [ ] User can join a Circle by invite code
- [ ] Joined Circle appears in local list after refresh

## 12. Circle Detail

- [ ] Circle detail opens from Circle list
- [ ] Segments switch correctly between Timeline, QuickPick, Members, and Activity
- [ ] Members load when available
- [ ] Activity feed loads when available
- [ ] Shared timeline loads when shared entries exist
- [ ] Shared entries open read-only detail
- [ ] Group QuickPick placeholder appears in Circle detail

## 13. Circle Management

- [ ] Owner can edit Circle details
- [ ] Owner can delete Circle
- [ ] Non-owner can leave Circle
- [ ] Owner cannot use leave flow incorrectly
- [ ] Deleting a Circle removes it from active local membership lists

## 14. Sharing Entries to Circles

- [ ] Entry editor shows Circle share picker when relevant
- [ ] User can select one or more Circles
- [ ] Shared entry remains in personal timeline
- [ ] Shared entry appears in Circle shared timeline after sync/pull
- [ ] Non-shared entry does not appear in Circle timeline

## 15. Settings and Sync Controls

- [ ] Profile header appears
- [ ] Sync status summary appears
- [ ] Sync now appears when pending work exists
- [ ] Retry sync appears when failed actions exist
- [ ] Refresh from cloud works
- [ ] Privacy section appears
- [ ] Offline-first section appears
- [ ] Pending local entries count is accurate
- [ ] Queued actions count is accurate
- [ ] Completed sync actions count is accurate
- [ ] Clear completed sync history works
- [ ] Version/build info appears
- [ ] Sign out works

## 16. Firestore Push Sync

- [ ] New entry syncs to Firestore
- [ ] Quick Add syncs to Firestore
- [ ] Edit syncs to Firestore
- [ ] Delete syncs deleted state to Firestore
- [ ] Entry ownerId matches Firebase Auth UID
- [ ] Entry source type is stored correctly
- [ ] Shared Circle IDs persist correctly when present
- [ ] Success or warning feedback appears in Settings after sync

## 17. Firestore Pull Sync

- [ ] Initial session refresh pulls entries when appropriate
- [ ] Manual refresh from Settings pulls entries
- [ ] Fresh install plus sign-in restores synced entries
- [ ] Remote deleted entries stay hidden
- [ ] Local pending entries are not overwritten by pull
- [ ] Local failed entries are not overwritten by pull

## 18. Offline-First Behavior

- [ ] App opens offline
- [ ] User can create entries offline
- [ ] User can use Quick Add offline
- [ ] User can edit offline
- [ ] User can delete offline
- [ ] Pending sync state is visible offline
- [ ] No local data loss after relaunch
- [ ] Reconnect plus Sync now pushes pending changes

## 19. Conflict and Queue Behavior

- [ ] Pending action queue tracks syncable work
- [ ] Completed actions can be cleaned up
- [ ] Failed actions remain retryable
- [ ] Pull respects local conflict policy assumptions

## 20. Automated Test Baseline

- [ ] `DuplicateDetectorTests` pass
- [ ] `EntryValidationTests` pass
- [ ] `QuickPickEngineTests` pass
- [ ] `PendingActionQueueTests` pass
- [ ] `EntryConflictPolicyTests` pass
- [ ] UI tests are intentionally minimal or passing

## 21. Release Readiness

- [ ] Bundle ID is correct
- [ ] Version is correct
- [ ] Build number is correct
- [ ] Signing team is correct
- [ ] `GoogleService-Info.plist` target membership is correct
- [ ] Required Firestore rules and indexes are deployed
- [ ] Archive succeeds
- [ ] Normal happy path does not produce obvious console noise
