# CloseCut QA Checklist

## 1. Fresh Install / Launch

- [ ] App launches without crashing
- [ ] Signed-out user lands on Auth
- [ ] Loading auth state renders cleanly
- [ ] Loading profile state renders cleanly
- [ ] Root session gate routes correctly
- [ ] Home, Circle, Battle, and Settings match the dark visual system
- [ ] No debug-only UI leaks into the happy path
- [ ] Console does not show critical app startup errors

## 2. Authentication

- [ ] User can create an account
- [ ] User can sign in
- [ ] User profile is created or restored
- [ ] User can sign out
- [ ] Signing out resets session state cleanly
- [ ] Signing back in restores the expected user state
- [ ] Auth error messages render clearly
- [ ] Invalid email/password state prevents submission when expected

## 3. Session and Launch Gate

- [ ] Signed-in user enters session preparation flow
- [ ] Profile loading works
- [ ] Profile error state can retry
- [ ] Launch gate resolves onboarding vs main app correctly
- [ ] Completed onboarding routes to main app
- [ ] Returning user does not see onboarding again
- [ ] Initial cloud refresh runs once per session when expected

## 4. Onboarding

- [ ] New user sees onboarding
- [ ] Continue navigation works
- [ ] Back navigation works after moving forward
- [ ] Skip completes onboarding
- [ ] Start fresh routes to main app
- [ ] Add past watches fast opens Quick Add
- [ ] Quick Add sheet dismissal completes onboarding flow correctly
- [ ] Onboarding error message appears if completion fails
- [ ] Onboarding does not repeat after completion

## 5. Quick Add

- [ ] Quick Add opens from Home toolbar
- [ ] Quick Add opens from onboarding
- [ ] Quick Add opens from Timeline empty state
- [ ] TMDB search card opens Media Search
- [ ] User can add a TMDB result
- [ ] Seeded/local fallback suggestions appear
- [ ] Manual title entry works
- [ ] User can add a suggested title
- [ ] Duplicate prevention works
- [ ] Duplicate message appears when relevant
- [ ] Success message appears after add
- [ ] Quick sentiment is stored when selected
- [ ] Approximate watched date is stored when selected
- [ ] Query clears after manual add
- [ ] Quick Add result appears in Timeline
- [ ] Quick Add result can later be upgraded to full entry

## 6. Media Search / TMDB

- [ ] Media Search opens from Quick Add
- [ ] Media Search opens from Entry Editor metadata section
- [ ] Search requires at least 2 characters
- [ ] Debounced search works
- [ ] Immediate submit search works
- [ ] Loading state appears
- [ ] Empty result state appears
- [ ] Error state appears when API fails
- [ ] Clear search works
- [ ] Poster thumbnails render when available
- [ ] Fallback poster renders when poster is unavailable
- [ ] Selecting a result returns metadata to the caller
- [ ] Selected metadata appears in Entry Editor

## 7. Entry Creation and Editing

- [ ] New Entry opens from the plus button
- [ ] Save stays disabled without required fields
- [ ] Title validation works
- [ ] Mood validation works
- [ ] User can create movie entries
- [ ] User can create series entries
- [ ] User can select TMDB metadata
- [ ] User can change selected TMDB metadata
- [ ] User can clear a new TMDB selection
- [ ] Home context works
- [ ] Cinema context reveals cinema-specific fields
- [ ] Cinema audio/screen/comfort fields save correctly
- [ ] Tags are cleaned, deduped, and lowercased
- [ ] Tag limit is enforced
- [ ] Takeaway character count appears
- [ ] Key moment saves correctly
- [ ] Intensity selector works
- [ ] Dirty-dismiss confirmation appears
- [ ] Saved entry appears in Timeline
- [ ] Existing entry can be edited
- [ ] Visibility and Circle sharing selections persist correctly
- [ ] Entry sync state becomes pending after local create/edit

## 8. Quick Add to Full Entry Upgrade

