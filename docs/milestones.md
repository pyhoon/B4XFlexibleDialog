# B4XFlexibleDialog Milestones

The library is being developed incrementally. Planned features below are not claims of current platform support. Current implementation status is summarized in [`TODO.md`](TODO.md) and [`README.md`](../README.md).

## Product direction

Build a reusable JSON-first preferences framework with definitions independent of values, localization, presentation, and persistence. Keep controller/model logic independent of UI controls; isolate platform renderers and file providers. Validate each B4X platform separately.

## M0 — Definition contract and B4J model — complete

Version-1 JSON schema and B4J parser/validator for the initial four preference types. The model checks required fields, IDs, duplicate IDs, supported types, defaults, number bounds, and choice items. The source and demo JSON are included.

## M1 — B4J core and basic preferences dialog — complete

Implemented and manually exercised in the B4J demo:

- `text`, `number`, `switch`, and `choice` controls.
- Controller-owned committed values and draft values; validate before Save/commit; Cancel and window close discard edits.
- Programmatic typed get/set and `GetValues` snapshots.
- Before-save, after-save, and dialog-closed callbacks.
- English/Malay runtime localization and basic light/dark theme.
- Demo/core assertions and API/schema documentation.

This milestone has in-memory state only. Values surviving dialog close/reopen is supported; restoration after application restart is intentionally not supported yet.

## M2 — B4J full-page renderer — complete

The B4J `PrefsPage` mounts in a caller-provided `AnchorPane`, keeps caller navigation and unrelated children intact, and shares the model/controller with the modal dialog. It supports the same four controls and explicit Save/Cancel semantics; the demo has a mount/remove page action. Programmatic values and language/theme changes refresh the mounted view. It compiled with B4JBuilder 10.70 and interactive page sizing, scrolling, save/cancel, theme/language refresh, and repeated mount/dispose checks were reported passing.

## M3 — Additional preference types and validation — complete

The B4J model/controller and both renderers include multiline, password, checkbox, multichoice, date, time, datetime, slider, label, and action alongside text, number, switch, and choice. Dates use ISO `yyyy-MM-dd` strings; time/datetime use timezone-free 24-hour strings; sliders use numeric min/max values. `label` and `action` are non-value preferences excluded from value maps; actions raise the `<prefix>_Action` callback. Required/minLength/maxLength string validation and defensive multichoice list values are implemented. `ResetToDefaults` and `ResetPreference` value operations and draft-reset Reset buttons are implemented in both presentations. All controls and behaviors are build-verified and were reported passing in the demo, including label/action localization, the action callback, and Reset semantics. `file`, `directory`, and `custom` remain in later milestones (M5/M7).

## M4 — Persistence and migrations — complete

`PrefsStore` provides map-backed persistence with JSON import/export, independent of controller state. When a store is set, committed values persist after Save/commit, programmatic `SetValue`, and reset. Saving merges committed values into the stored map so unknown keys are preserved; loading applies only known, valid value preferences. `ExportValues`/`ImportValues` support JSON round-tripping, and the store exposes its own schema version separately from library versioning. The B4J demo persists to an application-owned file under `File.DirApp` and restores it at startup; a full close-and-relaunch restored the saved values (`Restored 12 value(s)`).

## M5 — File and directory preferences — complete

`PrefsFileProvider` defines the picker contract and `PrefsFileResult` normalizes selections (success/cancelled, path, URI, display name, MIME type, access). The B4J implementation uses JavaFX `FileChooser`/`DirectoryChooser` with optional extension filters; applications may supply their own picker via `SetCustomHandler`, so no external picker is mandatory. `file` and `directory` preference types are integrated into the schema, model, controller, and both presentations, with cancel-preserves-value, optional Clear, and optional copy-to-app-storage. URI/path/access limitations are documented. Browse/Clear and extension filtering were verified in both presentations. Copy-to-app-storage is implemented but was not exercised because the demo definition disables it.

## M6 — B4A and B4i adapters — in progress

The shared modules (`PrefsModel`, `PrefsController`, `PrefsLocalization`, `PrefsTheme`, `PrefsStore`, `PrefsFileResult`) avoid JavaFX and compile unchanged on B4A (verified with B4ABuilder 14.20 through code, resource, and dex steps). A `PrefsSelfTest` class runs the core assertions without any UI, and a minimal B4A project reuses the same sources via relative module references and displays the result at startup. The B4i project is prepared in the same shape but cannot be compiled without a Mac/hosted builder. Dialog/page renderers and native pickers remain B4J-only; see the README capability matrix. Do not claim cross-platform completion until B4A and B4i examples are compiled and exercised.

## M7 — Extensibility and release

Finalize custom renderer lifecycle, API compatibility, platform capability documentation, fresh-project integration, and distributable `.b4xlib` packaging.
