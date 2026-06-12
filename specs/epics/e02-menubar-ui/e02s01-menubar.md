STORY KEY: e02s01
TITLE:     Status Bar Item & Dropdown Menu
TYPE:      Story
PARENT:    e02
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      M

### 1. Business narrative
Users need a quick, accessible way to view their clipboard history and select previous items to copy/paste back into their active text field. An application that only runs in the background without a user-visible entry point is unusable.

This story implements the main system status bar (menu bar) item using SwiftUI's `MenuBarExtra`. Clicking the status icon displays a dropdown menu containing the 20 most recent clips with global keyboard shortcuts (Command+0 to Command+9) for quick retrieval, options to clear history, open preferences, and quit the app.

### 2. Value statement
As a macOS user, I want a menu bar icon that shows my recent clipboard items when clicked, so that I can easily select and paste them.

### 3. Actors and permissions
- User (external) — Clicks status bar icon, views list, selects clip, triggers clear/preferences/quit.

### 4. Trigger and preconditions
Trigger: User clicks the application status icon in the macOS menu bar.
Precondition: The application is running as an agent (LSUIElement=YES).

### 5. Main flow and business logic
1. User clicks the menu bar status icon (paperclip image).
2. System displays a dropdown menu.
3. System reads the top 20 items from the clipboard history list.
4. System populates the menu with the text of each clip (truncated to 40 characters if necessary).
5. System assigns shortcuts `cmd+0` through `cmd+9` to the top 10 clips.
6. When the user clicks an item or presses its corresponding shortcut:
   - System copies the selected clip's full text back into the general pasteboard.
   - System issues a virtual keyboard shortcut (Command+V) to paste the text into the frontmost application.
   - System closes the menu.
7. System displays standard options: "Delete All History", "Preferences...", and "Quit".
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Empty Clipboard History
  - If no clips are stored, the system displays "No Clips Stored" (disabled menu item) at the top of the menu.
6b. Selecting "Delete All History"
  - System clears all clips in memory and invokes the StorageManager to clear the `history.json` file on disk.

### 7. Interface elements
Context: new.
Static elements: "Preferences...", "Delete All History", "Quit".
Dynamic elements: MenuBarExtra status icon, list of up to 20 clip titles with key equivalents.

### 8. Domain model
- `Clip` (attributes `text`, `timestamp`)

### 9. Integrations and boundaries
- MenuBarExtra (SwiftUI framework representation of NSStatusItem/NSMenu)
- CGEvent / Quartz (for virtual cmd+v keypress event insertion)

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs when a clip is selected and pasted, or when history is cleared.

### 13. Solution variabilities
- `maxDisplayedClips` (config) — Number of clips shown in the menu (default: 20).

### 14. Quality attributes *NFR*
- Menu opens in < 50ms upon click.
- Truncated text shows trailing ellipses (`...`) for strings exceeding 40 characters.

### 15. Security and compliance *NFR*
- Keyboard simulation events are only routed locally to the frontmost application.

### 16. UX and accessibility *NFR*
- Modality: Screen readers (VoiceOver) can navigate the list and trigger items.

### 17. Acceptance criteria
Scenario: Populated list in dropdown
  Given a clipboard history with 5 items: "A", "B", "C", "D", "E"
  When the user clicks the status bar icon
  Then the dropdown menu displays 5 items
  And the first item "A" has keyboard shortcut Command+0

Scenario: Empty list placeholder (6a)
  Given the clipboard history is empty
  When the user clicks the status bar icon
  Then the dropdown menu displays "No Clips Stored"
  And the item is disabled

Scenario: Selecting clip to paste
  Given the user has focus on a TextEdit document
  And the clipboard history contains "apple" as the first item (cmd+0)
  When the user presses Command+0 while the menu is active
  Then "apple" is written to the system clipboard
  And "apple" is inserted into the TextEdit document

Scenario: Delete All History (6b)
  Given a clipboard history with 10 items
  When the user clicks "Delete All History" in the dropdown
  Then the history is completely cleared in memory and on disk
  And the menu displays "No Clips Stored"

### 18. Out of scope
- Custom popover views with Search filters inside the menu bar dropdown itself (search is handled in the Preferences window).

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
