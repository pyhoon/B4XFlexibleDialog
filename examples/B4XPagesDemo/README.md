# B4XPages demo

A B4XPages-based B4J project that consumes the packaged **B4XFlexibleDialog.b4xlib**.
The shared `B4XMainPage` shows an embedded settings page (via `Prefs.CreatePage`)
next to a button that opens the modal dialog (via `Prefs.Show`), demonstrating
both presentations from one definition. Values persist to
`File.DirApp\prefs-store.json` and are restored on the next launch.

B4J-only for now: the hosted settings page needs a native `AnchorPane`, which
only exists on B4J. The B4XPages structure (manager plus shared page class)
allows B4A/B4i folders to be added later once the facade supports those
platforms.

## Setup

1. Install the library: copy `dist\B4XFlexibleDialog.b4xlib` into your B4J Libraries folder
   (the standard `Libraries` folder or your configured Additional Libraries folder).
2. Open `B4J/B4XPagesDemo.b4j` in B4J and run it, or build from PowerShell:

   ```powershell
   & 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
     -BaseFolder='examples\B4XPagesDemo\B4J' `
     -Project='examples\B4XPagesDemo\B4J\B4XPagesDemo.b4j' `
     -ShowWarnings=True
   ```

## What to look for

- The page shows the settings form inline on the right; the dialog button opens the modal form.
- Both presentations share committed values: Save in one and the other reflects it.
- Edit values and Save; close and relaunch: values are restored from `prefs-store.json`.
- The `satisfaction` row is a custom star-rating renderer (`Rating_*` subs in Main).

## Files

- `B4J/B4XPagesDemo.b4j` — project file, `Main` module (B4XPages manager, Prefs setup, event prefix `Prefs`).
- `B4XMainPage.bas` — shared launcher page (title, dialog button, embedded page host).
- `B4J/Files/` — `settings.json`, `en.json`, `ms.json`, `prefs.css`, `b4x_materialicons.ttf`.
