STORY KEY: e02s02
TITLE:     Auto-Strip Formatting Toggle
TYPE:      Story
PARENT:    e02
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      S

### 1. Business narrative
Rich text copied from websites, PDFs, or formatted documents carries style payloads (font, size, color, alignments) that pollute the destination document when pasted. This forces users to paste text and then manually format it, or use auxiliary software.

This story adds a global toggle for "Auto-Strip Formatting" (Paste Plain Text mode). When active, any new copy containing styling is intercepted, cleared of styles, and written back to the clipboard as pure plain text.

### 2. Value statement
As a macOS user, I want the app to automatically remove formatting from text I copy when Auto-Strip is enabled, so that I paste only clean, style-free text.

### 3. Actors and permissions
- ClipboardMonitor (system) — Intercepts styled text copies and updates the system clipboard with plain text.

### 4. Trigger and preconditions
Trigger: User copies text when the Auto-Strip setting is enabled.
Precondition: "Auto-Strip Formatting" option is active.

### 5. Main flow and business logic
1. User enables the "Auto-Strip Formatting" toggle from the menu bar dropdown or preferences.
2. User copies a block of rich text (containing RTF, HTML, or styled data) from an external app.
3. `ClipboardMonitor` detects the clipboard change.
4. `ClipboardMonitor` checks if the clipboard contains rich formatting types (e.g., `rtf`, `html`) in addition to plain text.
5. System extracts the plain text string from `NSPasteboard.general`.
6. System clears the contents of `NSPasteboard.general`.
7. System writes the plain text string back to the pasteboard under the single type `NSPasteboard.PasteboardType.string`.
8. System updates the internal change count to avoid triggering a self-copy detection loop.
9. System records the plain text item in the history.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Copy Already Plain Text
  - If the clipboard content has no rich text types or its text matches the last processed string, the monitor registers the item in history but does not rewrite the pasteboard, avoiding an infinite trigger loop.
6b. Auto-Strip Disabled
  - If the toggle is disabled, the system preserves the rich formatting on the clipboard, but records the plain text representation in the history list.

### 7. Interface elements
Context: existing.
Static elements: None.
Dynamic elements: "Auto-Strip Formatting" toggle menu item in dropdown.

### 8. Domain model
Not applicable.

### 9. Integrations and boundaries
- NSPasteboard.general (perennial, direction: both)

### 10. Background processes
- Pasteboard interceptor loop.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs the bundle ID of the source app and the length of the string stripped.

### 13. Solution variabilities
- `isAutoStripEnabled` (config) — Boolean toggle state stored in `UserDefaults`.

### 14. Quality attributes *NFR*
- Formatting stripping completes in < 3ms from detection.

### 15. Security and compliance *NFR*
- Clipboard manipulation is performed locally, in memory.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Auto-Strip rich text copy
  Given "Auto-Strip Formatting" is enabled
  When the user copies rich text containing RTF formatting
  Then the system intercepts the copy
  And the clipboard is updated to hold only plain text string
  And pasting with Command+V outputs plain text without formatting

Scenario: Prevent infinite polling loop (6a)
  Given "Auto-Strip Formatting" is enabled
  When the system writes plain text back to the clipboard
  Then the clipboard monitor does not trigger a duplicate copy event or loop

Scenario: Preserve formatting when disabled (6b)
  Given "Auto-Strip Formatting" is disabled
  When the user copies rich text containing RTF formatting
  Then the clipboard contents remain styled
  And the plain text representation is still added to the history

### 18. Out of scope
- Custom stripping rules (e.g. keeping links but stripping fonts) - all formatting is stripped.

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
