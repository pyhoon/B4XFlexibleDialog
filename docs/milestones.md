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

## M2 — B4J full-page renderer — next

Render the existing model/controller inside a caller-provided B4J container. The caller retains navigation ownership. Verify that dialog and page use the same committed values and explicit save semantics; refresh controls for value, language, and theme changes; document sizing, scrolling, mounting, and disposal behavior.

## M3 — Additional preference types and validation

Add control types incrementally, each with documented value/default/options/validation behavior. Add reset operations and applicable built-in constraints without introducing a general expression engine.

## M4 — Persistence and migrations

Introduce persistence adapters independently of in-memory values. Start with map/JSON adapters, define commit/error behavior, preserve unknown keys where appropriate, and keep definition migration policy separate from library versioning.

## M5 — File and directory preferences

Add an optional file-provider contract and normalized selection result. Use JavaFX chooser APIs for B4J; evaluate other platform providers separately. Document URI/path/access differences and optional app-managed copying. No mandatory external picker dependency is planned.

## M6 — B4A and B4i adapters

Port the logical model/controller contracts, then implement and test platform-specific renderers and pickers. Do not claim cross-platform completion until B4A and B4i examples are compiled and exercised.

## M7 — Extensibility and release

Finalize custom renderer lifecycle, API compatibility, platform capability documentation, fresh-project integration, and distributable `.b4xlib` packaging.
