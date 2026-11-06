# Component inventory — clairvoyant-rb

Upstream is `origin/main` (Vala, meson/GResource build). Clairvoyant is a
small app — one window, one dialog, one custom widget, no settings, no
shortcuts window, no preferences, no submenus. The whole upstream source tree
(excluding `po/`) is:

```
src/Application.vala
src/Config.vala.in
src/config.vapi
src/FortuneLabel.vala
src/MainWindow.vala
data/gresource.xml
data/icons/{app,symbolic,about-symbolic}.svg
data/metainfo.appdata.xml.in
data/styles/style.css
data/launcher.desktop.in
po/*.po, po/POTFILES.in, po/com.cassidyjames.clairvoyant.pot
```

There are no `.ui`/`.blp` files — every widget is built in Vala source — and
no GSettings schema, no shortcuts window, no preferences dialog, no submodule.

## Status summary

Every upstream unit already has a corresponding `lib/*.rb` file on `ruby`, and
reading each file against its upstream source shows the port already
reproduces the widget tree, the CSS classes, the signal wiring and the one
action (`app.quit`) upstream installs. This is a parity survey, not a gap
list — see "Residual notes" at the end for the handful of things worth a
second look rather than components still to build.

## Components, in the order a user meets them

### `src/Application.vala` → `lib/application.rb` — the app itself (exists)

Not a widget, but the unit that owns the action and the accelerators.

| Facet | Upstream | Port |
|---|---|---|
| Class | `Clairvoyant : Adw.Application` | `Application` (plain Ruby class wrapping `Gtk::Application`, with a comment explaining `Adwaita::Application` is broken in the bindings) |
| Action | `app.quit` (`SimpleAction`) | `quit_action` → `Gio::SimpleAction.new('quit', nil)`, present |
| Accels | `Escape`, `<Ctrl>Q`, `<Ctrl>W` on `app.quit` | `QUIT_ACCELS = ['Escape', '<Ctrl>Q', '<Ctrl>W']`, present |
| Signal | `activate` → present existing window or build one | `app.signal_connect('activate')` branches on `app.windows.empty?`, present |
| `quit_action.activate` | destroys the main window | `action.signal_connect('activate') { main_window.close }`, present |

Kind: **application class**. Present, matches.

### `src/MainWindow.vala` → `lib/main_window.rb` — the whole app on screen (exists)

| Widget | × | CSS | Signals | Port status |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` (not resizable, no title bar chrome) | 1 | — | — | `Adwaita::ApplicationWindow`, `resizable = false`, present |
| `Gtk.WindowHandle` | 1 | — | — | `window_handle`, present — whole surface drags the window |
| `Gtk.Box` (vertical, main layout) | 1 | — | — | `main_layout`, present |
| `Gtk.HeaderBar` | 1 | `flat` | — | `header`, present, `flat` class set |
| `Gtk.Button` (about button) | 1 | `dim-label` | `clicked` → present About | `about_button`, icon `about-symbolic`, `dim-label`, `clicked`, present |
| `Gtk.Label` (empty header title widget) | 1 | — | — | `header.title_widget = Gtk::Label.new(nil)`, present |
| `FortuneLabel` (composite, defined in its own file) | 1 | — | `realize` → randomize with `allow_current: true` | `fortune_label`, `margin_top`/`margin_bottom` set, `realize` connected, present |
| `Gtk.Button` (Ask Again) | 1 | `suggested-action`, `pill` | `clicked` → randomize | `ask_button`, label `_('Ask Again')`, both classes, `clicked`, present |
| `Adw.AboutWindow` (built via `from_appdata`, defined in its own file in the port) | 1 | — | — | `about_dialog` → `AboutDialog`, present (see below) |

Behaviour: `randomize_fortune` (recursive draw-until-different unless
`allow_current`) → ported as `MainWindow#randomize_fortune`, present.

Kind: **window**. Present, matches, including the window title being taken
from the About dialog's AppData (`win.title = about_dialog.application_name`)
rather than stored separately.

### `src/FortuneLabel.vala` → `lib/fortune_label.rb` + `lib/fortunes.rb` — the answer on screen (exists)

