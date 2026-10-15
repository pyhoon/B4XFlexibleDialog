# Changelog

## Unreleased — Milestone 3 progress

- Added `multiline`, `password`, and `checkbox` to the B4J model, dialog, page, and demo.
- Added `required`, `minLength`, and `maxLength` string validation to the version-1 schema, model, and controller.
- Added multi-select ListView preferences with list-value snapshot copying.
- Added ISO date preferences using B4J DatePicker and numeric slider preferences.
- Added validated `HH:mm` time and timezone-free `yyyy-MM-dd'T'HH:mm` datetime preferences.
- Added startup assertions for the new value types and validation cases.

## 0.1.0 — Milestone 1 foundation

- Added the B4J JSON definition model, committed/draft controller, four basic controls, modal Save/Cancel flow, runtime language dictionaries, and light/dark theme.
- Defined JSON schema version 1 and a runnable four-control demo.
- Initialize themes through `PrefsTheme.Initialize(Dark As Boolean)` and show the current demo language/theme state visibly.
- No cross-platform API is claimed as implemented.
