# Component identification — clairvoyant-rb

Upstream ref audited: `origin/main` @ `f4f3a605` ("ci: only mirror on pushes to
main"). Port ref audited: `ruby` @ `4f57ec8` ("Declare the runtime GTK/gettext
dependencies the gemspec was missing").

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
read or exercised by anything in `lib/`, `exe/` or `test/` — the port's Ruby
code has no counterpart to the `.desktop` file at all; it exists only as the
unmodified `.in` template plus a Nix-build-time `msgfmt --desktop` step. See
`component-parity.md` for why this is a gap and not merely a build detail.
