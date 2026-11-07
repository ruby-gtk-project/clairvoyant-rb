# Component inventory — clairvoyant-rb

Upstream is `cassidyjames/clairvoyant`, read at `origin/main` in this clone.
It is a three-file Vala app with no `.ui`/`.blp` templates, no GSettings
schema, and no GResource menu — every widget is built in code, so the scan
below is a straight read of the three source files plus the AppData the About
window consumes and the one stylesheet. `po/POTFILES.in` names the full
translatable surface (`src/FortuneLabel.vala`, `src/MainWindow.vala`,
`data/com.cassidyjames.clairvoyant.metainfo.xml.in`); no other upstream file
contributes user-facing strings.

Order below is the order a user meets them: the application, then the window,
then the window's two pieces (the fortune, the About dialog), then the two
supporting files that have no widgets of their own.

## src/Application.vala — the application object

| Item | Detail |
|---|---|
| Class | `Clairvoyant : Adw.Application` |
| Action | `app.quit` — `SimpleAction`, installed on the application |
| Accels | `app.quit` → `Escape`, `<Ctrl>Q`, `<Ctrl>W` |
| Behaviour | `activate`: presents the existing window if one is already up, otherwise builds `MainWindow` and shows it; `quit_action.activate` destroys the main window |

**Port status: exists.** `lib/application.rb` — `Application`. Builds a
`Gtk::Application` (not `Adwaita::Application`, which the port's comments say
is broken in the Ruby bindings) with `Adwaita.init` called by hand, reproduces
the activate-presents-existing-window branch, and installs `quit_action` with
the same three accels (`QUIT_ACCELS`) on `app.quit`. Full behavioural parity;
no gap.

## src/MainWindow.vala — the one window the app has

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | — | not resizable, `icon_name = APP_ID` |
| `Gtk.WindowHandle` | 1 | — | — | wraps the whole layout so the entire surface drags the window |
| `Gtk.Box` (vertical) | 1 | — | — | `main_layout`: header, fortune, button |
| `Gtk.HeaderBar` | 1 | `flat` | — | empty `title_widget` (a bare `Gtk.Label`) |
| `Gtk.Button` | 1 | `dim-label` | `clicked` → presents the About window | the About button, icon `about-symbolic`, packed at header start |
| `FortuneLabel` | 1 | — | `realize` → `randomize_fortune(allow_current: true)` | the component below; `margin_top`/`margin_bottom` 24 |
| `Gtk.Button` | 1 | `suggested-action`, `pill` | `clicked` → `randomize_fortune` | label "Ask Again", `halign: center`, `margin_bottom` 48 |
| `Adw.AboutWindow` | 1 | — | — | built via `.from_appdata`; see the About dialog row below |

Behaviour: `randomize_fortune(allow_current)` draws `Random.int_range(1, 29)`
and re-draws until it differs from the stack's current page unless
`allow_current` is set; the window's title is taken from
`about_window.application_name` after the AboutWindow parses the AppData.

**Port status: exists.** `lib/main_window.rb` — `MainWindow`. Every widget,
CSS class and signal above has a memoized accessor and a matching
`signal_connect`: `window` (`Adwaita::ApplicationWindow`, not resizable),
`window_handle`, `main_layout`, `header` (`flat`), `about_button`
(`dim-label`, `about-symbolic` icon, `clicked` → `about_dialog.present`),
`fortune_label` (margins 24/24, `realize` → `randomize_fortune(allow_current:
true)`), `ask_button` (`suggested-action`, `pill`, label "Ask Again",
`clicked` → `randomize_fortune`). `randomize_fortune` reproduces the
redraw-until-different logic via `Fortunes.random_page_name`. Window title is
set from `about_dialog.application_name`, matching upstream's AppData-sourced
title. No gap.

## src/FortuneLabel.vala — the fortune on screen

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` (self, horizontal in the port / unspecified orientation upstream*) | 1 | — | — | the component's own root |
| `Gtk.Stack` | 1 | — | — | `transition_type: crossfade`; `public`, driven by `MainWindow` |
| `Gtk.Box` (vertical) | 28 | — | — | one per fortune; `margin_start`/`margin_end` 24, `halign: center` — a **repeater** over the 28-row table |
| `Gtk.Label` | 28 | `title-1` + one of `success` / `error` / `warning` (dynamic, per-fortune) | — | `selectable = true`; the fortune's translated text |

*Upstream's `FortuneLabel : Gtk.Box` has no explicit orientation set on
itself (Vala/GTK default is horizontal); the port's `super(:horizontal, 0)`
matches that default explicitly — not a gap, just worth naming since it is
the one place the port is more explicit than upstream.

Data: upstream's `static Content[] content` — 28 literal entries, each a
`{title, css_class}` pair, `css_class` ∈ {`success`, `error`, `warning`}: 14
`success`, 7 `error`, 7 `warning`.

**Port status: exists**, split across two files as the house style allows for
a data table:
- `lib/fortune_label.rb` — `FortuneLabel < Gtk::Box`. Builds the `Gtk::Stack`
  (`crossfade`), the 28 `page()` boxes (margins 24/24, `halign: center`) and
  the 28 `title_label()` labels (`selectable`, `title-1` + the fortune's own
  css class) via `Fortunes.page_names.each`. `stack` is a public memoized
  accessor, matching upstream's public field.
- `lib/fortunes.rb` — `Fortunes` module. The 28-row `TABLE`, each `[N_(title),
  css_class]`, counted: 14 `SUCCESS`, 7 `ERROR`, 7 `WARNING` — matches
  upstream's table exactly row for row (spot-checked the full list against
  `src/FortuneLabel.vala`: titles and class assignments line up one to one).
  `page_names`/`random_page_name` reproduce the 1-based `i.to_string()` paging
  upstream's stack and randomizer rely on.

No gap.

## data/metainfo.appdata.xml.in — the About window's data source

Not a widget file, but it is what upstream's `Adw.AboutWindow.from_appdata`
reads to populate the dialog `MainWindow` presents, and `.from_appdata` is not
bound in the Ruby `adwaita` gem (only the plain constructor is), so this is a
real porting unit in its own right.

Upstream-derived fields the About window shows: `application_name` (`<name>`),
`application_icon`/id (`<id>`), `developer_name` (`<developer_name>` or
`<developer><name>`), `comments` (`<summary>`), `license_type`/`license`
(`<project_license>`, SPDX → `Gtk::License`), `website`/`issue_url`/
`support_url` (`<url type="homepage"/"bugtracker"/"help">`), `version` +
matching `<release>`'s `<description>` as `release_notes`, `copyright` (built
from the current year + developer name, same as upstream's `"© 2018–%i
%s".printf(...)`), and `translator_credits`.

