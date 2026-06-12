# Conventions

## Conventional Commits & Semantic Versioning

All changes to this repository MUST follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. Versioning MUST strictly adhere to [Semantic Versioning 2.0.0](https://semver.org/).

### Commit Message Format
`<type>(<scope>): <description>` (Space after colon is MANDATORY)

### Types & Version Bumps
- `feat`: Minor (x.Y.z) - New feature
- `fix`: Patch (x.y.Z) - Bug fix
- `perf`: Patch (x.y.Z) - Performance improvement
- `docs`, `chore`, `style`, `refactor`, `test`: No bump (unless breaking)
- `BREAKING CHANGE:` (or `!` after type): Major (X.y.z)

## GitHub & Git Operations

- No direct work on `main` or `master`. Every task MUST start with a feature branch or worktree via `kickoff-branch`.
- **Integrate:** Use `release-branch` in **solo-local** mode (`land-branch.sh`) to land changes locally squashed to `main`, then push to remote.
- **Git Attribution:** NEVER include `Co-authored-by`, `Co-Authored-By`, or any other footer that attributes code to an AI agent (e.g., Claude, Gemini) in git commits. All commits MUST appear as if they were authored solely by the human user.
- Never call GitHub REST API directly.
- Never create GitHub issues from automated workflows — produce local `.md` files in `specs/` instead.

## Agent Workflow Mandates

**AGENTS MUST NEVER BYPASS THE BIGPOWERS WORKFLOW.**
You are operating within the `bigpowers` spec-driven development methodology.
- **No Direct Coding:** When a user issues a directive like "build feature X" or "go epic 10", you MUST NOT execute the request by writing code directly.
- **Required Skills:** You MUST route all work through the appropriate bigpowers skills.
  - Start with `survey-context` if you lack context.
  - Use `plan-work` to flesh out tasks in `specs/epics/eNN-*.yaml` (with `verify:` per task) before writing any feature code.
  - Use `develop-tdd` or `execute-plan` to implement the plan.
  - Use `investigate-bug` for bug reports before writing a fix.
- **Verification Mandate:** Every story implementation MUST end with a step-by-step manual verification script provided to the user. You must wait for the user to confirm behavioral correctness (UAT) before declaring the story done or moving to the next.
- **Verification:** You MUST verify every change with tests. Code generation without a corresponding plan in `specs/` is strictly forbidden.

## specs/ — All Planning Output Goes Here

Every skill that produces written output writes to `specs/` at the project root.

### YAML cockpit (runtime + delivery)

| Layer | File | Answers |
|-------|------|---------|
| Session | `specs/state.yaml` | Active flow, epic/bug, ship-epic step, git, `handoff.next_skill` |
| Release index | `specs/release-plan.yaml` | Target semver, WSJF epic list |
| Progress | `specs/execution-status.yaml` | Flat status keys (`e01`, `e01s01`) — sole SoT for story state |

- **Do not** put story status in `release-plan.yaml`. **Do not** duplicate the release plan inside `state.yaml`.
- Every story implementation must specify story baseline BCPs in `release-plan.yaml`.
- All written output (plans, specs, investigations) goes in `specs/`.

## Code Style (Swift & Native stack)

- **Layout:** Structure source files under `Sources/App/`, `Sources/Core/`, and `Sources/UI/` directories.
- **XCodeGen:** Always run `xcodegen --spec project.yml` after adding, deleting, or renaming source/test files.
- **Types:** Use `struct` for value types; `class` only when reference semantics/lifecycle management are required.
- **Async:** Use `async/await` rather than completion handlers or callback pyramids.
- **Thread Safety:** Align UI updates and clipboard-related pasteboard access to `@MainActor`.
- **Functions:** Under 20 lines. Split if longer.
- **Files:** Under 300 lines. Split by responsibility to ensure content fits within a single agent context window.
- **Names:** Descriptive and unique. Avoid force-unwrap (`!`) in production paths without a documented safety invariant.
- **Boy Scout Rule:** Leave every file you touch at least as clean as you found it. Fix the first broken window you see.

## Comments

- Keep existing comments. Never strip them on refactor.
- Write WHY, not WHAT.
- Docstrings on public functions: intent + one usage example.

## Tests (F.I.R.S.T)

- Tests run headless with a single command: `xcodebuild test -project BigClipboard.xcodeproj -scheme BigClipboard -only-testing BigClipboardTests`.
- Every new function gets a test. Every bug fix gets a regression test.
- Use Swift Testing (`@Suite`, `@Test`, `#expect`) instead of legacy XCTest.
- Assert on observable outcomes (return values, API responses, UI state). Never assert on internal state or private methods.

## Defensive Code

- **File Write Throttling:** Coalesce rapid clipboard history updates (e.g. within 500ms) before writing the history JSON to disk to avoid write-amplification and excessive CPU usage.
- **Graceful Degradation:** If JSON parsing or file write fails, log the error and fallback to in-memory history storage so clipboard history continues working for the current session.
