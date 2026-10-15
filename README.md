# B4XFlexibleDialog

Milestone 1 is a B4J-only JSON-driven modal preferences dialog. Preference definitions and values live in JavaFX-independent model/controller classes; the dialog renders controls and edits a separate draft. This milestone supports `text`, `number`, `switch`, and `choice` only.

## Demo and build

Open `B4XFlexibleDialog/B4J/B4XFlexibleDialog.b4j` in B4J 10.7 or build from PowerShell:

```powershell
& 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
  -BaseFolder='C:\Projects\B4XFlexibleDialog\B4XFlexibleDialog\B4J' `
  -Project='C:\Projects\B4XFlexibleDialog\B4XFlexibleDialog\B4J\B4XFlexibleDialog.b4j' `
  -ShowWarnings=True
```

The sample project compiles to `B4XFlexibleDialog/B4J/Objects/B4XFlexibleDialog.jar`. On launch it loads `Files/settings.json`, reads `Files/en.json` and `Files/ms.json`, runs core model/controller assertions to the log, and presents buttons to open the dialog, switch the language, and switch the theme. The selected language/theme is shown on the main form; the theme changes the main form preview as well as the dialog. The dialog applies its theme to the JavaFX root pane and controls, with explicit input surfaces, borders, readable foregrounds, and contrasting primary/secondary buttons. `Files/prefs.css` styles checkbox marks and the choice dropdown/popup using theme colors provided by the dialog.

### Verified dependencies

- B4J 10.7 / JavaFX (`jFX`, library key `jfx`)
- B4J core (`jCore`, library key `jcore`)
- B4J JSON (`Json`, library key `json`)
- No third-party libraries, external pickers, or persistence dependencies.

## Source modules

- `PrefsModel.bas`: JSON parsing and validation; preference metadata only.
- `PrefsController.bas`: defaults, typed values, draft state, validation, commit/cancel, snapshots; no UI types.
- `PrefsDialog.bas`: B4J JavaFX form and control rendering.
- `PrefsLocalization.bas`: language dictionaries and missing-key fallback.
- `PrefsTheme.bas`: minimal light/dark colors and layout spacing.
- `B4XFlexibleDialog.bas`: facade and callback forwarding.

## Definition JSON v1

See [`docs/schema-v1.json`](docs/schema-v1.json). Top-level fields are `schemaVersion` (must be `1`), `id`, optional `titleKey`, and `sections`. Each section has `id`, optional `titleKey`, and a `preferences` array. IDs use `[A-Za-z][A-Za-z0-9_.-]*`; preference IDs are unique across the full definition and section IDs are unique. Missing definition `titleKey` defaults to the definition ID; missing section `titleKey` defaults to its ID. Preference `titleKey` is required.

Supported preference contracts:

| Type | Value/default | Options and behavior |
| --- | --- | --- |
| `text` | String; omitted default becomes `""` | No extra options. |
| `number` | Numeric; omitted default becomes `0` | Optional numeric `options.min` and `options.max`; bounds must be ordered and contain the default and saved value. |
| `switch` | Boolean; omitted default becomes `false` | No extra options. |
| `choice` | String matching an item `value`; default required | `options.items` is a non-empty array of `{ "value": string, "titleKey": string }`; duplicate item values are rejected. |

`defaultValue` is optional for text, number and switch (defaults above), required for choice. Unknown schema versions, duplicate IDs, unsupported types, type mismatches, invalid choice defaults, malformed JSON and invalid number bounds are rejected with `LastError`. The loader ignores unrelated extra fields at present; the JSON Schema is the stricter authoring contract. Schema-breaking changes require a new version.

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
Prefs.Show ' Synchronous modal form, owned by MainForm
```

`SetValue` validates IDs, types, choices, and number bounds; failed sets do not modify values. `GetValues` returns a shallow copy (values in this milestone are immutable scalar values). `Show` creates draft values from the committed map. Save reads all controls, validates the complete draft, calls `BeforeSave`, commits only if accepted, then calls `AfterSave`. Cancel and the window close button discard the draft. Save and Cancel are mutually exclusive outcomes. Reopening after Save shows the committed in-memory values.

Implement all three callback subs on the object passed to `Initialize` (the demo uses event prefix `Prefs`):

```vb
Private Sub Prefs_BeforeSave(Values As Map) As Boolean
    Return True ' Return False to keep the dialog open and reject the commit.
End Sub

Private Sub Prefs_AfterSave(Values As Map)
End Sub

Private Sub Prefs_DialogClosed(WasSaved As Boolean)
End Sub
```

Callbacks use B4J `CallSub` / `CallSub2`; the before-save callback must return Boolean. It receives the complete candidate map before commit; AfterSave receives the committed snapshot. These three callback routines are required for the current implementation.

`SetLanguage` resolves keys against the selected dictionary; an unknown key falls back to the key itself. The dialog's Language button toggles English/Malay and refreshes visible labels, including choice titles, without touching values. `SetTheme` accepts a theme from `CreateLightTheme` or `CreateDarkTheme`; the demo also toggles theme while the dialog is closed. The dialog's Theme button changes its live background/text/button colors. Colors are 32-bit ARGB integers. Refreshes do not raise preference value-change callbacks (there is no change event in this milestone).

## Test checklist and results

| Check | Result |
| --- | --- |
| B4JBuilder 10.70 build, warnings enabled | **PASS** |
| JSON syntax for schema, demo definition, and both locale files | **PASS** |
| Demo jar contains `Files/settings.json`, `Files/en.json`, and `Files/ms.json` | **PASS** |
| Core runtime assertions (valid/malformed JSON, duplicate IDs, unknown type, defaults, typed set/get, bounds, snapshot, draft cancel/commit) | **PASS** (reported demo log) |
| All four controls render and edit | **NOT RUN (GUI)** |
| Cancel/close leaves committed defaults unchanged | **PASS** (reported `Saved=false` log; observed twice) |
| Save/rejection and numeric error display | **NOT RUN (GUI)** |
| In-dialog language/theme switching and value preservation | **NOT RUN (GUI)** |
| Reopen after Save | **NOT RUN (GUI)** |

The project was build-verified with B4JBuilder 10.70 and Java 19 selected by the builder. The core assertion results and Cancel/close result above were provided from a demo run. The remaining visual/edit/Save interactions still need their GUI checks. The demo emits a log line for each core assertion when it starts.

## Deferred to Milestone 2+

Full-page renderer, B4A/B4i support, adaptive presentation, more preference types, persistence and migrations, import/export, immediate-save mode, file providers, custom renderers, conditional display, advanced validators, advanced styling, automated GUI testing, and distributable `.b4xlib` packaging.
