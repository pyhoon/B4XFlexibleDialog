# B4XFlexibleDialog TODO

Status reflects the current B4J Milestone 1 implementation and the interactive checks reported from the demo. See [`milestones.md`](milestones.md) for scope and acceptance details.

## M0 — Definition contract and B4J model — COMPLETE

- [x] Define and document JSON schema version 1.
- [x] Parse definitions and reject malformed JSON, unsupported types, duplicate IDs, invalid defaults, and malformed choice/number options.
- [x] Keep metadata separate from value state and JavaFX controls.
- [x] Verify the B4J demo model cases for valid/invalid JSON, duplicates, unknown types, defaults, and choice values.

## M1 — B4J core and basic preferences dialog — COMPLETE

- [x] Implement committed values, defaults, typed `GetValue` / `SetValue`, and defensive `GetValues` snapshots.
- [x] Implement explicit-mode draft, validation, atomic commit, Cancel, and window-close discard.
- [x] Render `text`, `number`, `switch`, and `choice` in a modal JavaFX dialog.
- [x] Provide before-save, after-save, and dialog-closed callbacks.
- [x] Add English/Malay dictionaries, runtime language switching, missing-key fallback, and basic light/dark theme.
- [x] Supply a runnable B4J demo, schema, API documentation, and changelog.
- [x] Compile with B4JBuilder 10.70 and run the demo/core assertions.
- [x] Verify control editing, Save/Cancel, invalid numeric input/bounds, language/theme switching, and value restoration after dialog reopen (reported from interactive demo tests).
- [x] Confirm values intentionally reset after application restart; persistence is not part of this milestone.

## M2 — B4J full-page renderer — COMPLETE

- [x] Render the same definition/controller into a caller-provided B4J `AnchorPane`.
- [x] Leave caller navigation and unrelated container nodes under caller ownership; expose mount/refresh/dispose calls.
- [x] Reuse controller values and explicit Save/Cancel semantics between dialog and page.
- [x] Refresh page controls after programmatic value, language, and theme changes.
- [x] Add a demo host panel that switches dialog/page without reloading committed values.
- [x] Verify sizing, scrolling, cleanup, repeated mounting, and caller-owned layout behavior (reported from interactive demo tests).
- [x] Run interactive page acceptance tests for Save, Cancel, programmatic updates, localization, and theme refresh (reported passing).

## M3 — Additional preference types and validation — COMPLETE

- [x] Add initial `multiline`, `password`, and `checkbox` controls to both B4J presentations.
- [x] Add `multichoice` with string-list values and defensive copies.
- [x] Add ISO `date` values using B4J DatePicker and numeric `slider` controls to both presentations.
- [x] Verify date and slider editing and theme styling in both presentations (reported passing).
- [x] Add 24-hour `time` and timezone-free ISO `datetime` strings to both presentations.
- [x] Verify time/datetime editing and invalid-value errors in both presentations (reported passing).
- [x] Document current defaults and required/string-length validation.
- [x] Add required/minimum/maximum string-length checks to model and controller.
- [x] Add `label` (display-only) and `action` (callback button) non-value preferences to both presentations.
- [x] Verify label/action rendering, localization, and the `_Action` callback in both presentations (reported passing).
- [x] Validate that multichoice defaults and assigned values are unique selections from declared options.
- [x] Run GUI tests for multiline, password, checkbox, and multichoice controls (reported passing).
- [x] Verify scrollbar contrast in light/dark themes for dialog and page (reported passing).
- [x] Add `ResetToDefaults` / `ResetPreference` controller operations and facade accessors.
- [x] Add draft-reset Reset buttons to the dialog and page with localized status.
- [x] Verify dialog/page Reset behavior and localized validation messages (reported passing).

## M4 — Persistence and migrations — COMPLETE

- [x] Define a persistence adapter (`PrefsStore`) independent of controller state.
- [x] Implement map-backed storage with JSON import/export and save error handling.
- [x] Persist committed values after Save/commit, programmatic `SetValue`, and reset when a store is set.
- [x] Preserve unknown stored keys on save and skip unknown/invalid keys on load.
- [x] Expose `ExportValues` / `ImportValues` for JSON round-tripping.
- [x] Demonstrate file-backed restore across restart in the B4J demo.
- [x] Verify values restore after process restart (reported: `Restored 12 value(s)` and values reappear).
- [x] Document migration policy and confirm the demo store path is app-owned (`File.DirApp`).

## M5 — File and directory preferences — COMPLETE