Upstream keeps the 28-row content table and the widget in one file; the port
splits it into a data module (`Fortunes`, house style for "the static table a
widget reads") and the widget itself. Per the component-identification skill,
union both for the comparison:

| Widget | × | CSS | Signals | Port status |
|---|---:|---|---|---|
| `Gtk.Box` (outer, horizontal in upstream's call but functions as the component root) | 1 | — | — | `FortuneLabel < Gtk::Box`, present |
| `Gtk.Stack` (crossfade) | 1 | — | — | `stack`, `transition_type = :crossfade`, public ivar as upstream's `public Gtk.Stack stack`, present |
| `Gtk.Box` (vertical, per-page) | 28 (repeater, one per fortune) | — | — | repeater over `Fortunes`, present |
| `Gtk.Label` (fortune title) | 28 (repeater) | `title-1`, plus one of `success`/`error`/`warning` per row (dynamic, data-driven) | — | repeater, present; all three dynamic classes are listed in `Fortunes`, not collapsed to "dynamic" |

Data table (`Fortunes`, 28 rows, `success`/`error`/`warning` in upstream's
order): present, matches upstream's `Content[]` literal row for row.

Kind: **custom widget** + **data module**. Present, matches.

### `Adw.AboutWindow.from_appdata(...)` (inline in `MainWindow.vala`) → `lib/about_dialog.rb` — the About dialog (exists)

Upstream builds this inline rather than in its own file; the port gives it
one, which is the correct house-style split (one widget, one file) and still
counts as the same component.

| Facet | Upstream | Port |
|---|---|---|
| Widget | `Adw.AboutWindow.from_appdata(path, VERSION)` | `AboutDialog < Adwaita::AboutWindow`, since `from_appdata` is unbound — port parses the AppData XML itself (`AppData` inner class) and sets each property by hand |
| `transient_for` | main window | set in `main_window.rb`'s `about_dialog` memo |
| `hide_on_close` | `true` | `about.hide_on_close = true`, present |
| `translator_credits` | `_("translator-credits")` | present |
| `copyright` | `"© 2018–%i %s" % [year, developer_name]` | `format('© 2018–%d %s', Time.now.year, @appdata.developer_name)`, present |
| License mapping | N/A (native `project_license` property) | port adds `LICENSES` SPDX→`Gtk::License` table since it must do by hand what `from_appdata` would have done; falls back to `CUSTOM` + raw SPDX string |

Kind: **dialog**. Present, matches, including the one behavioural piece
(`hide_on_close`, so the About button reuses the same window instance) that
is easy to drop in a port and wasn't.

### `src/Config.vala.in` + root `meson.build` conf → `lib/config.rb` (exists)

Not a widget — build-time constants (`APP_ID`, `VERSION`, `GETTEXT_PACKAGE`,
locale dir). Present as literals since there is no configure step. Kind:
**support module**.

### `data/gresource.xml` + icon/install rules in `data/meson.build` → `lib/resources.rb` (exists)

Upstream's GResource bundle (metainfo, stylesheet, about-symbolic icon) plus
the install-time icon renames (`app.svg`/`symbolic.svg` → app-id-named icons
in `hicolor/scalable/apps`). Port has no GResource; `Resources.register`
adds `data/icons` to the icon theme search path instead, and `Resources::METAINFO`
points at the appdata file directly. Kind: **support module**. Present,
matches in effect.

### `data/styles/style.css` → `lib/style.rb` (exists)

One rule block, tinting window bg/fg with the accent colour via
`color-mix`. Port loads the same file through a `Gtk::CssProvider` at
application priority. Kind: **stylesheet / support module**. Present,
matches.

### `src/Application.vala`'s `Intl.bindtextdomain` calls → `lib/intl.rb` (exists)

Kind: **support module**. Present, matches (binds the same gettext domain
for both the pure-Ruby `gettext` gem and GLib's own catalogue).

### `po/*.po`, `po/POTFILES.in`, `po/com.cassidyjames.clairvoyant.pot` → `po/` (exists)

The full upstream catalogue (200+ locale files plus the template) is present
unchanged in the port's `po/` directory.

### `data/metainfo.appdata.xml.in` → read at runtime by `AboutDialog::AppData` (no port file of its own)

Not transcribed into Ruby; the port reads upstream's own XML file at runtime
(`Resources::METAINFO`), which is a stronger form of parity than duplicating
its content in source. Not a gap.

## Non-components (confirmed absent upstream, so absent is correct)

- No `.ui`/`.blp` files anywhere in the tree — confirmed by `git ls-tree` and a
  `.ui`/`.blp` search; nothing for the port to be missing.
- No GSettings schema (`*.gschema.xml`).
- No shortcuts window, no preferences dialog/window.
- No submenus or `Gio.Menu` models.
- No submodules (`.gitmodules` absent).
- Only one GTK-level action exists in the whole app (`app.quit`); it is
  present and correctly wired (see Application above).

## Residual notes (not gaps — worth a second look)

- `about_dialog.rb`'s `AppData` parser is a hand-rolled AppStream-XML reader
  (regex-based, explicitly because `rexml` is "not in the port's gem
  closure"). This is the kind of thing the accountability audit looks for as
  a hand-rolled substitute for a gem — but it is not standing in for one of
  this app's two mandated gems (`gtk4`/`adwaita`/`glib2` plus `ashpd`;
  clairvoyant has no portal use, so `ashpd` does not apply to this app at
  all) — it is substituting for `rexml`, a stdlib library, on a fixed,
  trusted, ship-with-the-app document. Flagging for visibility, not fixing
  as part of this survey (survey step does not write app code).
- `clairvoyant-rb.gemspec` and `nix/Gemfile` were not audited for the
  `ashpd`/gem-wiring checklist in this step, since the survey's job is the
  component inventory; that is a separate pass if the maintainers want it,
  and this app does not call any portal API (no file chooser, no
  background/autostart, no notifications) that `ashpd` would cover.

## Totals

- Upstream user-facing units: 4 (`Application`, `MainWindow`, `FortuneLabel`,
  the inline `AboutWindow`) + 1 data table + 3 support concerns (config,
  resources/icons, stylesheet) + gettext wiring.
- Port `lib/*.rb` files: 10, one per upstream unit/concern (`about_dialog.rb`,
  `application.rb`, `clairvoyant.rb` (gem entry point), `config.rb`,
  `fortune_label.rb`, `fortunes.rb`, `intl.rb`, `main_window.rb`,
  `resources.rb`, `style.rb`), plus `clairvoyant/rb/version.rb` (gem
  scaffolding, not an upstream port unit).
- Components found missing from the port: **0**.
