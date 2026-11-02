# Clairvoyant — upstream component inventory

Survey of `origin/main` (Vala, meson, GTK4 >= 4.19.4 / libadwaita >= 1.8.1,
upstream version 3.1.12) against `lib/` on the `ruby` branch.

Upstream has **no `.ui` and no `.blp` files** — every widget is built in Vala
`construct` blocks, so the inventory below comes from reading all three source
files. There is **no GSettings schema** (`build-aux/meson/post_install.py`
calls `glib-compile-schemas`, but no `.gschema.xml` exists in the tree), **no
`GtkBuilder` menu model**, and **no preferences dialog**. The whole app is one
non-resizable window with a header bar, a crossfading stack of 28 fortunes and
an "Ask Again" button.

## Component map

| # | Upstream file(s) | Port file | Kind | Exists on `ruby`? |
|---|---|---|---:|---|
| 1 | `src/Application.vala`, `src/Config.vala.in`, `src/config.vapi` | `lib/application.rb` | application | partial — scaffold only |
| 2 | `src/MainWindow.vala` | `lib/main_window.rb` | window | no |
| 3 | `src/MainWindow.vala` (header bar + About button) | `lib/main_window.rb` | header bar | no |
| 4 | `src/MainWindow.vala` (`Adw.AboutWindow.from_appdata`), `data/metainfo.appdata.xml.in` | `lib/about_dialog.rb` | dialog | no |
| 5 | `src/FortuneLabel.vala` | `lib/fortune_label.rb` | widget (stack of 28 pages) | no |
| 6 | `src/FortuneLabel.vala` (the 28-entry `Content[]` table) | `lib/fortunes.rb` | data / strings | no |
| 7 | `src/Application.vala` (`app.quit` + accels) | `lib/application.rb` | action + shortcuts | no |
| 8 | `data/styles/style.css` | `lib/style.rb` (inline `Gtk::CssProvider`) | stylesheet | no |
| 9 | `data/gresource.xml`, `data/icons/about-symbolic.svg` | `lib/resources.rb` (icon theme search path / resource load) | resources | no |
| 10 | `po/` (196 locales, `po/POTFILES.in`) | `po/` + gettext in `lib/fortunes.rb` etc. | translations | no |

There are no pages, rows, menus, empty states or error states upstream — the
app has no list, no navigation and no failure path.

## src/Application.vala — the application object, actions and accelerators

