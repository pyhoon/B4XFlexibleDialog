# B4XFlexibleDialog

Milestone 1 provides a B4J JSON-driven modal preferences dialog; Milestone 2 adds an embedded B4J page using the same model/controller. Milestone 3 is adding preference types and validation incrementally. Definitions and values remain independent of JavaFX controls. Current source supports `text`, `multiline`, `password`, `number`, `switch`, `checkbox`, `choice`, `multichoice`, `date`, `time`, `datetime`, `slider`, `label`, and `action` in both B4J presentations.

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

The archive contains the platform-independent modules at the root (`PrefsModel`, `PrefsController`, `PrefsLocalization`, `PrefsTheme`, `PrefsStore`, `PrefsFileResult`, `PrefsSelfTest`), the B4J-specific modules under `B4J/` (`B4XFlexibleDialog`, `PrefsDialog`, `PrefsPage`, `PrefsFileProvider`), `Files/prefs.css`, and a `manifest.txt` declaring `B4J.DependsOn=jFX, Json`. Shared modules intentionally avoid JavaFX so they can be reused by future platform ports.

To consume it in B4J, add `B4XFlexibleDialog.b4xlib` to the Libraries folder, reference the library in the project, and call `Prefs.Initialize` as shown above. This was verified by adding the packaged library to a fresh B4J project, copying the demo `Files\*`, and confirming it compiles and shows the dialog.

A ready-to-run consumer project is included at [`examples/B4JLibraryTest`](examples/B4JLibraryTest). Install the `.b4xlib`, open `B4JLibraryTest.b4j`, and run; it builds to `examples/B4JLibraryTest/Objects/B4JLibraryTest.jar` with the library referenced as `b4xflexibledialog`.

### Verified dependencies

- B4J 10.7 / JavaFX (`jFX`, library key `jfx`)
- B4J core (`jCore`, library key `jcore`)
- B4J JSON (`Json`, library key `json`)
- No third-party libraries, external pickers, or persistence dependencies.

## Source modules

- `PrefsModel.bas`: JSON parsing and validation; preference metadata only.
- `PrefsController.bas`: defaults, typed values, draft state, validation, commit/cancel, snapshots; no UI types.
- `PrefsDialog.bas`: B4J JavaFX form and control rendering.
- `PrefsPage.bas`: B4J embedded page renderer; adds/removes only its own scroll pane in the supplied `AnchorPane`.
- `PrefsLocalization.bas`: language dictionaries and missing-key fallback.
- `PrefsTheme.bas`: minimal light/dark colors and layout spacing.
- `PrefsStore.bas`: persistence adapter (map-backed with JSON import/export); preserves unknown stored keys.
- `PrefsFileProvider.bas`: file/directory picker abstraction; default B4J `FileChooser`/`DirectoryChooser`, optional custom handler, optional copy-to-app-storage.
- `PrefsFileResult.bas`: normalized selection result (success/cancelled, path, URI, display name, MIME type, access).
- `PrefsSelfTest.bas`: platform-independent core assertions (`RunAll` returns passed/failed/log); used by the B4A/B4i validation projects.
- `B4XFlexibleDialog.bas`: facade and callback forwarding.

## Platform support

| Area | B4J | B4A | B4i |
| --- | --- | --- | --- |
| Model, controller, localization, theme, store | Implemented and verified | Verified: `PrefsSelfTest` 29/29 `passed=` on device | Deferred (Mac/hosted builder required) |
| `.b4xlib` packaging | Implemented and verified | Not packaged | Not packaged |
| Modal dialog renderer | Implemented and verified | Implemented (`PrefsRenderer` activity form); on-device verification pending | Not implemented |
| Embedded page renderer | Implemented and verified | Covered by the same activity form; dedicated page container pending | Not implemented |
| File/directory picker | Implemented and verified (JavaFX choosers) | Not implemented (values render read-only; see limitations) | Not implemented (see limitations) |
| Persistence | File-backed demo verified | Store API shared; app-owned path differs | Store API shared; app-owned path differs |

The B4A validation project at `B4XFlexibleDialog/B4A` references the shared modules with relative paths (`Module=|relative|..\B4J\...`) and runs `PrefsSelfTest` at startup, showing `passed=`/`failed=` plus the full log. It reported `passed=29 failed=0` on device. It builds with:

```powershell
& 'C:\Program Files\B4X\B4A\B4ABuilder.exe' -Task=Build `
  -BaseFolder='B4XFlexibleDialog\B4A' `
  -Project='B4XFlexibleDialog\B4A\B4XFlexibleDialog.b4a' `
  -ShowWarnings=True -NoSign=True
