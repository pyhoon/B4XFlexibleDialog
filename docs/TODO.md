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

## M3 — Additional preference types and validation — IN PROGRESS

- [x] Add initial `multiline`, `password`, and `checkbox` controls to both B4J presentations.
- [x] Add `multichoice` with string-list values and defensive copies.
- [x] Add ISO `date` values using B4J DatePicker and numeric `slider` controls to both presentations.
- [x] Verify date and slider editing and theme styling in both presentations (reported passing).
- [x] Document current defaults and required/string-length validation.
- [x] Add required/minimum/maximum string-length checks to model and controller.
- [ ] Continue with time/datetime, label, and action.
- [x] Validate that multichoice defaults and assigned values are unique selections from declared options.
- [x] Run GUI tests for multiline, password, checkbox, and multichoice controls (reported passing).
- [ ] Add Reset and localized validation feedback.

## M4 — Persistence and migrations

- [ ] Define a pluggable persistence adapter independent of controller state.
- [ ] Implement map and JSON storage adapters with clear save/error semantics.
- [ ] Verify values restore after process restart.
- [ ] Preserve unknown stored keys and define schema migration policy separately from library versioning.

## M5 — File and directory preferences

- [ ] Define `PrefsFileProvider` and a normalized selection result model.
- [ ] Verify JavaFX file chooser behavior for B4J; keep media-picker dependencies optional.
- [ ] Implement filters, cancel preservation, clear behavior, and optional app-managed copying.
- [ ] Document URI/path/access limitations and directory support.

## M6 — B4A and B4i adapters

- [ ] Establish supported B4A/B4i toolchains and compile environments.
- [ ] Port model/controller/localization/theme semantics.
- [ ] Implement platform-specific dialog/page renderers and native picker behavior.
- [ ] Verify each platform with runnable examples and maintain a capability matrix.

## M7 — Extensibility and release

- [ ] Define custom-renderer registration and lifecycle.
- [ ] Finalize public APIs and callback contracts against each target compiler.
- [ ] Package a distributable `.b4xlib` and verify integration from a fresh project.
- [ ] Complete automated/repeatable tests, platform examples, and release documentation.
