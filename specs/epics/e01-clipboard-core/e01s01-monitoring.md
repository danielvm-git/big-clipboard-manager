STORY KEY: e01s01
TITLE:     Background Clipboard Monitoring
TYPE:      Story
PARENT:    e01
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      M

### 1. Business narrative
Users constantly copy and paste text snippets across multiple applications. The default macOS clipboard only retains the most recently copied item, resulting in data loss when a new item is copied before the old one is pasted. This forces users to repeat copy operations, introducing friction and delays. 

This story introduces a background clipboard monitor that polls the macOS pasteboard system for text content changes and populates an in-memory clipboard history buffer.

### 2. Value statement
As a macOS user, I want the app to automatically track when I copy text to my clipboard, so that my history includes all recently copied items.

### 3. Actors and permissions
- ClipboardMonitor (system) — Polls `NSPasteboard.general` and updates in-memory history.
- User (external) — Copies text snippets using system-wide applications.

### 4. Trigger and preconditions
Trigger: A background timer fires every 500 milliseconds.
Precondition: The application is running in the background and the "Record clipboard history" setting is enabled.

### 5. Main flow and business logic
1. System wakes up on background polling timer.
2. System reads the current `changeCount` of `NSPasteboard.general`.
3. System detects that `changeCount` has increased compared to the last recorded value.
4. System queries `NSPasteboard.general` for the primary string representation.
5. System validates that the string is not empty.
6. System compares the new string with the most recent item in the history buffer.
7. If the string is new and not a duplicate of the last entry, the system creates a new `Clip` object with the text, a unique identifier, and the current timestamp.
8. System appends the new `Clip` to the head of the in-memory history array.
9. System trims the history array if it exceeds the maximum size limit (default: 80).
Interruption point: N/A (runs continuously in the background).

### 6. Alternative flows and exceptions
6a. Consecutive Duplicate Copy
  - If the new string is identical to the text of the first item in the history array, the copy is ignored, and the history count does not increase.
6b. Non-Text Content Copied
  - If the pasteboard contains no string representation (e.g., an image or file is copied), the `changeCount` is updated, but the system ignores the copy and history remains unchanged.

### 7. Interface elements
Context: new.
Static elements: Not applicable.
Dynamic elements: Not applicable.

### 8. Domain model
- `Clip`:
  - `id`: UUID
  - `text`: String
  - `timestamp`: Date

### 9. Integrations and boundaries
- NSPasteboard.general (perennial, direction: both)

### 10. Background processes
- Pasteboard Polling Timer (scheduled, 500ms interval)

### 11. Notifications
Not applicable.

### 12. Audit and logging
- System logs information when a new clip is successfully recorded or ignored due to duplicate checks.

### 13. Solution variabilities
- `maxRememberedClips` (config) — Max size of the history array (default: 80).
- `isRecordingEnabled` (config) — Enable/disable pasteboard polling (default: true).

### 14. Quality attributes *NFR*
- Pasteboard verification pass completes in < 5ms.
- Background polling thread maintains CPU overhead of < 1% on idle.

### 15. Security and compliance *NFR*
- Clipboard data is only read and stored in local memory; no network interfaces are declared.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Successful detection of copied text
  Given the clipboard history is empty
  When the user copies "antigravity rules" to the system clipboard
  Then the clipboard monitor detects the new string within 500ms
  And "antigravity rules" is added to the top of the history

Scenario: Prevent duplicate consecutive entries (6a)
  Given the last item in the clipboard history is "antigravity rules"
  When the user copies "antigravity rules" to the system clipboard again
  Then the clipboard monitor detects the copy
  And the clipboard history size does not change
  And no duplicate entry is created

Scenario: Ignore non-text clipboard updates (6b)
  Given the clipboard history contains 1 item
  When the user copies an image file to the system clipboard
  Then the clipboard monitor detects the clipboard change
  And the clipboard history size remains exactly 1

### 18. Out of scope
- Non-text clipboard tracking (images, files, PDFs).
- Database writes (covered in the persistence story, `e01s02`).

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
