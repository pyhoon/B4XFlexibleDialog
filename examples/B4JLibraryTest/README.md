# B4J library consumption example

A minimal B4J project that consumes the packaged **B4XFlexibleDialog.b4xlib** (not the source modules).
It loads a JSON definition, opens the modal preferences dialog, persists values to
`File.DirApp\prefs-store.json`, and restores them on the next launch.

## Setup

1. Install the library: copy `dist\B4XFlexibleDialog.b4xlib` into your B4J Libraries folder
   (the standard `Libraries` folder or your configured Additional Libraries folder).
2. Open `B4JLibraryTest.b4j` in B4J and run it, or build from PowerShell:

   ```powershell
   & 'C:\Program Files\B4X\B4J\B4JBuilder.exe' -Task=Build `
     -BaseFolder='examples\B4JLibraryTest' `
     -Project='examples\B4JLibraryTest\B4JLibraryTest.b4j' `
     -ShowWarnings=True
   ```

## What to look for

- A window with an **Open preferences** button.
- The dialog shows the controls defined in `Files\settings.json` with labels from `en.json`.
- Edit values and Save; close and relaunch: values are restored from `prefs-store.json`.
- The Language and Theme buttons switch runtime localization/theme.

## Files

- `B4JLibraryTest.b4j` — project file and `Main` module (event prefix `Prefs`).
- `Files\settings.json` — preference definition.
- `Files\en.json`, `Files\ms.json` — localization dictionaries.
- `Files\prefs.css` — theme stylesheet consumed by the library at runtime.