- [ ] Quick Add detail offers Add details
- [ ] Editor title reflects upgrade flow
- [ ] Helper copy reflects upgrade flow
- [ ] User can add emotional details
- [ ] User can add metadata during upgrade
- [ ] User can add Circle sharing during upgrade
- [ ] Saving upgrades source type to full entry
- [ ] Quick Add badge disappears after upgrade
- [ ] Upgraded entry remains in Timeline
- [ ] Updated entry syncs as pending

## 9. Timeline

- [ ] Empty state appears correctly with no entries
- [ ] Personal summary card appears
- [ ] Timeline renders mixed quick-add and full entries
- [ ] Timeline sections render when applicable:
  - [ ] Recently watched
  - [ ] Stayed with you
  - [ ] Rewatch candidates
  - [ ] High-rated memories
  - [ ] All history
- [ ] Low-history QuickPick progress module appears when expected
- [ ] Pending sync badge appears on pending entries
- [ ] Synced entries do not show pending state
- [ ] Failed sync state appears when relevant
- [ ] Deleted entries disappear from main timeline
- [ ] Entry cards open detail
- [ ] Poster thumbnail renders
- [ ] Poster fallback renders
- [ ] Private/shared chip renders correctly

## 10. Entry Detail

- [ ] Detail shows title, type, mood, date, and visibility
- [ ] Poster/backdrop render when metadata exists
- [ ] Fallback media background renders without metadata
- [ ] Overview appears when available
- [ ] Takeaway appears when available
- [ ] Quick Add empty-state copy appears when expected
- [ ] Tags render when available
- [ ] Intensity renders
- [ ] Cinema ratings appear only when relevant
- [ ] Sharing status block appears
- [ ] Sync warning appears for failed entries
- [ ] Actions menu opens
- [ ] Edit / Add details opens the editor
- [ ] Delete confirmation appears

## 11. Delete Entry

- [ ] Deleting removes the entry from Timeline
- [ ] Delete dismisses detail view
- [ ] Delete produces pending sync state
- [ ] Sync sends deleted state to Firestore
- [ ] Deleted remote entry is not restored into Timeline
- [ ] Circle shared timeline no longer shows deleted entry after refresh

## 12. QuickPick

- [ ] Fewer than 3 entries shows insufficient history state
- [ ] CTA to Quick Add works
- [ ] CTA to New Entry works
- [ ] 3 or more entries generate a suggestion
- [ ] Suggestion includes a reason string
- [ ] Suggestion includes a confidence label
- [ ] Suggestion includes signal pills when available
- [ ] Refresh avoids immediate repeats when alternatives exist
- [ ] Already watched seeded candidates are not suggested as new watch-next items
- [ ] Rewatch candidates can be suggested when eligible
- [ ] TMDB discovery can appear when metadata configuration is valid
- [ ] QuickPick works offline from local history when TMDB discovery is unavailable
- [ ] QuickPick does not crash with entries missing metadata

## 13. Battle

- [ ] Battle tab opens
- [ ] Empty/low-history state appears when fewer than 2 eligible entries exist
- [ ] Random pick flow opens option selector
- [ ] User can select at least 2 entries
- [ ] User cannot confirm with fewer than 2 entries
- [ ] Random pick result appears
- [ ] Pick again avoids immediate repeat when possible
- [ ] Random pick result is saved locally
- [ ] Movie vs Movie sheet opens
- [ ] User can choose two different entries
- [ ] User cannot battle the same entry against itself
- [ ] Winner selection works
- [ ] Head-to-head result is saved locally
- [ ] Recent Battle results appear
- [ ] Clear Battle results works
- [ ] Friend Battle and Circle Battle appear as future-facing/unavailable modes

## 14. Circle Creation and Join

- [ ] User can open Circle action sheet
- [ ] User can create a Circle
- [ ] Circle appears in the Circle list after creation
- [ ] Circle count stats update
- [ ] Invite code is shown in Circle detail
- [ ] Invite code can be copied
- [ ] User can open Join Circle
- [ ] Invite code normalizes correctly
- [ ] User can preview a Circle by invite code
- [ ] Already-member preview state appears when expected
- [ ] User can join a Circle by invite code
- [ ] Joined Circle appears in local list after refresh
- [ ] Circle errors show user-readable alerts

