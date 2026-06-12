STORY KEY: e03s02
TITLE:     Ignored Applications Blacklist
TYPE:      Story
PARENT:    e03
STATUS:    Draft
AUTHOR:    danielvm      DATE: 2026-06-12
MATURITY:  5
SIZE:      M

### 1. Business narrative
Users frequently handle sensitive data such as master passwords, authentication tokens, and private keys inside password managers or terminal shells. Storing these items in plain text clipboard histories exposes users to credential harvesting or accidental visual leakage. 

This story builds the "Ignored Apps" preferences tab. It lets users check running applications (e.g. 1Password, Keychain Access) to block the clipboard manager from saving any text copied while those applications are active.

### 2. Value statement
As a macOS user, I want to select specific apps whose clipboard copies should be ignored, so that passwords or sensitive data from those apps are never recorded in my history.

### 3. Actors and permissions
- User (external) — Selects applications to add/remove from the ignored apps list.
- ClipboardMonitor (system) — Queries active application bundle IDs and filters clipboard additions.

### 4. Trigger and preconditions
Trigger: A copy operation occurs while an ignored app has active focus.
Precondition: Blacklist configuration is saved in `UserDefaults` and workspace API is accessible.

### 5. Main flow and business logic
1. User clicks the "Ignored Apps" tab in Preferences.
2. System fetches currently running applications using `NSWorkspace.shared.runningApplications`.
3. System filters the list to include only user-visible GUI applications with a bundle identifier.
4. System displays the list showing each application's name, bundle identifier, and icon alongside a checkbox.
5. User checks the box next to an application.
6. System adds the bundle identifier to the `ignoredAppBundleIds` array in `UserDefaults` and updates `AppState`.
7. When the user copies text, `ClipboardMonitor` reads the bundle identifier of the frontmost application:
   `NSWorkspace.shared.frontmostApplication?.bundleIdentifier`.
8. System checks if the identifier exists in `ignoredAppBundleIds`.
9. If found, the system discards the clipboard addition and does not create a `Clip` object.
Interruption point: N/A.

### 6. Alternative flows and exceptions
6a. Bundle Identifier Unavailable
  - If the frontmost application's bundle identifier is nil or cannot be resolved, the system defaults to recording the clipboard item to prevent silent copy failures.

### 7. Interface elements
Context: new.
Static elements: Columns headers (AppName, Bundle ID).
Dynamic elements: Scrollable list of running applications with icons, names, bundle IDs, and checkboxes.

### 8. Domain model
Not applicable.

### 9. Integrations and boundaries
- NSWorkspace (perennial, direction: in)

### 10. Background processes
Not applicable.

### 11. Notifications
Not applicable.

### 12. Audit and logging
- Logs when a copy is ignored (logs source bundle ID and text length; never logs text contents).

### 13. Solution variabilities
- `ignoredAppBundleIds` (config) — Persistent string array in `UserDefaults`.

### 14. Quality attributes *NFR*
- Frontmost app check completes in < 1ms on copy detection.
- App list loads in Preferences in < 100ms.

### 15. Security and compliance *NFR*
- Blacklist checks are local. Excluded strings never touch RAM history or disk files.

### 16. UX and accessibility *NFR*
- App list rows support standard VoiceOver navigation.

### 17. Acceptance criteria
Scenario: Blacklist application successfully
  Given "com.agilebits.onepassword-osx" is checked in the Ignored Apps list
  When the user copies "my_secret_password" inside 1Password
  Then the clipboard monitor detects the copy
  And matches the bundle identifier with the blacklist
  And the history list remains unchanged

Scenario: Standard recording for unlisted apps
  Given "com.apple.Safari" is unchecked in the Ignored Apps list
  When the user copies "public search query" inside Safari
  Then the clipboard monitor records "public search query" in history

Scenario: Fallback on missing identifier (6a)
  Given the frontmost application bundle ID cannot be resolved (is nil)
  When the user copies "anonymous text"
  Then the system records the text in history

### 18. Out of scope
- Manual text entry of bundle identifiers - apps must be selected from the dynamic list of running applications.

### 19. Open questions
Not applicable.

### 20. References
- CLAUDE.md
- CONVENTIONS.md
