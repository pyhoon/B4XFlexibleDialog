# B4XPages demo

A B4XPages demo that consumes the packaged **B4XFlexibleDialog.b4xlib** on B4J,
B4A and B4i from a single shared page. The shared `B4XMainPage` owns the whole
demo: it builds its UI with cross-platform views, wires up the library (the B4J
facade in-process, or the B4A/B4i `PrefsRenderer`), persists values and hosts the
sample `RatingStars` custom renderer. On B4J a button opens the modal dialog
(`Prefs.Show`) alongside the embedded page (`Prefs.CreatePage`); on B4A/B4i the
renderer has no built-in chrome, so the page provides Save/Cancel and renders the
form into a host panel. Values persist locally and are restored on launch.

The page is the only module in the project (`B4XMainPage.bas`), so a page class
never reaches into an Activity module (B4A forbids that), and no view-typed class
fields live in `Process_Globals` (B4A forbids that too). Platform differences are
handled with `#If B4J`/`#If B4A`/`#If B4i` blocks inside the one file.

B4i is wired up as stubs for now (`B4i/README.md`): the library ships a B4i
`PrefsRenderer`/`PrefsDirPicker` with the same public surface but no-op bodies, so
the shared page compiles on B4i while the real renderer is pending.

## Setup

1. Install the library: copy `dist\B4XFlexibleDialog.b4xlib` into your B4J/B4A/B4i
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
     -BaseFolder='C:\Projects\B4XFlexibleDialog\examples\B4XPagesDemo\B4A' `
     -Project='C:\Projects\B4XFlexibleDialog\examples\B4XPagesDemo\B4A\B4XPagesDemo.b4a' `
     -ShowWarnings=True -NoSign=True
   ```

   The B4A builder needs an absolute `-BaseFolder` (its D8 dex step fails to
   resolve a relative one). B4i builds require a Mac builder.

## What to look for

- B4J: the page shows the settings form inline on the right; the dialog button opens the modal form.
- B4A: the page hosts the same form with Save/Cancel buttons above it.
- Both presentations share committed values: Save in one and the other reflects it.
- Edit values and Save; close and relaunch: values are restored from the local store file.
- The `satisfaction` row is a custom star-rating renderer (`Rating_*` subs in `B4XMainPage`).

## Files

- `B4XMainPage.bas` — the shared page: UI, library wiring, persistence and the rating renderer (platform branches via `#If`).
- `B4J/B4XPagesDemo.b4j` — B4J project. `Main` hands the owner form to the page with `B4XPages.MainPage.SetHostForm`.
- `B4A/B4XPagesDemo.b4a` — B4A project. `Main` just initializes `B4XPagesManager`; the page does the rest.
- `B4i/B4XPagesDemo.b4i` — B4i project (unverified; needs a Mac builder).
- `B4J/Files/` and `B4A/Files/` and `B4i/Files/` — `settings.json`, `en.json`, `ms.json` (B4J also `prefs.css`). The rating sample uses the built-in MaterialIcons font.
