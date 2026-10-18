# B4XFlexibleDialog

Milestone 1 provides a B4J JSON-driven modal preferences dialog; Milestone 2 adds an embedded B4J page using the same model/controller. Milestone 3 is adding preference types and validation incrementally. Definitions and values remain independent of JavaFX controls. Current source supports `text`, `multiline`, `password`, `number`, `switch`, `checkbox`, `choice`, `multichoice`, `date`, `time`, `datetime`, `slider`, `file`, `directory`, `label`, `action`, and `custom` in the dialog and the embedded page, on B4J and B4A (B4i branches are stubs).

## Demo and build

Open `B4XFlexibleDialog/B4J/B4XFlexibleDialog.b4j` in B4J 10.7 or build from PowerShell:

```powershell
& 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
  -BaseFolder='C:\Projects\B4XFlexibleDialog\B4XFlexibleDialog\B4J' `
  -Project='C:\Projects\B4XFlexibleDialog\B4XFlexibleDialog\B4J\B4XFlexibleDialog.b4j' `
  -ShowWarnings=True
```

The sample project compiles to `B4XFlexibleDialog/B4J/Objects/B4XFlexibleDialog.jar`. On launch it loads `Files/settings.json`, reads `Files/en.json` and `Files/ms.json`, runs core model/controller assertions to the log, and presents buttons to open the dialog, switch language/theme, and mount/remove a settings page in a caller-owned host panel. Dialog and page share committed values. The selected language/theme is shown on the main form; theme changes affect the main form and current presentation. `Files/prefs.css` styles checkbox marks, choice/multichoice lists, slider track/thumbs, date-picker surfaces, and scrollbars using theme colors.

The modal dialog is capped at 600 DIP and scrolls its preference body when needed; Save/Cancel and status remain fixed at the bottom.

## Packaging (.b4xlib)

`dist/B4XFlexibleDialog.b4xlib` is a distributable B4J library built by `tools/package-b4xlib.ps1`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/package-b4xlib.ps1 -Version 0.2
```

`Version` must be a valid decimal (for example `0.2`, not `0.2.0`).

The archive contains the platform-independent modules at the root (`PrefsModel`, `PrefsController`, `PrefsLocalization`, `PrefsTheme`, `PrefsStore`, `PrefsFileResult`, `PrefsSelfTest`, `PrefsDialog`, `PrefsPage`, `PrefsFileProvider`, `B4XFlexibleDialog`), the B4A-specific modules under `B4A/` (`PrefsDirPicker`), the B4i-specific stub under `B4i/` (`PrefsDirPicker`), `Files/prefs.css`, and a `manifest.txt` declaring `B4J.DependsOn=Json, jXUI` and `B4A.DependsOn=Phone, XUI, JavaObject`. The dialog, page, file provider, and facade now ship as shared modules and branch per platform with `#If`; they avoid JavaFX types in their shared paths, and the public view API is `B4XView`-based (`Show`, `CreatePage(Container As B4XView)`) so the same source compiles on B4J and B4A alike.

To consume it in B4J, add `B4XFlexibleDialog.b4xlib` to the Libraries folder, reference the library in the project, and call `Prefs.Initialize` as shown above. This was verified by adding the packaged library to a fresh B4J project, copying the demo `Files\*`, and confirming it compiles and shows the dialog.

A ready-to-run consumer project is included at [`examples/B4XPagesDemo`](examples/B4XPagesDemo). Install the `.b4xlib`, open `B4J/B4XPagesDemo.b4j` (B4J) or `B4A/B4XPagesDemo.b4a` (B4A), and run; the B4J build lands in `examples/B4XPagesDemo/B4J/Objects/B4XPagesDemo.jar`, both with the library referenced as `b4xflexibledialog`. The shared `B4XMainPage` is the only module in the project: it drives the library through its cross-platform facade (a button opens the modal dialog; the same form is embedded inline in the page host) with platform differences handled by `#If` blocks in the one file. B4i reuses the same shared page, with the library's B4i facade/page branches and directory picker shipped as stubs for now (`B4i/README.md`).

### Verified dependencies

