# Changelog

## Unreleased — cross-platform port

- Made the facade `B4XFlexibleDialog` cross-platform: `Show` drives `PrefsDialog` on B4J (blocking) and B4A (async overlay) and fires exactly one `_DialogClosed`; `CreatePage`/`RefreshPage`/`DisposePage` work on B4J+B4A; added `SetDirectoryValue` for host-driven directory picks.
- Rewrote `PrefsDialog` with B4J/B4A/B4i branches so the modal dialog runs on B4A (previously B4J-only); first pass at the shared `MultiValues` state, per-slider min/max, and `B4XView`-based overlay teardown.
- Added a cross-platform `PrefsPage` (B4J JavaFX scroll pane; B4A `ScrollView` of native controls; B4i stub) so `CreatePage` works on B4A.
- Guarded `PrefsFileProvider`'s B4J `FileChooser`/`DirectoryChooser` behind `#If B4J`; non-B4J callers now get a clear "call `SetCustomHandler`" failure.
- Retired the separate B4A `PrefsRenderer` (and its B4i stub) in favour of the shared dialog/page; updated the `.b4xlib` packaging so `PrefsDialog`, `PrefsPage`, `PrefsFileProvider`, and the facade ship as shared modules.
- Reworked the shared demo `B4XMainPage` to drive the library through the facade on every platform (drops the hand-built B4A overlay and Save/Cancel chrome).

## Unreleased — Milestone 3 progress

- Added `multiline`, `password`, and `checkbox` to the B4J model, dialog, page, and demo.
- Added `required`, `minLength`, and `maxLength` string validation to the version-1 schema, model, and controller.
- Added multi-select ListView preferences with list-value snapshot copying.
- Added ISO date preferences using B4J DatePicker and numeric slider preferences.
- Added validated `HH:mm` time and timezone-free `yyyy-MM-dd'T'HH:mm` datetime preferences.
- Added non-value `label` and `action` preferences; action buttons raise a `<prefix>_Action` callback.
- Added `ResetToDefaults` / `ResetPreference` value operations and draft-reset Reset buttons in both presentations.
- Added `PrefsStore` persistence: map-backed storage, JSON import/export, unknown-key preservation, and auto-persist after commit/set/reset.
- Added the `custom` preference type with `RegisterCustomRenderer` and a create/read/validate/refresh/dispose lifecycle in both B4J presentations, plus a sample rating renderer.
- Added `GetTheme` so custom renderers can follow the active theme; the sample rating buttons use theme accent/button colors.
- Ported the custom renderer contract to the B4A renderer (create/read/validate/dispose, fail-fast registration) with a matching rating sample (on-device verification pending).
- Added `file` and `directory` preference types with a `PrefsFileProvider`/`PrefsFileResult` picker abstraction, extension filters, optional Clear, and optional copy-to-app-storage.
- Added a shared `PrefsSelfTest` class and B4A/B4i validation projects; the B4A project reuses the shared sources and compiles with B4ABuilder (runtime self-test pending on device).
- Added a B4A activity-form renderer (`PrefsRenderer`) with the same controller Save/Cancel semantics; compiles with B4ABuilder (on-device verification pending).
- Added B4A `file` selection via `ContentChooser` with MIME filtering and optional copy to app-internal storage (on-device verification pending); directory picking remains unimplemented.
- Added B4A `directory` selection via `ExternalStorage` with persistable tree URIs (on-device verification pending).
- Replaced the B4A directory flow with a dependency-free `PrefsDirPicker` (SAF tree URIs, no `DocumentFile` requirement) after `ExternalStorage` crashed on a missing legacy class.
- Added a `.b4xlib` packaging script and generated `dist/B4XFlexibleDialog.b4xlib` (shared modules at root, B4J modules under `B4J/`).
- Added startup assertions for the new value types and validation cases.
- Cast the public view API to `B4XView` and added a B4A B4XPages example; later collapsed the example's `AppHost` dispatcher and per-platform `PrefsHost` classes into the single shared `B4XMainPage`.
- Set the B4J manifest dependency to `Json, jXUI` and the B4A one to `Phone, XUI, JavaObject` (dropped `jFX`/`Core`).
- Added documented B4i stubs (`B4i/PrefsRenderer`, `B4i/PrefsDirPicker`), shipped them in the `.b4xlib` under `B4i/`, and made the B4i project a self-consistent self-test harness.

## 0.1.0 — Milestone 1 foundation

- Added the B4J JSON definition model, committed/draft controller, four basic controls, modal Save/Cancel flow, runtime language dictionaries, and light/dark theme.
- Defined JSON schema version 1 and a runnable four-control demo.
- Initialize themes through `PrefsTheme.Initialize(Dark As Boolean)` and show the current demo language/theme state visibly.
- No cross-platform API is claimed as implemented.
