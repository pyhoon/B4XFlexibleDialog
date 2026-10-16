# B4i

The B4i demo uses the same shared `B4XMainPage.bas` as B4J/B4A. The page is
platform-neutral, so the B4i project only supplies `Main` (which initializes
`B4XPagesManager`) and the shared `Files/` assets. Platform differences are
handled inside `B4XMainPage.bas` with `#If B4i` blocks.

The library side is stubbed for now. `B4XFlexibleDialog.b4xlib` ships B4i
`PrefsRenderer` and `PrefsDirPicker` modules with the same public surface as B4A
but no-op bodies that log a warning, so the shared page compiles on B4i without a
working form. `Save` returns `True` so persistence paths still behave predictably.

To finish B4i:

1. Implement `B4XFlexibleDialog/B4i/PrefsRenderer.bas` (mirror
   `B4XFlexibleDialog/B4A/PrefsRenderer.bas`, replacing the no-op bodies with a
   real UI built from `B4i` views).
2. Implement `B4XFlexibleDialog/B4i/PrefsDirPicker.bas` if directory preferences
   are needed (current `SelectDir` is a no-op).
3. Repackage with `tools/package-b4xlib.ps1` (it already ships the `B4i/` modules).

B4i compilation requires a Mac builder and has not been verified locally.