- B4J 10.7 / JavaFX (`jFX`, library key `jfx`)
- B4J core (`jCore`, library key `jcore`)
- B4J JSON (`Json`, library key `json`)
- No third-party libraries, external pickers, or persistence dependencies.

### XUI Views evaluation (not adopted)

XUI Views (`B4XSwitch`, `B4XComboBox`, `B4XPlusMinus`, …) was evaluated as a source
of replacement controls. It was deliberately not adopted, for these reasons:

- Its views are designer-oriented (`DesignerCreateView` with a `Props` map); our
  rows are built in code, so every adoption needs an emulation layer.
- Its events dispatch to a callback object, which is fragile from renderer
  class instances (the same class-instance dispatch that already ruled out a
  `CallSub`-based commit listener here).
- It would triple the dependency footprint (`XUI Views` plus transitives) for a
  largely cosmetic gain; the renderers are complete and verified as-is.
- The real payoff is cross-platform reuse. The right time is the B4A/B4i port
  work, adopting per view (starting with `B4XSwitch`, which would finally give
  the `switch` type a real toggle on all platforms) with on-device verification.

## Source modules

- `PrefsModel.bas`: JSON parsing and validation; preference metadata only.
- `PrefsController.bas`: defaults, typed values, draft state, validation, commit/cancel, snapshots; no UI types.
- `PrefsDialog.bas`: cross-platform modal form (B4J JavaFX widgets, B4A overlay of native controls, B4i stub).
- `PrefsPage.bas`: cross-platform embeddable page; adds/removes only its own scroll container in the supplied host `B4XView`.
- `PrefsLocalization.bas`: language dictionaries and missing-key fallback.
- `PrefsTheme.bas`: minimal light/dark colors and layout spacing.
- `PrefsStore.bas`: persistence adapter (map-backed with JSON import/export); preserves unknown stored keys.
- `PrefsFileProvider.bas`: file/directory picker abstraction; default B4J `FileChooser`/`DirectoryChooser` (non-B4J platforms call `SetCustomHandler`), optional custom handler, optional copy-to-app-storage.
- `PrefsFileResult.bas`: normalized selection result (success/cancelled, path, URI, display name, MIME type, access).
- `PrefsSelfTest.bas`: platform-independent core assertions (`RunAll` returns passed/failed/log); used by the B4A/B4i validation projects.
- `B4XFlexibleDialog.bas`: facade and callback forwarding.

## Platform support

| Area | B4J | B4A | B4i |
| --- | --- | --- | --- |
| Model, controller, localization, theme, store | Implemented and verified | Verified: `PrefsSelfTest` 29/29 `passed=` on device | Deferred (Mac/hosted builder required) |
| `.b4xlib` packaging | Implemented and verified | B4A modules packaged under `B4A/` (verified building the demo from the archive) | Not packaged |
| Modal dialog renderer | Implemented and verified | Cross-platform `PrefsDialog` overlay (compiles; on-device verification pending) | Not implemented (compiles as a stub) |
| Embedded page renderer | Implemented and verified | Cross-platform `PrefsPage` (compiles; on-device verification pending) | Not implemented (compiles as a stub) |
| File/directory picker | Implemented and verified (JavaFX choosers) | Both implemented and verified (`ContentChooser` + SAF picker; tree URIs persist) | Not implemented (see limitations) |
| Persistence | File-backed demo verified | Store API shared; app-owned path differs | Store API shared; app-owned path differs |

The B4A validation project at `B4XFlexibleDialog/B4A` references the shared modules with relative paths (`Module=|relative|..\B4J\...`) and runs `PrefsSelfTest` at startup, showing `passed=`/`failed=` plus the full log. It reported `passed=29 failed=0` on device. It builds with:

```powershell
& 'C:\Program Files\B4X\B4A\B4ABuilder.exe' -Task=Build `
  -BaseFolder='B4XFlexibleDialog\B4A' `
  -Project='B4XFlexibleDialog\B4A\B4XFlexibleDialog.b4a' `
  -ShowWarnings=True -NoSign=True
