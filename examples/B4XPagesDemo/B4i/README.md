# B4i

The B4i demo uses the same shared `B4XMainPage.bas` as B4J/B4A. The page is
platform-neutral, so the B4i project only supplies `Main` (which initializes
`B4XPagesManager`) and the shared `Files/` assets. Platform differences are
handled inside `B4XMainPage.bas` with `#If B4i` blocks.

The library side is stubbed for now. The shared `B4XFlexibleDialog` facade,
`PrefsDialog`, and `PrefsPage` carry `#Else`/`#If B4i` stubs, and
`B4XFlexibleDialog.b4xlib` ships a B4i `PrefsDirPicker` with the same public
surface as B4A but no-op bodies, so the shared page compiles on B4i without a
working form. `Show` fires `_DialogClosed(False)` immediately.

To finish B4i:

1. Implement the B4i branches of the shared `PrefsDialog.bas` / `PrefsPage.bas`
   (and the facade `Show`/`CreatePage` paths), replacing the no-op bodies with a
   real UI built from `B4i` views.
2. Implement `B4XFlexibleDialog/B4i/PrefsDirPicker.bas` if directory preferences
   are needed (current `SelectDir` is a no-op).
3. Repackage with `tools/package-b4xlib.ps1` (the facade/dialog/page are shared, so
   they already ship; only the `B4i/` picker is platform-specific).

B4i compilation requires a Mac builder and has not been verified locally.
