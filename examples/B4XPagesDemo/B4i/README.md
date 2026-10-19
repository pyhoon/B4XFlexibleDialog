# B4i (not planned)

B4i is **not planned for the near term**. The B4i project is kept only for compile
parity so the shared `B4XMainPage.bas` still builds on that target; it uses the
same shared page as B4J/B4A and only supplies `Main` (which initializes
`B4XPagesManager`) plus the shared `Files/` assets. Platform differences are
handled inside `B4XMainPage.bas` with `#If B4i` blocks.

The library side is a compile-only stub. The shared `B4XFlexibleDialog` facade,
`PrefsDialog`, and `PrefsPage` carry `#Else`/`#If B4i` stubs, and
`B4XFlexibleDialog.b4xlib` ships a B4i `PrefsDirPicker` with the same public
surface as B4A but no-op bodies, so the shared page compiles without a working
form. `Show` fires `_DialogClosed(False)` immediately.

If B4i is ever scheduled, the work is:

1. Implement the B4i branches of the shared `PrefsDialog.bas` / `PrefsPage.bas`
   (and the facade `Show`/`CreatePage` paths), replacing the no-op bodies with a
   real UI built from `B4i` views.
2. Implement the B4i branch of the shared `PrefsDirPicker.bas` if directory
   preferences are needed (current `SelectDir` is a no-op).
3. Repackage with `tools/package-b4xlib.ps1` (the facade/dialog/page are shared, so
   they already ship; only the `B4i/` picker is platform-specific).

B4i compilation requires a Mac builder and has not been verified locally.