**Port status: exists.** `lib/about_dialog.rb` — `AboutDialog <
Adwaita::AboutWindow`, with a nested `AppData` class that regex-reads the
same tags (documented in-file as a deliberate substitute for `.from_appdata`
and for `rexml`, which is outside the port's gem closure) and a `LICENSES`
table mapping the SPDX ids this app's metadata can name to `Gtk::License`
constants. Every field upstream's dialog shows has a matching assignment.
`hide_on_close = true` reproduces upstream's `hide_on_close` so the same
instance comes back on a second click. No gap.

## data/gresource.xml + data/styles/style.css — resources and the stylesheet

No widgets; two supporting units the port needs its own equivalent of because
it has no GResource compiler.

- **Icons** (`about-symbolic.svg`, plus the app icon upstream's `meson.build`
  installs under the app ID). **Port status: exists** — `lib/resources.rb`
  adds `data/icons` to the display's icon theme search path at activation.
- **Stylesheet** (`:root { --window-bg-color: …; --window-fg-color: … }`,
  tinting the window with the accent colour). **Port status: exists** —
  `lib/style.rb` loads the same CSS file through a `Gtk::CssProvider` at
  `PRIORITY_APPLICATION`, same priority band GResource auto-loading gives it.

## src/Config.vala.in, src/config.vapi — build-time constants

`APP_ID`, `VERSION`, `GETTEXT_PACKAGE`, `LOCALEDIR` — meson substitutions, no
widgets. **Port status: exists** — `lib/config.rb` (`APP_ID`, `VERSION`,
`GETTEXT_PACKAGE`, `DATA_DIR`, `LOCALE_DIR` as literals, since the port has no
configure step).

## Application.vala's `main()` — gettext binding

`Intl.bindtextdomain`/`bind_textdomain_codeset`/`textdomain` against
`Config.GETTEXT_PACKAGE`/`LOCALEDIR`. **Port status: exists** —
`lib/intl.rb` binds the same domain through the `gettext` gem (for the app's
own strings) and `GLib::GetText` (for GLib/AppStream strings), against
`Config::GETTEXT_PACKAGE`/`LOCALE_DIR`.

## Not present upstream — confirmed absent, not a port gap

- **No GSettings schema.** No `.gschema.xml` anywhere in `origin/main`'s
  tree; nothing in `src/` calls `Gio.Settings`. There is nothing for the
  port to bind.
- **No GResource menu, no `Gtk.PopoverMenu`, no `Gio.Menu`.** The only
  `Gio.SimpleAction` upstream installs is `app.quit`, already covered above.
- **No shortcuts window / `Gtk.ShortcutsWindow`.** The only keyboard
  entry points are the three `app.quit` accels, already covered above.
- **No `.ui`/`.blp` files at all** — `find . -name '*.blp' -o -name '*.ui'`
  against `origin/main`'s tree returns nothing; every widget upstream builds
  is built in `src/*.vala`, which this inventory read directly.
- **`po/` catalogue** (182 `.po` files + the `.pot`) is counted and checked by
  `translation-parity`, not by this component inventory. Naming it here so no
  later reader mistakes its absence from the tables above for this survey
  having missed it.

## Summary

| Upstream unit | → port file | Kind | Exists on `ruby`? |
|---|---|---|---|
| `src/Application.vala` | `lib/application.rb` | application class | yes |
| `src/MainWindow.vala` | `lib/main_window.rb` | window | yes |
| `src/FortuneLabel.vala` (widgets) | `lib/fortune_label.rb` | composite widget | yes |
| `src/FortuneLabel.vala` (`Content[]` table) | `lib/fortunes.rb` | data table | yes |
| `data/metainfo.appdata.xml.in` (as read by `Adw.AboutWindow.from_appdata`) | `lib/about_dialog.rb` | dialog | yes |
| `data/gresource.xml` (icons) | `lib/resources.rb` | resource loader | yes |
| `data/styles/style.css` | `lib/style.rb` | stylesheet loader | yes |
| `src/Config.vala.in`, `src/config.vapi` | `lib/config.rb` | constants | yes |
| `src/Application.vala`'s `main()` gettext calls | `lib/intl.rb` | i18n binding | yes |

Every upstream file that contributes a user-facing component, action, accel,
or piece of About-dialog data already has a corresponding `lib/*.rb` file on
`ruby`, and each one's widgets, CSS classes and signal connections were
checked line-for-line against upstream's source above — this inventory found
no missing component for `component-parity` to flag as absent. What
`component-parity`, `test-parity` and `translation-parity` still owe this
fork is byte-level verification (string-for-string CSS/signal matching
already spot-checked here, full `po/` catalogue parity, and test coverage),
not new component discovery.