```

The B4J library project at `B4XFlexibleDialog/B4J` runs the same core assertions (`RunCoreChecks`, `RunStoreChecks`, `RunFacadeChecks`) at startup and logs `PASS:`/`FAIL:` lines. A headless run reports 51 passed, 0 failed.

B4A/B4i notes and limitations:

- The shared modules use only cross-platform keywords (`JSONParser`, `JSONGenerator`, `DateTime`, `Map`, `List`, `Asc`); no JavaFX references, so the same source compiles on B4A (verified) and is expected to compile on B4i (deferred).
- The cross-platform `PrefsDialog` (modal overlay) and `PrefsPage` (embedded `ScrollView`) render on B4A into native controls: `EditText` (text/number/multiline/password), `CheckBox` (switch/checkbox), `Spinner` (choice), per-item `CheckBox` rows (multichoice), `EditText` with ISO hints (date/time/datetime), `SeekBar` (slider), `Label` (label), and `Button` (action, fires `<prefix>_Action`). File/directory values render read-only. Save validates the full draft and commits atomically; Cancel discards. The B4A demo wires the same `Prefs_BeforeSave` / `Prefs_AfterSave` / `Prefs_Action` callbacks through the facade. Class instances live in activity `Globals`, not `Process_Globals`.
- On B4A, `file` preferences open a `ContentChooser` (Phone library) filtered by MIME derived from `options.extensions`, store the selected content path, and optionally copy into `File.DirInternal/prefs-files` when `copyToAppStorage` is set. Cancelling preserves the existing value. Content URIs carry no usable file name, so copied files are named from the URI tail (or the preference id) plus the first allowed extension, keeping extension validation meaningful. Failures surface as a form error instead of crashing. `directory` preferences open the system folder picker through the dependency-free `PrefsDirPicker` class (Storage Access Framework `OPEN_DOCUMENT_TREE` with persistable URI permissions); the stored value is the tree URI string, saved under `File.DirInternal` for reuse, and the host feeds it back via `Facade.SetDirectoryValue`. The demo wires `Prefs_BrowseDirectory` for this. iOS needs a document picker with security-scoped access (not implemented).
- `PrefsFileProvider`'s default pickers are B4J-only; on B4A/B4i the built-in selectors report that a custom handler is required (`SetCustomHandler`), so hosts supply their own picker (as the B4A `PrefsDirPicker` demo does for directories).
- File/directory values must be treated as opaque strings or URIs; `copyToAppStorage` on B4J copies into `File.DirApp\prefs-files`, which has no B4A/B4i equivalent yet.
- Persistence (`PrefsStore`) is platform code; only the storage location differs per platform (`File.DirApp` on B4J, `File.DirInternal` on B4A/B4i). The B4A demo saves committed values to `prefs-values.json` after each save and restores them at startup, so picked file paths and directory URIs survive restarts (directory access additionally relies on the persisted SAF grant).
- The B4i project at `B4XFlexibleDialog/B4i` is prepared but deferred: it cannot be compiled without a Mac/hosted builder.

Do not claim cross-platform completion until B4A and B4i examples are compiled and exercised.

## Definition JSON v1

See [`docs/schema-v1.json`](docs/schema-v1.json). Top-level fields are `schemaVersion` (must be `1`), `id`, optional `titleKey`, and `sections`. Each section has `id`, optional `titleKey`, and a `preferences` array. IDs use `[A-Za-z][A-Za-z0-9_.-]*`; preference IDs are unique across the full definition and section IDs are unique. Missing definition `titleKey` defaults to the definition ID; missing section `titleKey` defaults to its ID. Preference `titleKey` is required.

Supported preference contracts:

| Type | Value/default | Options and behavior |
| --- | --- | --- |
| `text` | String; omitted default becomes `""` | No extra options. |
| `multiline` | String; omitted default becomes `""` | Wrapped multi-line editor. |
| `password` | String; omitted default becomes `""` | Masked B4J password field; values are still in-memory plaintext. |
| `number` | Numeric; omitted default becomes `0` | Optional numeric `options.min` and `options.max`; bounds must be ordered and contain the default and saved value. |
| `switch` | Boolean; omitted default becomes `false` | No extra options. |
| `checkbox` | Boolean; omitted default becomes `false` | B4J checkbox control; visually the same native control as `switch` for now. |
| `choice` | String matching an item `value`; default required | `options.items` is a non-empty array of `{ "value": string, "titleKey": string }`; duplicate item values are rejected. |
| `multichoice` | List of strings matching item `value`s; omitted default becomes an empty list | Same `options.items` format as `choice`; selection is through a multi-select ListView (use platform selection gestures such as Ctrl-click on desktop). |
| `date` | ISO date string `yyyy-MM-dd`; omitted default becomes `""` | Uses B4J DatePicker. Empty is allowed unless `required: true`; calendar-invalid dates are rejected. |
| `time` | String `HH:mm` (24-hour); omitted default becomes `""` | Valid range is 00:00–23:59. |
| `datetime` | String `yyyy-MM-dd'T'HH:mm`; omitted default becomes `""` | ISO date plus 24-hour time; no timezone is implied. |
| `slider` | Numeric; omitted default becomes `options.min` or `0` | Optional numeric `options.min` / `options.max`; defaults to 0–100 if omitted. |
| `file` | String path or URI; omitted default becomes `""` | Browse button uses `PrefsFileProvider`. Options: `extensions` (allowed list), `allowClear`, `copyToAppStorage`, `preview` (reserved), `title`, `initialDirectory`. Non-empty values must match `extensions` when present. |
| `directory` | String path or URI; omitted default becomes `""` | Browse button uses the directory picker. Options: `allowClear`, `copyToAppStorage` (reserved), `title`, `initialDirectory`. |
| `label` | No stored value | Display-only text. Uses `descriptionKey` when present, otherwise `titleKey`. It is excluded from value maps. |
| `action` | No stored value | Renders a button; activation calls the `<prefix>_Action(PreferenceId)` callback. It is excluded from value maps. |
| `custom` | Any JSON value; omitted default becomes `""` | Rendered by an application-registered renderer named in `options.renderer` (required). Values pass through the controller untouched; the renderer validates at Save. |

`file`/`directory` values are stored as strings. On B4J the default provider returns an absolute filesystem path and a `file://` URI; other platforms must not assume a permanent path, so the normalized `PrefsFileResult` carries path, URI, display name, MIME type, and an access descriptor. Cancelling the picker preserves the existing value. `SetFileProvider` lets an application supply its own picker via `SetCustomHandler(Target, FileSub, DirectorySub)`, where each sub takes the options `Map` and returns a `PrefsFileResult`; `CopyToAppStorage` copies a selection into `File.DirApp\prefs-files`.

