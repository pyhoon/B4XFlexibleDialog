# B4XPages demo

A B4XPages demo that consumes the packaged **B4XFlexibleDialog.b4xlib** on B4J
and B4A from a single shared page. The shared `B4XMainPage` mounts the settings
form next to the platform's entry points: on B4J a button opens the modal dialog
(`Prefs.Show`) alongside the embedded page (`Prefs.CreatePage`); on B4A the
renderer has no built-in chrome, so the page provides Save/Cancel and renders
the form into a host panel. Values persist locally and are restored on launch.

The page talks to each platform only through a small, identical surface — the
shared `AppHost` code module, which forwards to a per-platform `PrefsHost` class.
That keeps `B4XMainPage.bas` free of platform modules (B4A forbids a page class
from accessing Activity-module members) and the platform code out of
`Process_Globals` (B4A forbids view-typed class fields there).

B4i is a placeholder for now (`B4i/README.md`): the library's public view API is
`B4XView`-based and the shared page is platform-neutral, so only a B4i renderer
and `PrefsHost` need to be added.

## Setup

1. Install the library: copy `dist\B4XFlexibleDialog.b4xlib` into your B4J/B4A
   Libraries folder (the standard `Libraries` folder or your configured
   Additional Libraries folder).
2. Open `B4J/B4XPagesDemo.b4j` or `B4A/B4XPagesDemo.b4a` in the matching IDE and
   run it, or build from PowerShell:

   ```powershell
   & 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
     -BaseFolder='examples\B4XPagesDemo\B4J' `
     -Project='examples\B4XPagesDemo\B4J\B4XPagesDemo.b4j' `
     -ShowWarnings=True

   & 'C:\Program Files\B4X\B4A\B4ABuilder.exe' -Task=Build `
     -BaseFolder='examples\B4XPagesDemo\B4A' `
     -Project='examples\B4XPagesDemo\B4A\B4XPagesDemo.b4a' `
     -ShowWarnings=True -NoSign=True
   ```

## What to look for

- B4J: the page shows the settings form inline on the right; the dialog button opens the modal form.
- B4A: the page hosts the same form with Save/Cancel buttons above it.
- Both presentations share committed values: Save in one and the other reflects it.
- Edit values and Save; close and relaunch: values are restored from the local store file.
- The `satisfaction` row is a custom star-rating renderer (`Rating_*` subs in `PrefsHost`).

## Files

- `B4XMainPage.bas` — shared launcher page (title, platform entry points, embedded page host).
- `AppHost.bas` — shared dispatcher the page calls; forwards to `AppHost.Target`.
- `B4J/B4XPagesDemo.b4j` — B4J project; `PrefsHost.bas` owns the facade, store and rating renderer.
- `B4A/B4XPagesDemo.b4a` — B4A project; `PrefsHost.bas` owns the renderer, directory picker, store and rating renderer.
- `B4J/Files/` and `B4A/Files/` — `settings.json`, `en.json`, `ms.json`, `b4x_materialicons.ttf` (B4J also `prefs.css`).
- `B4i/` — placeholder for the B4i port.
