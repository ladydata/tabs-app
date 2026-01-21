# Settled Tabs Redesign

## Overview

Redesign how settled tabs (groups) are handled to match Splitwise's UX pattern. Instead of showing all groups in the main list with a manual cleanup option, automatically hide settled tabs after 30 days and provide a dedicated view for managing them.

## Current State

- All groups (active and settled) appear in the main groups list
- "Clean Up Inactive Tabs" option buried in profile menu
- Users must manually trigger cleanup of old settled groups

## New Behavior

### Auto-Hide Logic

- Groups that are **settled** AND have **no activity for 30+ days** are hidden from the main list
- The 30-day clock starts from the `settledAt` timestamp (or last activity, whichever is later)
- No new database fields needed - uses existing `isSettled` flag and timestamps
- No migration required - existing settled groups appear in the new section based on their timestamps

### Floating "Settled Tabs" Card

**Location:** Fixed at the bottom of the groups screen, floating above the scrollable list

**Appearance:**
- Slightly elevated with shadow
- Muted styling (subtle background, archive icon)
- Shows count: "Settled Tabs (3)"

**Behavior:**
- Only visible when at least 1 hidden settled tab exists
- Always visible while scrolling (not part of the list)
- Tapping navigates to the Settled Tabs screen
- Main list has bottom padding so last group isn't obscured

### Settled Tabs Screen

**Navigation:** Full-screen view pushed onto navigation stack

**App bar:** Back button + title "Settled Tabs"

**List display:**
- Same card style as main groups list
- Each card shows: group name, member count, currency, settled duration (e.g., "Settled 45 days ago")
- Empty state: "No settled tabs"

**Swipe-to-delete:**
- Swipe left reveals delete action (red background, trash icon)
- Releasing swipe triggers immediate deletion
- Snackbar appears: "Tab deleted" with "Undo" button
- Undo restores tab to settled list (stays settled, just not deleted)
- Snackbar auto-dismisses after ~4 seconds
- Soft delete while snackbar visible, hard delete after dismissal

**No restore option:** Users can only delete, not move back to active list

### Cleanup

- Remove "Clean Up Inactive Tabs" from profile menu
- Delete associated dialog and bulk deletion code
- Reuse existing deletion logic for individual group removal

## Summary Table

| Aspect | Decision |
|--------|----------|
| Auto-hide rule | Settled + 30 days inactive |
| Entry point | Floating card at bottom of groups screen |
| Card visibility | Only when settled tabs exist |
| Tap action | Navigate to full-screen Settled Tabs list |
| Deletion method | Swipe-to-delete on individual tabs |
| Confirmation | None - immediate delete with undo snackbar |
| Restore option | No - delete only |
| Old feature | Remove "Clean Up Inactive Tabs" from profile menu |