`label` and `action` are non-value preferences; they are not stored in committed/draft maps, and `SetValue` rejects them. `defaultValue` is optional for text, multiline, password, number, switch, checkbox, multichoice, date, time, datetime, and slider (defaults above), and required for choice. String preferences support optional root fields `required`, `minLength`, and `maxLength`; empty required strings and values outside length bounds fail validation. Date values use ISO `yyyy-MM-dd` strings and are converted to/from B4J DatePicker ticks only at the UI boundary. Time/datetime are timezone-free wall-clock values. Multichoice values are copied when read/written to keep snapshots independent. Unknown schema versions, duplicate IDs, unsupported types, type mismatches, invalid choice defaults, malformed JSON, and invalid bounds are rejected with `LastError`.

## Public API (cross-platform)

The facade is the same on every platform; `Owner` is the B4J `Form`, the B4A `Activity`, or the B4i `Page`.

```vb
Prefs.Initialize(Me, "Prefs", MainForm)
Prefs.SetDictionary("en", EnglishMap)
Prefs.SetDictionary("ms", MalayMap)
Prefs.SetLanguage("en")
Dim Lang As String = Prefs.GetLanguage
Prefs.SetTheme(Prefs.CreateLightTheme) ' Or CreateDarkTheme
Dim Theme As PrefsTheme = Prefs.GetTheme ' Active theme object (same instance the dialog mutates)
Dim Dark As Boolean = Prefs.IsDarkTheme
If Prefs.LoadDefinition(DefinitionJson) = False Then Log(Prefs.LastError)

Prefs.SetValue("username", "Aeric") ' Boolean result; LastError on failure
Dim Value As Object = Prefs.GetValue("username")
Dim Values As Map = Prefs.GetValues ' Copy/snapshot
Prefs.ResetToDefaults ' Restores every value preference to its default
Prefs.ResetPreference("username") ' Restores one value preference to its default

' Custom renderers and file/directory providers
Prefs.RegisterCustomRenderer("RatingStars", Me, "Rating") ' See custom renderers below
Dim Renderer As Map = Prefs.GetCustomRenderer("RatingStars")
Prefs.SetFileProvider(MyProvider) ' Optional; replaces the default picker
Dim Provider As PrefsFileProvider = Prefs.GetFileProvider
Prefs.SetDirectoryValue(Uri) ' Feeds a host-picked directory value back to the dialog/page

' Persistence
Dim Store As PrefsStore
Store.Initialize
Prefs.SetStore(Store) ' Writes committed values to the store after every commit/set/reset
Dim Current As PrefsStore = Prefs.GetStore
Dim Applied As Int = Prefs.LoadStoredValues ' Restores stored values for known value preferences
Prefs.SaveStoredValues ' Writes committed values into the store (no JSON round-trip)
Dim Json As String = Prefs.ExportValues ' Save committed values into the store and return a JSON snapshot
Dim Imported As Int = Prefs.ImportValues(Json) ' Parse JSON into the store, then apply matching values

' Presentations
Prefs.Show ' Modal dialog: blocking on B4J, async overlay on B4A
Prefs.CreatePage(MainForm.RootPane) ' Anchors a page in this caller-owned B4XView container
Prefs.RefreshPage ' Rebuilds visible values from committed state
Prefs.DisposePage ' Removes only the library-owned page node
```