## 15. Circle Hub

- [ ] Circle hub shows empty state when no Circles exist
- [ ] Circle hub shows list when Circles exist
- [ ] Owned and joined counts are accurate
- [ ] Circle cards show name, description, owner, member count, and role
- [ ] Deleted Circles do not appear in active list
- [ ] Privacy card appears
- [ ] Circle feature preview card appears
- [ ] Pull remote Circles works when local memberships are empty

## 16. Circle Detail

- [ ] Circle detail opens from Circle list
- [ ] Header shows Circle name, owner, role, member count, and invite code
- [ ] Invite code copy works
- [ ] Segments switch correctly:
  - [ ] Timeline
  - [ ] QuickPick
  - [ ] Members
  - [ ] Activity
- [ ] Members load when available
- [ ] Activity feed loads when available
- [ ] Shared timeline loads when shared entries exist
- [ ] Shared timeline empty state appears when no entries are shared
- [ ] Shared entries open read-only detail
- [ ] Group QuickPick placeholder appears in Circle detail
- [ ] Refresh updates Circle detail data
- [ ] Deleted Circle dismisses or disappears correctly

## 17. Circle Management

- [ ] Owner can edit Circle details
- [ ] Edited Circle name persists locally
- [ ] Edited Circle description persists locally
- [ ] Owner can delete Circle
- [ ] Deleted Circle is removed from active local membership lists
- [ ] Non-owner can leave Circle
- [ ] Owner cannot use leave flow incorrectly
- [ ] Leave Circle removes the Circle from the user’s active list
- [ ] Circle action failures show an alert

## 18. Sharing Entries to Circles

- [ ] Entry editor shows Circle share picker when Circles exist
- [ ] Entry editor handles no-Circle sharing state gracefully
- [ ] User can select one Circle
- [ ] User can select multiple Circles
- [ ] User can unselect Circles
- [ ] Shared entry remains in personal timeline
- [ ] Shared entry visibility becomes Circle
- [ ] Shared Circle IDs persist locally
- [ ] Shared Circle IDs sync to Firestore
- [ ] Shared entry appears in Circle shared timeline after sync/pull
- [ ] Non-shared entry does not appear in Circle timeline
- [ ] Removing all Circles returns entry to private visibility

## 19. Circle Shared Entry Detail

- [ ] Read-only shared entry detail opens
- [ ] Shared-by text is correct for owner vs other member
- [ ] Metadata appears correctly
- [ ] Overview appears when available
- [ ] Takeaway appears
- [ ] Key moment appears when available
- [ ] Watch details appear
- [ ] Tags appear when available
- [ ] Circle access explanation appears
- [ ] Social unavailable state appears when Circle context is invalid
- [ ] Deleted entry social unavailable state appears when relevant
- [ ] Entry not shared with current Circle disables social actions

## 20. Circle Reactions

- [ ] Reactions load for a valid shared Circle entry
- [ ] Reaction bar renders all reaction types
- [ ] User can add one reaction
- [ ] Selecting a different reaction replaces the previous one
- [ ] Selecting the same reaction removes it
- [ ] Reaction count updates after add/remove
- [ ] Reaction update loading state appears
- [ ] Permission failure shows warning banner
- [ ] Missing Firestore index failure is identifiable during QA

## 21. Circle Comments

- [ ] Comments load for a valid shared Circle entry
- [ ] Empty comments state appears
- [ ] User can send a short comment
- [ ] Empty comment cannot be sent
- [ ] Comment max length is enforced
- [ ] Sent comment appears after refresh
- [ ] User can delete their own comment
- [ ] User cannot delete another user’s comment from UI
- [ ] Soft-deleted comments disappear from UI
- [ ] Permission failure shows warning banner
- [ ] Required Firestore index exists for comment queries

## 22. Settings and Sync Controls

