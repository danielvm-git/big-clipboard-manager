# BigClipboard — OpenCode

Read CONVENTIONS.md before any GitHub or git operation.

## Project
A macOS menu bar clipboard manager that saves clipboard history and automatically strips text formatting.
Stack: Swift 6.0 / SwiftUI / macOS 14.0+

## Commands
| Action | Command |
|--------|---------|
| Run    | `open build/Debug/BigClipboard.app` |
| Test   | `xcodebuild test -project BigClipboard.xcodeproj -scheme BigClipboard -only-testing BigClipboardTests` |
| Build  | `xcodebuild -project BigClipboard.xcodeproj -scheme BigClipboard build` |
| Lint   | `swiftlint` (if installed) |
| Regen project | `xcodegen --spec project.yml` |

## Architecture
A native macOS SwiftUI app centered around MenuBarExtra. AppState coordinates NSPasteboard polling, history retention, and plain-text stripping with persistent JSON storage.

## Conventions
- Run `xcodegen --spec project.yml` after adding, deleting, or renaming source/test files.
- Align code to App/, Core/, and UI/ directories under Sources/.
- Align UI state updates and clipboard interactions to `@MainActor`.
- Write unit tests using the new Swift Testing framework (`@Suite`, `@Test`, `#expect`).

## Never
- Never hardcode the user's home directory (always resolve paths dynamically using FileManager).
- Never use external packages or libraries (maintain 100% native Cocoa/Swift frameworks).
- Never skip regenerating `BigClipboard.xcodeproj` via `xcodegen` when file structures change.
- Never commit to `main` directly (always follow the bigpowers branch lifecycle).

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g., `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (`product/SCOPE_LATEST.yaml`, `release-plan.yaml`, `epics/`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
