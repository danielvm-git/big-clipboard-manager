STORY KEY: e03s03
TITLE:     Clips Management Interface
TYPE:      Story
PARENT:    e03
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      M

### 1. Business narrative
While the menu bar dropdown displays recent clips for instant copying, users need a dedicated management space to inspect their entire history logs, search for specific clips, clean up single items, and configure safety gates for deletions.

This story builds the "Clips Management" preferences tab view in SwiftUI, incorporating search filtering, a data table showing all clips, a delete command, and a "Confirm before deleting" toggle.

### 2. Value statement
As a macOS user, I want an interface to search, inspect, and delete individual clipboard items, so that I can manage my history and clean up sensitive entries easily.

### 3. Actors and permissions
- User (external) — Searches clips, selects items to delete, toggles deletion confirmation.

### 4. Trigger and preconditions
Trigger: User clicks the "Clips Management" tab in the Preferences window.
Precondition: Clipboard history array is populated.

### 5. Main flow and business logic
1. User clicks the "Clips Management" tab in Preferences.
2. System displays:
   - A search bar at the top.
   - A scrollable list of all stored clippings.
   - A "Confirm before deleting" checkbox.
   - A "Delete" button (disabled unless an item is selected).
3. User types a query string into the search bar.
4. System filters the clips list in real-time using case-insensitive substring matching on the clip text.
5. User selects a clip from the list.
6. User clicks the "Delete" button.
7. System checks if "Confirm before deleting" is checked.
8. If checked:
   - System displays an NSAlert confirmation dialog: "Are you sure you want to delete this clipping?"
   - If user confirms:
     - System deletes the clip from `AppState` in-memory history.
     - System triggers `StorageManager` to update the JSON file.
     - System updates the list display.
   - If user cancels:
     - System dismisses the alert without modifying the clip.
9. If "Confirm before deleting" is unchecked:
   - System deletes the clip from memory and disk immediately.
Interruption point: NSAlert modal blocks main thread execution until dismissed.

### 6. Alternative flows and exceptions
6a. No Search Matches
  - If no clips match the search query, the system displays a placeholder text "No Match Found" in the center of the list.

### 7. Interface elements
Context: new.
Static elements: "Confirm before deleting", "Delete".
Dynamic elements: Search field, scrollable list of clips, NSAlert modal dialog.

### 8. Domain model
Not applicable.

### 9. Integrations and boundaries
- NSAlert (Cocoa modal UI library)

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs individual clip deletion operations.

### 13. Solution variabilities
- `confirmBeforeDeleting` (config) — Boolean state backed by `UserDefaults` (default: true).

### 14. Quality attributes *NFR*
- Search filter updates in < 10ms for a history list of 1000 items.

### 15. Security and compliance *NFR*
- Deleted items are completely wiped from both active RAM and the persistent JSON file.

### 16. UX and accessibility *NFR*
- List items and search input support keyboard accessibility focus.

### 17. Acceptance criteria
Scenario: Filter history list in real-time
  Given the history contains "XcodeGen build", "git status", and "xcodebuild test"
  When the user types "xcode" in the search bar
  Then the list displays "XcodeGen build" and "xcodebuild test"
  And "git status" is hidden

Scenario: Delete clipping with confirmation prompt
  Given "Confirm before deleting" is checked
  And the user selects a clip
  When the user clicks "Delete"
  Then the system displays a confirmation dialog
  And the clip is only removed after the user confirms

Scenario: Delete clipping immediately without confirmation
  Given "Confirm before deleting" is unchecked
  And the user selects a clip
  When the user clicks "Delete"
  Then the clip is deleted immediately without any dialog prompt

### 18. Out of scope
- Batch selection and deleting of multiple items (deletions are done one-by-one or via "Delete All History").

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