| Widget / object | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.Application` | 1 | — | `activate` (overridden `activate ()`) | `application_id = APP_ID` (`com.cassidyjames.clairvoyant`), `flags = FLAGS_NONE` |
| `Gio.SimpleAction` "quit" | 1 | — | `activate` → destroys the main window | installed on the **app** (`app.quit`) |
| `MainWindow` | 1 | — | — | built in `activate`, then `show ()` |

Accelerators for `app.quit`: **`Escape`**, **`<Ctrl>Q`**, **`<Ctrl>W`** — all
three, which is the whole keyboard interface of the app. There is no shortcuts
window.

Single-instance behaviour: `activate` presents the existing window when
`get_windows ().length () > 0` instead of building a second one.

`main ()` does gettext setup (`bindtextdomain`, `bind_textdomain_codeset
"UTF-8"`, `textdomain`) with `Config.GETTEXT_PACKAGE` /`Config.LOCALEDIR`;
`src/Config.vala.in` supplies `APP_ID` and `VERSION` at configure time.

Port status: `lib/clairvoyant/application.rb` exists but is the generated
scaffold — a `Gtk::Application` with id `org.rubygtkproject.Clairvoyant`, an
`Adwaita::ApplicationWindow` sized 800x600, an `Adwaita::ToolbarView`, an empty
`Adwaita::HeaderBar` and an `Adwaita::StatusPage` reading "The Ruby port has
not been written yet." None of it corresponds to an upstream component; the
status page is an **extra** to delete, and the window must become
non-resizable rather than 800x600. No actions, no accelerators.

## src/MainWindow.vala — the one window: header bar, fortune, Ask Again

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | — | `icon_name = APP_ID`, **`resizable = false`**, `title` taken from the About window's `application_name` |
| `Gtk.WindowHandle` | 1 | — | — | window content; wraps the whole layout so the body is draggable |
| `Gtk.Box` (vertical, spacing 0) | 1 | — | — | header + fortune + button |
| `Gtk.HeaderBar` | 1 | `flat` | — | `title_widget = new Gtk.Label (null)` (empty title), packed **inside the box**, not via a toolbar view |
| `Gtk.Label` (header title widget) | 1 | — | — | deliberately blank |
| `Gtk.Button` (About, `from_icon_name "about-symbolic"`) | 1 | `dim-label` | `clicked` → `about_window.present ()` | `tooltip_text = _("About")`, `pack_start` |
| `Adw.AboutWindow` (`from_appdata`) | 1 | — | — | from `/com/cassidyjames/clairvoyant/metainfo.xml` + `VERSION`; `transient_for = this`, `hide_on_close = true`, `translator_credits = _("translator-credits")`, `copyright = "© 2018–%i %s"` with the current year and `developer_name` |
| `FortuneLabel` | 1 | — | `realize` → `randomize_fortune (…, allow_current: true)` | `margin_top = 24`, `margin_bottom = 24` |
| `Gtk.Button` (`with_label _("Ask Again")`) | 1 | `suggested-action`, `pill` | `clicked` → `randomize_fortune` | `halign = CENTER`, `margin_bottom = 48` |

Behaviour that must be ported, not just the tree:

- `randomize_fortune (label, allow_current = false)` draws
  `Random.int_range (1, 29)` (1..28 inclusive) and sets
  `stack.visible_child_name`; when `allow_current` is false it **recurses**
  until the new fortune differs from the current one, so pressing "Ask Again"
  never shows the same answer twice in a row.
- The first fortune is re-rolled on `realize` with `allow_current = true`.
- The window title and the copyright line are derived from the parsed
  appdata at runtime — `Adw.AboutWindow.from_appdata` has **no Ruby
  equivalent in common use**; the port will need an
  `Adwaita::AboutDialog`/`AboutWindow` filled from constants or from the
  metainfo file explicitly.

Port status: **absent entirely.** No `lib/main_window.rb`.

## src/FortuneLabel.vala — the crossfading stack of 28 answers

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Box` (the `FortuneLabel` subclass itself) | 1 | — | — | subclasses `Gtk.Box`; exposes `public Gtk.Stack stack` |
| `Gtk.Stack` | 1 | — | — | `transition_type = CROSSFADE`; children named `"1"`..`"28"` via `add_named` |
| `Gtk.Box` (vertical, per page) | **28** (repeater) | — | — | `margin_start = 24`, `margin_end = 24`, `halign = CENTER` |
| `Gtk.Label` (per page) | **28** (repeater) | `title-1` **plus** one of `success` / `warning` / `error` | — | `selectable = true` |

Repeater: one page per entry of the static `Content[] content` table, built in
a `foreach` with a 1-based index. Dynamic CSS class: the second class on each
label is `fortune.css_class`, which takes exactly three values —
`success` (14 fortunes), `error` (7 fortunes), `warning` (7 fortunes).

Initial state: the constructor already picks `Random.int_range (1, 29)` for
`visible_child_name`, which `MainWindow`'s `realize` handler then re-rolls.

### The 28 fortunes, in upstream order (stack names 1..28)

| # | String | Class |
|---:|---|---|
| 1 | It is certain. | `success` |
| 2 | It is decidedly so. | `success` |
| 3 | Without a doubt. | `success` |
| 4 | Yes—definitely. | `success` |
| 5 | You may rely on it. | `success` |
| 6 | As I see it, yes. | `success` |
| 7 | Most likely. | `success` |
| 8 | Outlook good. | `success` |
| 9 | Yes. | `success` |
| 10 | Signs point to yes. | `success` |
| 11 | Yep! | `success` |
| 12 | Absolutely! | `success` |
| 13 | You bet! | `success` |
| 14 | Confirmed. | `success` |
| 15 | Don’t count on it. | `error` |
| 16 | My reply is no. | `error` |
| 17 | My sources say no. | `error` |
| 18 | Outlook not so good. | `error` |
| 19 | Very doubtful. | `error` |
| 20 | Naw. | `error` |
| 21 | I’ve got a bad feeling about this… | `error` |
| 22 | Reply hazy, try again. | `warning` |
| 23 | Ask again later. | `warning` |
| 24 | Better not tell you now. | `warning` |
| 25 | Cannot predict now. | `warning` |
| 26 | Concentrate and ask again. | `warning` |
| 27 | Impossible to see, the future is. | `warning` |
| 28 | 404 Answer Not Found | `warning` |

