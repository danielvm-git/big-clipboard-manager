STORY KEY: e03s01
TITLE:     General Preferences Settings
TYPE:      Story
PARENT:    e03
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      S

### 1. Business narrative
Users have different preferences for how many history clips they want to keep and show. A heavy user may want to remember 1000 items and display 50 in their dropdown menu, while a user seeking minimal resource usage might want only 10. They also need toggles for recording state and startup behavior.

This story builds the "General" preferences tab view in SwiftUI, letting users configure history storage limit, menu display limit, launch status, and active clipboard recording status.

### 2. Value statement
As a macOS user, I want a general settings interface to customize the clipboard history size, display limit, and recording state, so that the app matches my usage habits.

### 3. Actors and permissions
- User (external) — Modifies preferences text fields and checkboxes.

### 4. Trigger and preconditions
Trigger: User clicks "Preferences..." in the status bar dropdown menu, opening the settings window.
Precondition: The Settings/Preferences SwiftUI Scene is registered.

### 5. Main flow and business logic
1. User clicks "Preferences..." in the dropdown menu.
2. System opens the multi-tab Preferences window and shows the "General" tab by default.
3. System reads settings from `UserDefaults` and displays:
   - "Remember [N] clippings" (text input field backing history trim size).
   - "Display [M] clippings" (text input field backing menu display size).
   - "Start CopyClip at system startup" checkbox (linked to SMAppService).
   - "Record clipboard history" checkbox (linked to ClipboardMonitor active state).
4. User changes any setting.
5. System validates inputs:
   - "Remember" must be an integer between 1 and 9999.
   - "Display" must be an integer between 1 and 100.
6. If valid, the system saves the change to `UserDefaults` immediately.
7. System updates the live `AppState` / `ClipboardMonitor` configuration parameters.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Invalid Input in Numeric Fields
  - If the user inputs non-numeric characters or out-of-bounds numbers (e.g. 0 or 100000), the system displays a red validation highlight and falls back to saving the last known valid configuration.

### 7. Interface elements
Context: new.
Static elements: "Remember:", "clippings", "Display:", "clippings", "Options".
Dynamic elements: Checkboxes (Start at Startup, Record History), input text fields (Remember count, Display count) with validation states.

### 8. Domain model
Not applicable.

### 9. Integrations and boundaries
- UserDefaults (perennial, direction: both)

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs validation errors and general setting changes.

### 13. Solution variabilities
- App settings stored in `UserDefaults`.

### 14. Quality attributes *NFR*
- Changing settings updates active clipboard tracking behavior in < 10ms.

### 15. Security and compliance *NFR*
- Preferences are written to standard application preferences files.

### 16. UX and accessibility *NFR*
- Custom text fields support tab navigation and keyboard accessibility.

### 17. Acceptance criteria
Scenario: Load settings into form
  When the user opens Preferences
  Then the General tab displays current values from UserDefaults (default: Remember 80, Display 20)

Scenario: Update numeric preferences successfully
  Given the user changes "Remember clippings" to "150"
  When the field loses focus
  Then the setting is saved in UserDefaults
  And AppState trim size is updated to 150

Scenario: Validate out of bounds input (6a)
  Given the user enters "-10" or "abc" in "Remember clippings"
  When the field loses focus
  Then the system does not save the change
  And shows a visual validation warning

### 18. Out of scope
- Separate window controller sheets for settings (uses SwiftUI standard Settings scene/window).

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