- [ ] Profile header appears
- [ ] Control center header appears
- [ ] Sync status summary appears
- [ ] Sync now appears when pending work exists
- [ ] Retry sync appears when failed actions exist
- [ ] Refresh from cloud works
- [ ] Privacy section appears
- [ ] Local-first section appears
- [ ] Pending local entries count is accurate
- [ ] Queued actions count is accurate
- [ ] Completed sync actions count is accurate
- [ ] Clear completed sync history works
- [ ] Version/build info appears
- [ ] Bundle identifier appears
- [ ] Sign out confirmation appears
- [ ] Sign out works

## 23. Firestore Push Sync

- [ ] New full entry syncs to Firestore
- [ ] Quick Add entry syncs to Firestore
- [ ] Edit syncs to Firestore
- [ ] Delete syncs deleted state to Firestore
- [ ] Entry ownerId matches Firebase Auth UID
- [ ] Entry source type is stored correctly
- [ ] External source fields persist correctly when applicable
- [ ] TMDB metadata fields persist correctly
- [ ] Shared Circle IDs persist correctly when present
- [ ] Success or warning feedback appears in Settings after sync

## 24. Firestore Pull Sync

- [ ] Initial session refresh pulls entries when appropriate
- [ ] Manual refresh from Settings pulls entries
- [ ] Fresh install plus sign-in restores synced entries
- [ ] Remote deleted entries stay hidden
- [ ] Local pending entries are not overwritten by pull
- [ ] Local failed entries are not overwritten by pull
- [ ] Pulled TMDB metadata is preserved
- [ ] Pulled shared Circle IDs are preserved

## 25. Firestore Rules and Indexes

- [ ] User can read/write only their own user document
- [ ] User can create/read/update/delete own entries according to rules
- [ ] Circle members can read shared Circle entries
- [ ] Non-members cannot read private Circle data
- [ ] Reactions require valid membership and shared entry access
- [ ] Comments require valid membership and shared entry access
- [ ] Collection group members query works
- [ ] Required comment index exists
- [ ] Required Circle shared entry query index exists if applicable
- [ ] Permission failures are handled without app crash

## 26. Offline-First Behavior

- [ ] App opens offline
- [ ] User can create entries offline
- [ ] User can use Quick Add offline with local fallback/manual title
- [ ] User can edit offline
- [ ] User can delete offline
- [ ] Pending sync state is visible offline
- [ ] No local data loss after relaunch
- [ ] Reconnect plus Sync Now pushes pending changes
- [ ] Refresh from cloud handles offline failure gracefully
- [ ] Circle network-dependent features show recoverable failures

## 27. Conflict and Queue Behavior

- [ ] Pending action queue tracks syncable work
- [ ] Completed actions can be cleaned up
- [ ] Failed actions remain retryable
- [ ] Update after pending create compacts correctly
- [ ] Delete after pending update compacts correctly
- [ ] Pull respects local conflict policy assumptions
- [ ] Local pending work is not overwritten by newer remote data
- [ ] Local failed work remains retryable

## 28. Automated Test Baseline

- [ ] `DuplicateDetectorTests` pass
- [ ] `EntryValidationTests` pass
- [ ] `QuickPickEngineTests` pass
- [ ] `PendingActionQueueTests` pass
- [ ] `EntryConflictPolicyTests` pass
- [ ] `CloseCutUITests` launch test passes
- [ ] Tests compile with current `Entry` initializer
- [ ] Tests run with current Swift concurrency annotations

## 29. Release Readiness

- [ ] Bundle ID is correct
- [ ] Version is correct
- [ ] Build number is correct
- [ ] Signing team is correct
- [ ] `GoogleService-Info.plist` target membership is correct
- [ ] Required Firestore rules are deployed
- [ ] Required Firestore indexes are deployed
- [ ] TMDB configuration is available for builds that need metadata search
- [ ] Archive succeeds
- [ ] Normal happy path does not produce obvious critical console noise
- [ ] App does not crash on auth/session/onboarding/main transitions
- [ ] Main tabs are reachable:
  - [ ] Personal
  - [ ] Circle
  - [ ] Battle
  - [ ] Settings
