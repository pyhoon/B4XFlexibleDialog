# B4XFlexibleDialog / B4XPreferences Milestones

Roadmap based on the [New B4XPreferencesDialog forum discussion](https://www.b4x.com/android/forum/threads/new-b4xpreferencesdialog.172283/) and the current repository implementation. The library is being developed incrementally; planned capabilities below are not claims of current support.

## Product direction

Build a reusable, schema-driven preferences framework for B4X with shared definitions and values, runtime localization, customizable themes, explicit or immediate save semantics, dialog and embedded-page presentations, and platform-specific file picking. Start with a verifiable B4J implementation, then port shared behavior and isolate platform differences in adapters.

Architecture principles:

- Preference IDs and definitions are independent of language, presentation, and persistence.
- One definition serves all locales; changing locale must preserve current and draft values.
- Dialog and page presentations use the same controller/value model.
- Theme changes and custom preference renderers must not require editing core renderer code.
- Platform-specific limitations, especially file access, are explicit in the API and documentation.
- B4X `MediaChooser` should be evaluated as a cross-platform file/media picker integration, as suggested in the forum discussion.

## Milestones

### M0 — Definition contract and B4J model (in progress / baseline)

Define schema version 1 and implement the B4J JSON definition loader and validator.

**Acceptance criteria**

- Machine-readable schema and example definition are checked in.
- Loader rejects malformed definitions, duplicate IDs, missing required fields, unsupported types, and invalid choice lists with actionable errors.
- A small B4J project exercises loading and reports the definition ID and preference count.
- Documentation distinguishes schema-listed/planned types from implemented renderers.

**Current state:** `docs/schema-v1.json` and `B4XFlexibleDialog/B4J/PrefsModel.bas` provide the initial contract and loader. More thorough type-specific option/value validation remains future work.

### M1 — B4J controller, values, and validation

Implement the public-facing value lifecycle around the model before building UI.

**Scope**

- Stable-ID value access, defaults, reset operations, and defensive snapshots.
- Committed and draft maps for explicit Save/Cancel transactions; configurable immediate mode.
- Built-in constraints and validation of both individual changes and the complete draft before commit.
- Documented change, validation, save, and close event ordering.
- Expand the runnable B4J example to demonstrate values and cancel/commit behavior.

**Acceptance criteria**

- Cancel never commits draft values; failed full validation never partially commits values.
- Programmatic and user-originated changes share validation and change notification behavior.
- Defaults, missing values, and valid empty values remain distinguishable.

### M2 — B4J presentation prototype and theming

Render the same model/controller as both a modal dialog and an embedded page/panel.

**Scope**

- Initial common controls: text, multiline, password, number, switch, checkbox, choice, date, and action/label as feasible.
- Save/Cancel/Reset interaction for explicit mode; immediate update behavior for immediate mode.
- Theme presets and configurable colors, typography, spacing, dimensions, buttons, switches, and date-picker Today action.
- Per-preference style overrides and refresh/update behavior for programmatic changes.
- Explicit dialog/page mode; adaptive mode follows once both presentations have measured sizing behavior.

**Acceptance criteria**

- One definition and controller values work unchanged in both presentations.
- Theme customization does not require changing renderer source.
- Dialog and page are usable in the included B4J example and have documented limitations.

### M3 — Localization and schema/runtime completeness

Add language dictionaries independent of the schema and complete important runtime definition features.

**Scope**

- Load/replace locale dictionaries, active and fallback language, missing-key policy, and localized built-in strings.
- Runtime language switch refreshes visible text without resetting values or drafts.
- Section grouping plus runtime add/update/remove/enable/hide/read-only operations where supported by the model/UI.
- Simple `enabledWhen` / `visibleWhen` conditions and explicit distinction among hidden, disabled, and read-only.
- Document schema versioning and keep definition evolution separate from saved-value migration.

**Acceptance criteria**

- A single settings definition can be rendered in multiple languages without duplication.
- Missing translations use the documented fallback policy.
- Changing language preserves edits and updates labels in the visible presentation.

### M4 — Persistence and file/media preferences

Keep persistence pluggable and add a portable first-party storage option plus platform picker abstraction.

**Scope**

- In-memory/map and JSON value stores; persistence only at the configured commit boundary.
- Preserve unknown stored keys where appropriate and define migration/error behavior.
- File preference with filters, optional multiple selection, preview, clear action, and optional copy-to-app-storage behavior.
- Directory selection only where supported; normalized result includes path/URI, display name, and access details as applicable.
- Evaluate/integrate `MediaChooser` for cross-platform file and media picking; document when platform adapters or different picker modes are needed.

**Acceptance criteria**

- Stored values can be loaded and saved without coupling the schema to a storage backend.
- File access semantics are documented per platform; the API does not promise a permanent filesystem path when the OS supplies a URI or scoped access.
- A selected image can be previewed and, when configured, remains available through app-managed storage after restart.

### M5 — B4A and B4i adapters and compatibility

Port shared model/controller/localization/theme behavior and supply thin platform-specific UI and picker adapters.

**Scope**

- Build and smoke-test shared definitions and values on B4A and B4i.
- Implement supported dialog/page presentations and native file/media selection integrations.
- Record minimum toolchain versions, dependencies, unsupported controls, and behavior differences.

**Acceptance criteria**

- Same schema and value semantics work on B4J, B4A, and B4i for the documented common feature set.
- Platform limitations are reported rather than silently represented as equivalent behavior.

### M6 — Extensibility, packaging, and release

Stabilize the public API and deliver a usable library package.

**Scope**

- Callback-based custom renderers with a registration contract; keep advanced extension points additive.
- Finalize public facade, event contracts, examples, API/schema/migration documentation, and dependency list.
- Package `.b4xlib` and provide runnable examples for supported platforms.

**Acceptance criteria**

- A fresh project can consume the library without modifying its source.
- Examples demonstrate localization, theme customization, save modes, both presentations, and file/media selection where supported.
- Public API and compatibility contract match implemented and tested behavior.
