# B4XFlexibleDialog TODO

Action list aligned with the [milestone roadmap](milestones.md). Check items off only when implemented and verified. The current repository is at the definition/model baseline; prioritize B4J controller work before broadening platform scope.

## M0 — Definition contract and B4J model

- [x] Add versioned JSON schema and example definition.
- [x] Implement initial B4J model parsing and validation.
- [x] Add B4J smoke-test project.
- [ ] Add detailed type-specific validation for option shapes and default-value types.
- [ ] Add focused model cases for malformed JSON, duplicate IDs, missing fields, unknown types, and choice options.

## M1 — B4J controller, values, and validation

- [ ] Define and document policies for `SetValues`, missing values, and unknown IDs.
- [ ] Implement committed values, defaults, defensive `GetValues` snapshot, `GetValue`, `SetValue`, and `HasValue`.
- [ ] Implement `ResetToDefaults`, `ResetPreference`, and `GetDefaultValue`.
- [ ] Implement explicit-save draft transaction with atomic validate-then-commit and cancel/discard behavior.
- [ ] Implement configurable immediate-save mode and dirty-state reporting.
- [ ] Implement built-in constraints and validation result/error contract.
- [ ] Define and implement callback/event ordering for value changes, validation, save, and close.
- [ ] Demonstrate controller behavior in the B4J example and compile/run the smoke test.

## M2 — B4J presentation prototype and theming

- [ ] Define renderer/control factory boundary so preference types can be registered without expanding core conditionals.
- [ ] Add B4J dialog presentation backed by the shared controller.
- [ ] Add embedded page/panel presentation backed by the same controller.
- [ ] Implement initial text, multiline, password, number, switch, checkbox, choice, date, label, and action controls as feasible.
- [ ] Add Save, Cancel, and Reset actions and connect them to save semantics.
- [ ] Add light/dark/system theme presets and configurable design tokens.
- [ ] Add switch colors, Today-button styling, button styling, and per-preference overrides.
- [ ] Verify programmatic value changes update rendered controls and document sizing behavior.

## M3 — Localization and runtime definition features

- [ ] Load JSON dictionaries by language code and configure active/fallback languages.
- [ ] Implement missing-key policy and built-in UI translations (Browse, Clear, Today, Save, Cancel, Reset, validation messages).
- [ ] Refresh visible strings when language changes without resetting committed or draft values.
- [ ] Add runtime preference/section add, update, and remove operations with ID/ordering guarantees.
- [ ] Implement simple equality/boolean `enabledWhen` and `visibleWhen` rules.
- [ ] Keep hidden, disabled, and read-only states distinct.
- [ ] Document locale-sensitive date/number formatting and unsupported cases.

## M4 — Persistence and file/media preferences

- [ ] Define persistence adapter contract independently of controller values.
- [ ] Add map and JSON storage adapters with documented commit timing and error handling.
- [ ] Decide unknown-key preservation and stored-value migration policy.
- [ ] Define normalized file selection result (path/URI, display name, access information).
- [ ] Evaluate `MediaChooser` for cross-platform file/media picker integration and record platform coverage/dependencies.
- [ ] Add file filters, clear-selection behavior, optional multiple selection, and optional image preview.
- [ ] Define and implement optional copy-to-app-storage behavior.
- [ ] Add directory selection only for platforms/adapters that support it; report unsupported cases clearly.

## M5 — B4A and B4i adapters

- [ ] Establish minimum supported B4A/B4i versions and build environments.
- [ ] Port shared model, controller, localization, theme, and validation behavior.
- [ ] Implement platform-specific dialog/page rendering adapters.
- [ ] Implement and document native file/media picker behavior, URI/security-scoped access, and persistence implications.
- [ ] Verify common schema and value semantics with per-platform runnable examples.
- [ ] Publish a platform capability/limitation matrix.

## M6 — Extensibility and release

- [ ] Finalize callback-based custom renderer registration and lifecycle.
- [ ] Review public API names/signatures against actual B4X compiler/platform constraints.
- [ ] Complete API, schema, storage, migration, localization, theme, and compatibility documentation.
- [ ] Package `.b4xlib` with dependencies and supporting resources.
- [ ] Add runnable examples for each supported platform and core use case.
- [ ] Perform a fresh-project integration check without editing library source.
