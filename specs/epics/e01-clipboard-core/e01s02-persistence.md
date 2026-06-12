STORY KEY: e01s02
TITLE:     History Persistence via JSON
TYPE:      Story
PARENT:    e01
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      M

### 1. Business narrative
To provide a useful experience, clipboard history must survive application restarts and system reboots. Retaining history only in memory causes data loss when updating the app or restarting macOS. 

This story introduces local file persistence using Swift's `JSONEncoder` and `JSONDecoder` to save and load history files from the standard macOS Application Support directory. To optimize disk operations and prevent write-amplification during rapid copies, writes will be throttled.

### 2. Value statement
As a macOS user, I want my clipboard history to be saved to my hard drive, so that my clips are preserved even if the application or system restarts.

### 3. Actors and permissions
- StorageManager (system) — Decodes and encodes the history JSON payload and writes it to disk.

### 4. Trigger and preconditions
Trigger: The application starts up, or the in-memory clipboard history is modified (appended or deleted).
Precondition: The system has write permissions in the user's `Library/Application Support/` directory.

### 5. Main flow and business logic
1. During startup, the system resolves the URL path to the Application Support directory (`com.danielvm.bigclipboard/history.json`).
2. If the directory does not exist, the system creates it.
3. If `history.json` exists, the system reads its contents and decodes the JSON data into a `[Clip]` array.
4. The system populates the `ClipboardMonitor` in-memory history list with the decoded array.
5. When `ClipboardMonitor` adds a new clip or removes an existing one, it notifies `StorageManager`.
6. `StorageManager` schedules an encoding operation with a 500ms throttle delay to group consecutive modifications.
7. Once the throttle timer fires, the system serializes `[Clip]` to JSON.
8. The system writes the serialized JSON data atomically to `history.json`.
Interruption point: Startup load phase (the app must block or defer history list operations until load completes).

### 6. Alternative flows and exceptions
6a. Missing History File
  - If the `history.json` file does not exist, the system logs the condition and initializes the history with an empty array.
6b. Corrupted History File (Graceful Degradation)
  - If JSON decoding fails due to corruption or schema mismatch, the system logs the error, renames the corrupted file to `history.corrupted.json` as a backup, and falls back to an empty array.

### 7. Interface elements
Context: new.
Static elements: Not applicable.
Dynamic elements: Not applicable.

### 8. Domain model
- `Clip` (must conform to `Codable`)

### 9. Integrations and boundaries
- FileManager (perennial, direction: both)

### 10. Background processes
- Throttled Write Queue (event-driven, coalesces updates within 500ms)

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs file read operations, parsing failures, and atomicity metrics on write.

### 13. Solution variabilities
- `historyFileName` (config) — Name of the storage file (default: "history.json").

### 14. Quality attributes *NFR*
- JSON decoding takes < 10ms for 80 clips.
- Atomicity ensures that crash mid-write does not destroy the original history file.

### 15. Security and compliance *NFR*
- Files are written to local storage, restricted to user-level execution directories.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Load existing history file
  Given a valid `history.json` containing 3 clips is stored on disk
  When the app launches
  Then the clipboard history list loads all 3 clips in correct chronological order

Scenario: Save history dynamically with throttling
  Given the clipboard history is empty
  When the user copies "clip1" and "clip2" within 200ms
  Then the system writes to `history.json` exactly once
  And the file contains both clips

Scenario: Corrupted file recovery (6b)
  Given a corrupted `history.json` file containing malformed text
  When the app starts up
  Then the system logs the decode error
  And rename-backups the corrupted file
  And the app loads successfully with an empty history list

### 18. Out of scope
- History encryption.
- Multi-user sharing.

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
