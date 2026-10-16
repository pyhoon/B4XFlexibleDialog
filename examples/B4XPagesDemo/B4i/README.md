# B4i placeholder

B4i is not wired up yet. This folder marks where its project belongs.

The groundwork is already platform-neutral:

- The library's public view API is `B4XView`-based (`CreatePage(Container As B4XView)`),
  so the same call sites can target a B4i `B4XView`.
- `B4XMainPage.bas` and `AppHost.bas` are shared and contain no platform modules.
- The B4A `PrefsHost.bas` shows the shape a B4i host needs: a class that owns the
  renderer, persistence and the sample `Rating_*` custom renderer.

To add B4i:

1. Add a B4i renderer (`PrefsRenderer`) mirroring `B4XFlexibleDialog/B4A/PrefsRenderer.bas`,
   plus a `PrefsDirPicker` equivalent if directory preferences are needed.
2. Ship those modules under `B4i/` in the `.b4xlib` (see `tools/package-b4xlib.ps1`).
3. Create `B4i/B4XPagesDemo.b4i` with a `PrefsHost` class and `Main` that set
   `AppHost.Target`, reusing the shared `B4XMainPage.bas` and `AppHost.bas`.
4. Copy the shared `Files/` assets into `B4i/Files`.