- [x] Define `PrefsFileProvider` and a normalized `PrefsFileResult` selection model.
- [x] Implement B4J `FileChooser`/`DirectoryChooser` selection with extension filters.
- [x] Add `file` and `directory` types to the schema, model, controller, dialog, and page.
- [x] Implement cancel-preserves-value, optional Clear, and optional copy-to-app-storage.
- [x] Allow an application-supplied picker via `SetCustomHandler` (no mandatory MediaChooser dependency).
- [x] Document URI/path/access limitations and directory support.
- [x] Verify Browse/Clear and extension filtering in both presentations (reported: paths populated in dialog and page).
- [x] Verify copy-to-app-storage with a real selection (reported: picked file copied under `prefs-files`, stored path points at the copy).

## M6 — B4A and B4i adapters — IN PROGRESS

- [x] Establish supported toolchains: B4A 14.20 + Android SDK 36, B4i project format (Mac/hosted builder required).
- [x] Add shared, UI-free `PrefsSelfTest` (`RunAll` returns passed/failed/log).
- [x] Create a B4A validation project reusing the shared sources via `|relative|` module references.
- [x] Verify the shared modules compile on B4A with B4ABuilder (code, resources, and dex steps pass).
- [x] Run the B4A self-test on a device and report the `passed=`/`failed=` log (reported `passed=29 failed=0`).
- [x] Implement a B4A activity-form renderer (`PrefsRenderer`) for all types except file/directory pickers.
- [x] Run the B4A rendered form on a device and verify edit/Save/Cancel per control type (reported passing).
- [x] Implement the B4A file picker (`ContentChooser`, content-path values, optional copy to `File.DirInternal/prefs-files`).
- [x] Run the B4A file picker on a device (reported: Browse, copy to `prefs-files`, and Save commit verified).
- [x] Implement Android directory picking via a dependency-free `PrefsDirPicker` (persistable tree URIs, host-mediated callback).
- [x] Run the B4A directory picker on a device (reported: folder switching, tree-URI Save commit verified).
- [x] Persist B4A demo values with `PrefsStore` and verify full restart restore (reported `Restored 11 value(s)`).
- [ ] B4i project prepared but deferred (Mac/hosted builder required; revisit when builder access is available).
- [x] Implement B4A platform-specific form renderer and native picker behavior (dialog/page containers remain B4J-only).
- [x] Cast the public view API to `B4XView` (`CreatePage(Container As B4XView)`, B4J `PrefsPage.Initialize`, B4A `PrefsRenderer.Render`) so call sites are cross-platform.
- [x] Package the B4A modules (`PrefsRenderer`, `PrefsDirPicker`) under `B4A/` and ship the `XUI`/`jXUI` dependencies in `manifest.txt`.
- [x] Extend the B4XPages example to B4A (single shared `B4XMainPage` with `#If B4J`/`#If B4A` branches) and add a B4i project.
- [x] Start a capability matrix in the README; keep extending it as platforms are verified.
- [x] Collapse the B4XPages example's `AppHost` dispatcher and per-platform `PrefsHost` classes into the single shared `B4XMainPage` (B4J `Main` only initializes `B4XPagesManager` and shows the form; the page fetches the owner form with `B4XPages.GetNativeParent`).
- [x] Ship documented B4i stubs (`B4i/PrefsRenderer`, `B4i/PrefsDirPicker`) in the `.b4xlib` and make the B4i project a self-consistent self-test harness.

## M7 — Extensibility and release — IN PROGRESS

- [x] Evaluate XUI Views as replacement controls; defer adoption to the B4A/B4i port work (designer-oriented API, fragile class-instance event dispatch, dependency weight; see README).

- [x] Add the `custom` type to the schema, model (renderer name required), and controller (pass-through values, deep-cloned snapshots).
- [x] Add `RegisterCustomRenderer` with fail-fast handling of unregistered renderer names.
- [x] Implement the create/read/validate/refresh/dispose lifecycle in the B4J dialog renderer.
- [x] Implement the create/read/validate/refresh/dispose lifecycle in the B4J page renderer.
- [x] Demonstrate a custom rating renderer in the B4J demo and library-test example.
- [x] Verify the custom renderer GUI behavior (create, edit, invalid value, Save, Reset, language/theme refresh, dispose) in both presentations (reported passing).
- [x] Port the custom lifecycle (create/read/validate/dispose, fail-fast registration) to the B4A renderer with a matching rating sample.
- [x] Give the B4A demo the same two presentations as B4J: an inline hosted page plus a button-opened modal dialog overlay (sharing the controller, with its own renderer instance and Save/Cancel).
- [ ] Verify the B4A custom renderer on a device (render, edit, invalid value, Save, dispose).
- [ ] Finalize public APIs and callback contracts against each target compiler.
- [x] Package a distributable `.b4xlib` and verify integration from a fresh project.
- [ ] Complete automated/repeatable tests, platform examples, and release documentation.
