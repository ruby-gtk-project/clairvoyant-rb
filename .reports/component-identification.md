# Component identification — clairvoyant-rb

> **Update (round 3, this round, `2f6643e`):** re-confirmed
> `git rev-parse --short origin/main` is still `f4f3a60` — upstream unchanged.
> `git diff --stat b698135 2f6643e` touches `.github/workflows/drive.yml`,
> `.reports/test-parity.md`, `PORTING.md`, `Rakefile`, `flake.nix` and
> `test/validate_packaging.rb` — no `lib/`, `exe/` or `data/` file changed, so
> the widget inventory below still holds unchanged, same as every prior
> round. The change this round (vendoring `desktop-file-validate`/
> `appstreamcli` and wiring `rake test`/`rake spec`) is build/test
> infrastructure, not a new or changed component — it gives the existing
> "desktop entry installation" item (`data/gresource.xml` + `data/meson.build`
> section, below) its first real-validator check rather than adding a unit.
> See `component-parity.md`'s round-4 update and `test-parity.md`'s round-3
> update for what that closes.

> **Update (prior round, re-audit at `b698135`):** upstream unchanged —
> re-confirmed `git rev-parse --short origin/main` is still `f4f3a60`. Port
> moved from `2a8f5d2` to `b698135` ("Record port status") via `89ccac1`
> ("Parity reports", the prior round's `.reports/` writeup). `git diff --stat
> 2a8f5d2 b698135` touches only `.reports/accountability-ensurance.md`,
> `.reports/component-identification.md`, `.reports/component-parity.md` and
> the new `PORTING.md` — no `lib/`, `exe/`, `data/` or `.github/` file
> changed. The widget inventory below still holds unchanged.
>
> One more thing worth recording: packaging checks now exist
> (`test/validate_packaging.rb`, 16/16) that exercise `data/launcher.desktop.in`
> and `data/metainfo.appdata.xml.in` directly — these are checks of
> *installed-data artifacts*, not of a `lib/*.rb` widget class, so they do not
> add a new row to the "Port files and the units in each" table below; they
> are coverage of components this document already identified
> (`data/gresource.xml` + `data/meson.build`), not new components.

Upstream ref audited: `origin/main` @ `f4f3a605` ("ci: only mirror on pushes to
main") — unchanged since the previous round, re-confirmed this round
(`git rev-parse --short origin/main` still `f4f3a60`). Port ref audited:
`ruby` @ `2a8f5d2` ("Mark the About-dialog, desktop-entry and test-parity
gaps closed") — the current tip, re-walked this round rather than trusted
from the prior round's `4f57ec8`. Two things changed between those two refs
that the rest of this document's body (written against `4f57ec8`) predates
and this update records directly: `8f97156` added `test/validate_packaging.rb`
and `.github/workflows/drive.yml` (not units of their own — they are the test
and CI counterparts of the `data/meson.build` test targets noted below, not
new widget-tree files) and taught `AboutDialog::AppData` to translate its
metainfo fields; `2a8f5d2` only edited `.reports/`. Neither changed the widget
inventory itself, so the tables below still hold without re-deriving them.

No `.ui`/`.blp` files exist anywhere in the upstream tree (confirmed by
`git ls-tree -r --name-only origin/main` and a `.ui`/`.blp` name search) — every
widget is built in Vala source, so the inventory below is read out of
`src/*.vala` directly, file by file, per the skill's method.

## Upstream files and the units in each

### `src/Application.vala`

- Class `Clairvoyant : Adw.Application`, `application_id = APP_ID`,
  `flags = FLAGS_NONE`.
- `activate` override: presents the existing window if any exist, else builds
  `MainWindow`, shows it, installs `app.quit` (`SimpleAction`), sets accels
  `Escape`, `<Ctrl>Q`, `<Ctrl>W` on `app.quit`, connects `quit_action.activate`
  to `main_window.destroy`.
- `main()`: `Intl.bindtextdomain`, `Intl.bind_textdomain_codeset(UTF-8)`,
  `Intl.textdomain`, then `app.run(args)`.
- Owner: this file. No CSS.

### `src/MainWindow.vala`

- Class `MainWindow : Adw.ApplicationWindow`, constructed with
  `icon_name: APP_ID`, `resizable: false`.
- Widgets built in `construct`:
  | Widget | × | CSS | Signal |
  |---|---:|---|---|
  | `Gtk.Button.from_icon_name("about-symbolic")` | 1 | `dim-label` | (connected further down to open the about window) |
  | `Adw.AboutWindow.from_appdata("/com/cassidyjames/clairvoyant/metainfo.xml", VERSION)` | 1 | — | `transient_for = this`, `hide_on_close = true` |
  | `Gtk.HeaderBar` | 1 | `flat` | packs the about button, sets `title_widget` to an empty `Gtk.Label` |
  | `FortuneLabel` | 1 | — | `realize` → `randomize_fortune(true)` |
  | `Gtk.Button(label: _("Ask Again"))` | 1 | `suggested-action`, `pill` | `clicked` → `randomize_fortune()` |
  | `Gtk.Box` (vertical) | 1 | — | holds header, fortune label, ask button |
  | `Gtk.WindowHandle` | 1 | — | wraps the box, set as window content |
- `about_window.copyright` set from `"© 2018–%i %s"` with the current year and
  `about_window.developer_name`.
- `this.title = about_window.application_name`.
- `randomize_fortune(allow_current)`: picks a random page name from
  `FortuneLabel`'s stack; if `allow_current` is false and the name equals the
  one already showing, recurse until it differs.
- The about window reads `/com/cassidyjames/clairvoyant/metainfo.xml`, which is
  the **compiled GResource bundle's** copy of the metainfo — itself the output
  of `i18n.merge_file` against `po/`, i.e. upstream's running About window
  shows the *translated* summary/description/release notes under any locale
  that has them.

### `src/FortuneLabel.vala`

- Class `FortuneLabel : Gtk.Box`, horizontal-functioning root, public field
  `Gtk.Stack stack` (`transition_type: CROSSFADE`).
- A literal `Content[]` table of 28 rows: `{ title, css_class }`, where
  `css_class` is one of `success`, `error`, `warning`.
- `construct`: for each row, builds a vertical `Gtk.Box` page containing one
  `Gtk.Label` with CSS `title-1` plus the row's dynamic class, adds it to
  `stack` under a generated page name, appends the page box to `self`.
- Owner: this file. No actions.

### `data/gresource.xml` + `data/meson.build`

- GResource bundle: `data/styles/style.css`, `data/metainfo.appdata.xml.in`
  (merged → `metainfo.xml` by `i18n.merge_file`), `data/icons/about-symbolic.svg`.
- `install_data`: `data/icons/app.svg` → `hicolor/scalable/apps/<app-id>.svg`,
  `data/icons/symbolic.svg` → `hicolor/symbolic/apps/<app-id>-symbolic.svg`.
- `i18n.merge_file` on `data/launcher.desktop.in` → `<app-id>.desktop`
  (translates `Name`, `GenericName`, `Comment`, `Keywords`), installed to
  `$datadir/applications`, validated with `desktop-file-validate`.
- `i18n.merge_file` on `data/metainfo.appdata.xml.in` → `<app-id>.metainfo.xml`
  (translates `<name>`, `<summary>`, `<description>`, `<release>` entries),
  installed to `$datadir/metainfo`, validated with `appstreamcli validate`.
- `data/launcher.desktop.in`: `Name=Clairvoyant`, `GenericName=Fortune Teller`,
  `Comment=Ask questions, get psychic answers`,
  `Categories=Utility;Amusement;`, `Exec=com.cassidyjames.clairvoyant`,
  `Icon=com.cassidyjames.clairvoyant`, `Terminal=false`, `Type=Application`,
  `Keywords=magic;eight;ball;8;crystal;🔮;medium;🎱;`.

### `data/styles/style.css`

- One rule, tints window bg/fg via `color-mix()` with the accent colour.

### `src/Config.vala.in` + root `meson.build`

- Build-time constants: `APP_ID`, `VERSION`, `GETTEXT_PACKAGE`, `LOCALEDIR`.

### `po/*`

- 196 `.po` files named in `po/LINGUAS`, `POTFILES.in` listing the 5 extracted
  files (`data/launcher.desktop.in`, `data/metainfo.appdata.xml.in`,
  `src/Application.vala`, `src/FortuneLabel.vala`, `src/MainWindow.vala`), and
  the `.pot` template with 99 msgids (28 fortunes + UI strings + every
  metainfo `<summary>`/`<description>`/`<release>` string + every desktop-entry
  string + ~40 historical release-note strings).

## Non-components, confirmed absent

- No `.ui`/`.blp` files, no GSettings schema, no shortcuts window, no
  preferences window/dialog, no submenus/`Gio.Menu`, no submodules. Only one
  GTK action in the whole app (`app.quit`).

## Port files and the units in each

`lib/application.rb`, `lib/main_window.rb`, `lib/fortune_label.rb` +
`lib/fortunes.rb`, `lib/about_dialog.rb`, `lib/config.rb`, `lib/resources.rb`,
`lib/style.rb`, `lib/intl.rb`, `lib/clairvoyant.rb`, `exe/clairvoyant`. Each
carries a header comment naming its upstream source, and the widget trees in
`main_window.rb` and `fortune_label.rb` reproduce the tables above
widget-for-widget (verified directly against both files).

One divergence worth recording here because it changes what "the same
component" means for the About window: the port's `AboutDialog` is built from
`Resources::METAINFO`, which resolves to **`data/metainfo.appdata.xml`** —
a verbatim, byte-identical copy of upstream's untranslated
`.appdata.xml.in` (confirmed: `diff` between the two is empty) — read directly
with `File.read`, with no `msgfmt --xml`/`i18n.merge_file` equivalent applied
at the point the app reads it. Upstream's `/com/cassidyjames/clairvoyant/metainfo.xml`
is the *merged, translated* resource. This is the same component by type and
by file mapping; whether it behaves the same is a translation-parity question,
carried into `translation-parity.md` and `component-parity.md` rather than
re-litigated here.

No desktop-entry component (`data/launcher.desktop.in`'s merged output) is
read or exercised by anything in `lib/`, `exe/` — the port's Ruby code has no
counterpart to the `.desktop` file at all; it exists as the `.in` template
plus a Nix-build-time `msgfmt --desktop` step. As of `8f97156`,
`test/validate_packaging.rb` runs and asserts that merge (see
`component-parity.md` / `test-parity.md` for why that now closes the gap
this document originally flagged here).

**One undocumented difference found this round, independent of the
translation fix.** The port's `data/launcher.desktop.in` reads
`Exec=clairvoyant`; upstream's reads `Exec=com.cassidyjames.clairvoyant`
(confirmed: `diff` between the two files shows exactly this one line).
This is correct, not a bug — `flake.nix`'s `makeWrapper` installs the port's
binary to `$out/bin/clairvoyant` (the gemspec's `exe/clairvoyant`, not an
app-ID-named binary), so `Exec=com.cassidyjames.clairvoyant` would launch
nothing on a Nix-installed copy of the port and `Exec=clairvoyant` is the one
that resolves. But no prior report (`component-parity.md` included) named
this difference or the reasoning above; `test/validate_packaging.rb`'s own
check ("desktop entry Exec names the launcher") asserts the port's value
against itself, silently, rather than being read against upstream's file at
all. Recorded here as the correspondence it is, now that it has been found
and located.