Every name above is a public sub on the facade and is the finalized API for this release, compiled and verified against B4JBuilder 10.70 and B4ABuilder 14.20. `Owner` is the B4J `Form`, the B4A `Activity`, or the B4i `Page`; `EventTarget`/`EventName` select the callback module and `<prefix>_*` subs. Getters (`GetLanguage`, `IsDarkTheme`, `GetTheme`, `GetValues`, `GetStore`, `GetFileProvider`, `GetCustomRenderer`) are read-only accessors.

`SetValue` validates IDs, types, choice membership, string constraints, and number bounds; failed sets do not modify values. `GetValues` returns a copied map and deep-clones list/map values. `ResetToDefaults` and `ResetPreference` operate on committed values for value preferences and are excluded from change events (no change event exists in this milestone). `custom` values pass controller validation untouched; the registered renderer validates them at Save.

## Custom preference renderers (Milestone 7)

Register a renderer for each `options.renderer` name used by `custom` preferences:

```vb
Prefs.RegisterCustomRenderer("RatingStars", Me, "Rating")
```

The target must be a module (the app); class instances are not supported as the target. The library calls these lifecycle subs, where `<E>` is the event name:

- `<E>_Create(Args As Map) As Object` — `Args` holds `parent` (the content pane), `left`, `top`, `width`, `height`, `definition` (the preference map), and `value` (the current value). Build the control inside the given rectangle and return a handle (any object) that is passed back to the other callbacks.
- `<E>_Read(Handle As Object, Definition As Map) As Object` — return the current value from the control.
- `<E>_Validate(Value As Object, Definition As Map) As String` — return `""` when valid, otherwise an error message shown next to the preference id. Runs at Save before the draft is committed.
- `<E>_Refresh(Handle As Object, Args As Map)` — update the control from `Args` (`definition`, `value`). Called on language/theme change and on Reset.
- `<E>_Dispose(Handle As Object)` — release resources when the dialog closes or the page is disposed. Views owned by the content pane die with it, so removing them is optional but harmless.

Showing a dialog or page with an unregistered renderer name fails fast: Save is blocked with `No custom renderer registered for preference <id>`, and the message is logged. The demo registers a 1–5 star rating renderer (`Rating_*` subs in the demo Main) used by the `satisfaction` preference in both presentations. The sample paints its buttons from `Prefs.GetTheme` colors, so it follows light/dark switches including the in-dialog theme toggle.

The cross-platform dialog and page implement the same custom lifecycle (create/read/validate/refresh/dispose with fail-fast on unregistered names) via `Facade.RegisterCustomRenderer`; the B4A demo registers the same 1–5 rating sample. On-device verification is pending.