Every string is `_()`-wrapped and carries a `///TRANSLATORS:` comment (except
#14, "Confirmed.", which has none). The typography is load-bearing: curly
apostrophes (`Don’t`, `I’ve`), an em dash in `Yes—definitely.`, and an
ellipsis character in #21.

Port status: **absent entirely.** No `lib/fortune_label.rb`, no fortune table.

## data/styles/style.css — the accent-tinted window

```css
:root {
  --window-bg-color: color-mix(in oklab, var(--accent-color), var(--view-bg-color) 90%);
  --window-fg-color: color-mix(in oklab, var(--accent-color), var(--view-fg-color) 50%);
}
```

Two custom properties, no classes of its own — it recolours the window from
the user's accent colour. Loaded from the GResource bundle
(`/com/cassidyjames/clairvoyant/style.css`); the port has to load equivalent
CSS through a `Gtk::CssProvider` on the default display. **Absent on `ruby`.**

No CSS class used in the source is defined by this stylesheet — `flat`,
`dim-label`, `suggested-action`, `pill`, `title-1`, `success`, `warning`,
`error` all come from libadwaita.

## data/gresource.xml, data/icons — resources

| Resource | Path in bundle | Needed by |
|---|---|---|
| `metainfo.appdata.xml.in` | `/com/cassidyjames/clairvoyant/metainfo.xml` | `Adw.AboutWindow.from_appdata` |
| `styles/style.css` | `/com/cassidyjames/clairvoyant/style.css` | window colours |
| `icons/about-symbolic.svg` | `…/icons/scalable/actions/about-symbolic.svg` | the header bar's About button |

Also installed outside the bundle: `data/icons/app.svg` (hicolor scalable app
icon) and `data/icons/symbolic.svg` (hicolor symbolic app icon), both renamed
to the app id. `data/launcher.desktop.in` carries `GenericName=Fortune
Teller`, `Comment=Ask questions, get psychic answers`,
`Categories=Utility;Amusement;` and
`Keywords=magic;eight;ball;8;crystal;🔮;medium;🎱;`.

The port currently ships no icons and references
`applications-engineering-symbolic` from the system theme. **Absent on
`ruby`.**

## po/ — translations

`po/LINGUAS` lists **196 locales**; `po/POTFILES.in` covers
`data/launcher.desktop.in`, `data/metainfo.appdata.xml.in`,
`src/Application.vala`, `src/FortuneLabel.vala` and `src/MainWindow.vala`.
Translatable strings in code are exactly: the 28 fortunes, `_("About")`,
`_("Ask Again")` and `_("translator-credits")` — 31 in total. **Nothing on
`ruby`.**

## Summary

| | Upstream | `ruby` |
|---|---:|---:|
| Component files | 3 Vala (+1 CSS, 1 gresource) | 1 (scaffold) |
| Distinct widget types | 8 | 5 |
| Widget instances (counting repeaters) | ~62 | 4 |
| Distinct CSS classes applied | 8 | 0 |
| Signals connected | 4 (`activate`, `clicked` ×2, `realize`) | 1 (`activate`) |
| Actions | 1 (`app.quit`, 3 accels) | 0 |
| Translated strings | 31 | 0 |

Nothing user-facing is ported yet. The three files to write are
`lib/fortune_label.rb` (with the fortune table, inline or in
`lib/fortunes.rb`), `lib/main_window.rb` and `lib/application.rb`; the
existing `lib/clairvoyant/application.rb` scaffold and its status page go
away.
