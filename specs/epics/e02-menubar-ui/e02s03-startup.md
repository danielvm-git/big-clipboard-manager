STORY KEY: e02s03
TITLE:     Launch at Startup Integration
TYPE:      Story
PARENT:    e02
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      S

### 1. Business narrative
A menu bar clipboard manager is only effective if it captures all copy actions across system sessions. If the user has to manually open the app after every reboot or login, clips copied before launching are lost.

This story integrates launch-at-login capabilities using ServiceManagement's modern `SMAppService` API, allowing the user to toggle automatic startup directly from the General Preferences tab.

### 2. Value statement
As a macOS user, I want the app to start automatically upon system login, so that it is always running and tracking my clipboard history without manual intervention.

### 3. Actors and permissions
- StartupManager (system) — Registers and unregisters the application binary with the macOS Launch Services.
- User (external) — Toggles the startup registration setting.

### 4. Trigger and preconditions
Trigger: User modifies the "Start CopyClip at system startup" preference.
Precondition: Runs on macOS 13.0+ (supporting `SMAppService`).

### 5. Main flow and business logic
1. User clicks the "Start CopyClip at system startup" checkbox in Preferences.
2. System checks the current registration status via `SMAppService.mainApp.status`.
3. If checking the box:
   - System calls `SMAppService.mainApp.register()`.
   - System updates `UserDefaults` configuration keys.
4. If unchecking the box:
   - System calls `SMAppService.mainApp.unregister()`.
   - System updates `UserDefaults` configuration keys.
5. System logs the outcome.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Registration Failure
  - If `SMAppService` throws an exception during register/unregister, the system displays an error alert to the user, logs the details, and reverts the checkbox interface state to match the actual status.

### 7. Interface elements
Context: existing.
Static elements: None.
Dynamic elements: "Start CopyClip at system startup" toggle in General Preferences.

### 8. Domain model
Not applicable.

### 9. Integrations and boundaries
- ServiceManagement framework (`SMAppService`)

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs launch status query results and registration changes.

### 13. Solution variabilities
- `startAtStartup` (config) — Persistent setting in `UserDefaults`.

### 14. Quality attributes *NFR*
- SMAppService query returns status in < 10ms.

### 15. Security and compliance *NFR*
- App uses user-level login agent privileges. No daemon/admin rights are requested.

### 16. UX and accessibility *NFR*
Not applicable.

### 17. Acceptance criteria
Scenario: Register app for login startup
  Given the app is currently not registered to start at login
  When the user checks "Start CopyClip at system startup"
  Then the system invokes `SMAppService.mainApp.register()`
  And the service registration state is marked active

Scenario: Unregister app from login startup
  Given the app is registered to start at login
  When the user unchecks "Start CopyClip at system startup"
  Then the system invokes `SMAppService.mainApp.unregister()`
  And the service registration state is marked inactive

### 18. Out of scope
- SMLoginItems helper apps (legacy API pre-macOS 13.0).

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