## Persistence (Milestone 4)

`PrefsStore` is a map-backed adapter independent of the controller. `Prefs.SetStore(Store)` enables persistence: after a successful Save/commit, a programmatic `SetValue`, or a reset, the facade writes the committed value map into the store. The store merges those values into its stored map, so **unknown stored keys are preserved** rather than deleted. `LoadStoredValues` applies only known value preferences; unknown keys and invalid values are skipped, leaving defaults in place. `ExportValues`/`ImportValues` provide JSON round-tripping for backup or transfer.

The library does not choose or own the storage location. The demo writes `Store.ToJson` to `File.DirApp\prefs-store.json` after each save and loads it at startup to restore values across restarts. Stored-value migration is intentionally application-defined and kept separate from the library version; the store exposes `SetSchemaVersion`/`GetSchemaVersion` for an application to track its own schema, and preserves unknown keys so migrations can read legacy data. `Show` creates draft values from the committed map. Save reads all controls, validates the complete draft, calls `BeforeSave`, commits only if accepted, then calls `AfterSave`. Cancel and the window close button discard the draft. The dialog and page Reset buttons load each value preference's default into the current draft and refresh the visible controls; Save then commits them, or Cancel discards. Save and Cancel are mutually exclusive outcomes. Reopening after Save shows the committed in-memory values.

`CreatePage` accepts a B4J `AnchorPane` and mounts a scrollable page without clearing or owning the caller's other nodes/navigation. Page Save commits and leaves the page mounted; page Cancel discards current edits and reloads committed values. Programmatic `SetValue`, language changes, and theme changes refresh the visible page. `RefreshPage` discards uncommitted page edits and reloads committed values. Opening the modal dialog while a page is mounted also resets the page draft to committed values; after the dialog closes, the page refreshes from the resulting committed state. Save before switching presentations if edits should be kept.

Implement all three callback subs on the object passed to `Initialize` (the demo uses event prefix `Prefs`):

```vb
Private Sub Prefs_BeforeSave(Values As Map) As Boolean
    Return True ' Return False to keep the dialog open and reject the commit.
End Sub

Private Sub Prefs_AfterSave(Values As Map)
End Sub

Private Sub Prefs_DialogClosed(WasSaved As Boolean)
End Sub

Private Sub Prefs_Action(PreferenceId As String)
End Sub
```

Callbacks use B4J `CallSub` / `CallSub2`; the before-save callback must return Boolean. It receives the complete candidate map before commit; AfterSave receives the committed snapshot. The three save/close callbacks are required; `Prefs_Action` is only invoked when an `action` preference button is pressed, so it is required only if the definition contains an `action` preference.

`SetLanguage` resolves keys against the selected dictionary; an unknown key falls back to the key itself. The dialog's Language button toggles English/Malay and refreshes visible labels, including choice titles, without touching values. `SetTheme` accepts a theme from `CreateLightTheme` or `CreateDarkTheme`; the demo also toggles theme while the dialog is closed. The dialog's Theme button changes its live background/text/button colors. Colors are 32-bit ARGB integers. Refreshes do not raise preference value-change callbacks (there is no change event in this milestone).

## Building and testing

Build the library on each target compiler:

```powershell
# B4J library
& 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
  -BaseFolder='B4XFlexibleDialog\B4J' `
  -Project='B4XFlexibleDialog\B4J\B4XFlexibleDialog.b4j' -ShowWarnings=True

# B4A library (absolute -BaseFolder; unsigned)
& 'C:\Program Files\B4X\B4A\B4ABuilder.exe' -Task=Build `
  -BaseFolder='C:\Projects\B4XFlexibleDialog\B4XFlexibleDialog\B4A' `
  -Project='B4XFlexibleDialog\B4A\B4XFlexibleDialog.b4a' -ShowWarnings=True -NoSign=True