```

B4A/B4i notes and limitations:

- The shared modules use only cross-platform keywords (`JSONParser`, `JSONGenerator`, `DateTime`, `Map`, `List`, `Asc`); no JavaFX references, so the same source compiles on B4A (verified) and is expected to compile on B4i (deferred).
- The B4A `PrefsRenderer` class renders into a host `Panel` with a `ScrollView`: `EditText` (text/number/multiline/password), `CheckBox` (switch/checkbox), `Spinner` (choice), per-item `CheckBox` rows (multichoice), `EditText` with ISO hints (date/time/datetime), `SeekBar` (slider), `Label` (label), and `Button` (action, fires `<prefix>_Action`). File/directory values render read-only. Save validates the full draft and commits atomically; Cancel discards. The B4A demo wires the same `Prefs_BeforeSave` / `Prefs_AfterSave` / `Prefs_Action` callbacks. Class instances live in activity `Globals`, not `Process_Globals`.
- The B4J-only `PrefsFileProvider` and `PrefsDialog`/`PrefsPage` renderers remain. Android needs a Storage Access Framework / `ContentChooser` picker returning content URIs (no permanent path); iOS needs a document picker with security-scoped access. Neither is implemented.
- File/directory values must be treated as opaque strings or URIs; `copyToAppStorage` on B4J copies into `File.DirApp\prefs-files`, which has no B4A/B4i equivalent yet.
- Persistence (`PrefsStore`) is platform code; only the storage location differs per platform (`File.DirApp` on B4J, app-internal dirs on B4A/B4i).
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

`file`/`directory` values are stored as strings. On B4J the default provider returns an absolute filesystem path and a `file://` URI; other platforms must not assume a permanent path, so the normalized `PrefsFileResult` carries path, URI, display name, MIME type, and an access descriptor. Cancelling the picker preserves the existing value. `SetFileProvider` lets an application supply its own picker via `SetCustomHandler(Target, FileSub, DirectorySub)`, where each sub takes the options `Map` and returns a `PrefsFileResult`; `CopyToAppStorage` copies a selection into `File.DirApp\prefs-files`.

`label` and `action` are non-value preferences; they are not stored in committed/draft maps, and `SetValue` rejects them. `defaultValue` is optional for text, multiline, password, number, switch, checkbox, multichoice, date, time, datetime, and slider (defaults above), and required for choice. String preferences support optional root fields `required`, `minLength`, and `maxLength`; empty required strings and values outside length bounds fail validation. Date values use ISO `yyyy-MM-dd` strings and are converted to/from B4J DatePicker ticks only at the UI boundary. Time/datetime are timezone-free wall-clock values. Multichoice values are copied when read/written to keep snapshots independent. Unknown schema versions, duplicate IDs, unsupported types, type mismatches, invalid choice defaults, malformed JSON, and invalid bounds are rejected with `LastError`.

## Public B4J API

```vb
Prefs.Initialize(Me, "Prefs", MainForm)
Prefs.SetDictionary("en", EnglishMap)
Prefs.SetDictionary("ms", MalayMap)
Prefs.SetLanguage("en")
Prefs.SetTheme(Prefs.CreateLightTheme)
If Prefs.LoadDefinition(DefinitionJson) = False Then LogError(Prefs.LastError)

Prefs.SetValue("username", "Aeric") ' Boolean result; LastError on failure
Dim Value As Object = Prefs.GetValue("username")
Dim Values As Map = Prefs.GetValues ' Copy/snapshot
Prefs.ResetToDefaults ' Restores every value preference to its default
Prefs.ResetPreference("username") ' Restores one value preference to its default

' Persistence
Dim Store As PrefsStore
Store.Initialize
Prefs.SetStore(Store) ' Writes committed values to the store after every commit/set/reset
Dim Applied As Int = Prefs.LoadStoredValues ' Restores stored values for known value preferences
Dim Json As String = Prefs.ExportValues ' Save committed values into the store and return a JSON snapshot
Dim Imported As Int = Prefs.ImportValues(Json) ' Parse JSON into the store, then apply matching values
Prefs.Show ' Synchronous modal form, owned by MainForm
Prefs.CreatePage(MainForm.RootPane) ' Anchors a page in this caller-owned container
Prefs.RefreshPage ' Rebuilds visible values from committed state
Prefs.DisposePage ' Removes only the library-owned page node
```

`SetValue` validates IDs, types, choice membership, string constraints, and number bounds; failed sets do not modify values. `GetValues` returns a copied map and clones list-valued multichoice values. `ResetToDefaults` and `ResetPreference` operate on committed values for value preferences and are excluded from change events (no change event exists in this milestone).

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

## Test checklist and results

| Check | Result |
| --- | --- |
| B4JBuilder 10.70 build, warnings enabled | **PASS** |
| JSON syntax for schema, demo definition, and both locale files | **PASS** |
| Demo jar contains `Files/settings.json`, `Files/en.json`, and `Files/ms.json` | **PASS** |
| Core runtime assertions (model validation, supported values, string/number/date/time/selection constraints, scalar and list snapshots, draft cancel/commit) | **Included; run in demo on startup** |
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
| Copy-to-app-storage | Implemented; not exercised (disabled in demo definition) |
| Values restored after application restart | **PASS** (reported: `Restored 12 value(s)` after relaunch) |
| Packaged `.b4xlib` compiles and runs from a fresh B4J project | **PASS** (reported) |
| Reopen after Save preserves values in memory | **PASS** (reported GUI test) |
| B4J page renderer compiles and shares the model/controller API | **PASS** (build verified) |
| Page mounting/resizing, Save/Cancel, repeated dispose/remount, localization/theme refresh | **PASS** (reported GUI test) |
| Multiline/password/checkbox/multichoice/date/time/datetime/slider controls and validation | **PASS** (reported GUI test) |
| Modal dialog sizing at 600 DIP | **PASS** (reported GUI test) |
| Values survive application reboot | **Supported via `PrefsStore`** (see Persistence) |

The project was build-verified with B4JBuilder 10.70 and Java 19 selected by the builder. Milestones 1–3 GUI results above were reported from demo runs. Committed values intentionally live in memory only; restarting the application restores definition defaults because persistence is deferred.

## Deferred beyond current scope

File/directory preferences and providers (M5), B4A/B4i support (M6), custom renderers (`custom`) and adaptive presentation (M7), immediate-save mode, conditional display, advanced validators, advanced styling, automated GUI testing, and distributable `.b4xlib` packaging.