```

Run the repeatable tests (builds the B4J harness and runs its assertions headlessly):

```powershell
powershell -File tools\run-b4j-tests.ps1
```

It exits non-zero if any `FAIL:` line appears or the shared self-test reports a non-zero failed count. The B4J library project runs both the shared, UI-free `PrefsSelfTest` (the same suite the B4A/B4i validation projects use, 29 checks) and its own inline core/store/facade assertions.

The B4A validation project at `B4XFlexibleDialog/B4A` runs `PrefsSelfTest` at startup and shows `passed=`/`failed=` plus the full log. The B4i project is prepared in the same shape and is deferred until Mac/hosted builder access is available.

Package the distributable:

```powershell
powershell -File tools\package-b4xlib.ps1 -Version 0.2
```

## Test checklist and results

| Check | Result |
| --- | --- |
| B4JBuilder 10.70 build, warnings enabled | **PASS** |
| JSON syntax for schema, demo definition, and both locale files | **PASS** |
| Demo jar contains `Files/settings.json`, `Files/en.json`, and `Files/ms.json` | **PASS** |
| Core runtime assertions (model validation, supported values, string/number/date/time/selection constraints, scalar and list snapshots, draft cancel/commit) | **Included; run in demo on startup** |
| Shared `PrefsSelfTest` on B4J | **PASS** (29 passed, 0 failed, headless) |
| B4J assertion harness (`RunCoreChecks`/`RunStoreChecks`/`RunFacadeChecks` + self-test) | **PASS** (80 passed, 0 failed, headless) |
| Repeatable runner `tools/run-b4j-tests.ps1` | **PASS** (builds + runs headlessly, exits 0) |
| Public API and callback contracts compiled against B4JBuilder 10.70 and B4ABuilder 14.20 | **PASS** (both build clean) |
| All implemented controls render and edit | **PASS** (reported GUI test) |
| Save commits; Cancel and window close discard edits | **PASS** (reported GUI test) |
| Invalid numbers (out-of-range and non-numeric text) block Save | **PASS** (reported GUI test) |
| In-dialog language/theme switching preserves values | **PASS** (reported GUI test) |
| Dark/light scrollbar contrast in dialog and page | **PASS** (reported GUI test) |
| Programmatic `ResetToDefaults` / `ResetPreference` restore defaults | **PASS** (reported demo run) |
| Dialog/page Reset button loads defaults into the draft | **PASS** (reported GUI test) |
| Label/action rendering, localization, and `_Action` callback | **PASS** (reported GUI test) |
| Store merge, unknown-key preservation, JSON round-trip, and `ApplyValues` | **PASS** (reported demo run) |
| `file`/`directory` validation (empty optional, allowed/disallowed extension, directory path) | **Included; run in demo on startup** |
| File/directory Browse/Clear and extension filtering in dialog and page | **PASS** (reported GUI test) |
| Copy-to-app-storage | **PASS** (reported: picked file copied under `prefs-files`, stored path points at the copy) |
| Values restored after application restart | **PASS** (B4J reported `Restored 12 value(s)`; B4A reported `Restored 11 value(s)` after relaunch) |
| Packaged `.b4xlib` compiles and runs from a fresh B4J project | **PASS** (reported) |
| `custom` definition validation (missing options/renderer rejected) | **Included; run in demo on startup** |
| Custom renderer lifecycle (create/read/validate/refresh/dispose) in dialog and page | **PASS** (reported GUI test) |
| Reopen after Save preserves values in memory | **PASS** (reported GUI test) |
| B4J page renderer compiles and shares the model/controller API | **PASS** (build verified) |
| Page mounting/resizing, Save/Cancel, repeated dispose/remount, localization/theme refresh | **PASS** (reported GUI test) |
| Multiline/password/checkbox/multichoice/date/time/datetime/slider controls and validation | **PASS** (reported GUI test) |
| Modal dialog sizing at 600 DIP | **PASS** (reported GUI test) |
| Values survive application reboot | **Supported via `PrefsStore`** (see Persistence) |

The project was build-verified with B4JBuilder 10.70 and Java 19 selected by the builder. Milestones 1–3 GUI results above were reported from demo runs. The library stores committed values in memory; the demo persists them through `PrefsStore` (see Persistence) so they survive restarts.

## Deferred beyond current scope

B4i implementation (the B4i facade/page branches and the directory picker are stubs; a Mac/hosted builder is required to verify), on-device verification of the B4A dialog/page, immediate-save mode, conditional display, advanced validators, advanced styling, and automated GUI testing.
