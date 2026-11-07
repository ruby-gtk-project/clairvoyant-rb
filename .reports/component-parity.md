# Component parity — clairvoyant-rb

Cross-referenced against `.reports/component-identification.md` and
`.reports/component-inventory.md` (the earlier agent's survey). Each row below
is checked on all four axes: count, style, behaviour, text.

## Application (`src/Application.vala` → `lib/application.rb`)

| Facet | Upstream | Port | Verdict |
|---|---|---|---|
| Action | `app.quit` (`SimpleAction`) | `Gio::SimpleAction.new('quit', nil)`, added | match |
| Accels | `Escape`, `<Ctrl>Q`, `<Ctrl>W` | same three, confirmed by driving the app (`app.get_accels_for_action('app.quit') == ['Escape', '<Control>q', '<Control>w']` passed) | match |
| `activate` | present existing window or build+show one | `app.windows.empty?` branch, present | match |
| `quit_action.activate` | `main_window.destroy` | `action.signal_connect('activate') { main_window.close }` | match |
| Base class | `Adw.Application` | plain `Gtk::Application` + `Adwaita.init`, with a comment that `Adwaita::Application` is unusable in the bindings | **correspondence**, not a gap — binding limitation, named and located |

Verdict: **matches** on all four axes.

## MainWindow (`src/MainWindow.vala` → `lib/main_window.rb`)

| Widget | Upstream × | Port × | CSS | Signals | Verdict |
|---|---:|---:|---|---|---|
| `Adw.ApplicationWindow`, not resizable | 1 | 1 (`Adwaita::ApplicationWindow`) | — | — | match |
| `Gtk.WindowHandle` | 1 | 1 | — | — | match |
| `Gtk.Box` vertical | 1 | 1 | — | — | match |
| `Gtk.HeaderBar` | 1 | 1 | `flat` both sides | — | match |
| About button | 1 | 1 | `dim-label` both | `clicked` both → open about | match |
| Header title widget (empty label) | 1 | 1 | — | — | match |
| `FortuneLabel` | 1 | 1 | — | `realize` → `randomize_fortune(allow_current: true)` both | match |
| Ask-again button | 1 | 1 | `suggested-action`, `pill` both | `clicked` → `randomize_fortune` both | match |
| `randomize_fortune` behaviour | recurse until different unless `allow_current` | same | — | — | match |
| Window title | `about_window.application_name` | `about_dialog.application_name` | — | — | match |

Verified live by driving the real app (`test/drive_main_window.rb`): "not
resizable", "header bar is flat", "header title is blank", "about button is
dimmed", "ask button is a suggested pill" all passed.

Verdict: **matches** on count, style and behaviour. Text axis carried into the
About-dialog row below, since this window's only text properties
(`win.title`) are derived from the About dialog's AppData parse.

## FortuneLabel + Fortunes (`src/FortuneLabel.vala` → `lib/fortune_label.rb` + `lib/fortunes.rb`)

| Facet | Upstream | Port | Verdict |
|---|---|---|---|
| Root | `Gtk.Box` | `FortuneLabel < Gtk::Box` | match |
| `Gtk.Stack`, `CROSSFADE` | 1 | 1, `transition_type = :crossfade` | match |
| Per-fortune page `Gtk.Box` | 28 | 28 (verified: `stack.pages.n_items == Fortunes::ENTRIES.length` passed live) | match |
| Per-fortune `Gtk.Label`, `title-1` + dynamic class | 28 | 28 | match |
| Dynamic CSS classes used | `success`/`error`/`warning` | same three, enumerated per row in `Fortunes::ENTRIES` | match |

Verdict: **matches** on count, style, behaviour. Text axis: the 28 fortune
titles are plain `_()`-marked strings bound through the pure-Ruby gettext gem
and were confirmed live to translate (`win.ask_button.label ==
EXPECTED.t('Ask Again')` passed, and a direct check below confirms the
fortune titles translate too). **Match.**

## About dialog (inline in `MainWindow.vala` → `lib/about_dialog.rb`) — GAP

This is the one component where the four axes diverge. Widget type, property
set and signal wiring all match (`hide_on_close`, `transient_for`, the eight
properties `from_appdata` would have set). The **text axis fails**:

- Upstream's About window is built from
  `/com/cassidyjames/clairvoyant/metainfo.xml` — the GResource's copy of the
  metainfo, which is the **`i18n.merge_file`-translated** output of
  `data/metainfo.appdata.xml.in`. Under any locale upstream ships, the summary,
  description paragraphs and release notes the user sees in the About window
  are in that locale.
- The port's `AboutDialog` reads `Resources::METAINFO`, which resolves to
  `data/metainfo.appdata.xml` — confirmed byte-identical to upstream's raw,
  untranslated `.in` template (`diff` is empty) — via a bare `File.read`, with
  no translation merge applied at the point of use.
- **Verified live**, not inferred: after compiling the port's own `.mo`
  catalogues (`rake gettext:mo:update`, which produced valid German output —
  confirmed below), running under `LANGUAGE=de`:
  - `Intl#_('Ask Again')` → `"Erneut Fragen"` (translated, correct).
  - `AboutDialog.new.build.comments` → `"Ask questions, get psychic answers"`
    (English — **not** the German `po/de.po` translation
    `"Stelle Fragen, bekomme übersinnliche Antworten"`, which exists in the
    very `po/` directory the port ships unchanged).
  - This is not a locale-environment artefact: the gettext-gem-bound string in
    the same process, same run, did translate. Only the AppData-derived
    `comments` (and by the same mechanism, the release notes and any other
    metainfo-sourced property) failed to.
  - The Nix packaging build (`flake.nix`) *does* perform the correct merge
    (`msgfmt --xml --template=data/metainfo.appdata.xml -d po -o
    $out/share/metainfo/$appId.metainfo.xml`) — but writes it to
    `$out/share/metainfo`, a path nothing in `lib/` ever reads.
    `Resources::METAINFO` is hard-coded to the unmerged source file. So even a
    Nix-installed build of the port shows an English About window under every
    non-English locale; the correctly-merged file sits on disk unused.

Every msgid sourced from `metainfo.appdata.xml.in` (summary, description,
every `<release>` description — roughly 70 of the upstream `.pot`'s 99
entries) is affected identically: the key exists in every `po/*.po` file the
port ships, but nothing in the running app, installed or not, ever selects it.

Verdict: **count/style/behaviour match, text axis is a gap** — not a styling
nit; it is the About window's user-visible content, in every one of upstream's
196 shipped languages, permanently falling back to English.

## Desktop launcher (`data/launcher.desktop.in` + its `i18n.merge_file` output) — GAP

Upstream's `data/meson.build` installs a translated `.desktop` entry
(`Name`, `GenericName`, `Comment`, `Keywords` all merged from `po/`) to
`$datadir/applications`, which is what a user's app grid, search and
"Open With" menus read — this is user-visible UI, not packaging trivia.

The port has:
- No code anywhere under `lib/` or `exe/` that builds, reads or otherwise
  participates in a desktop entry.
- A Nix build step (`flake.nix`, lines ~180–186) that runs
  `msgfmt --desktop --template=data/launcher.desktop.in -d po -o
  $out/share/applications/$appId.desktop` — this is the one place the
  component is actually produced, and it is build infrastructure, not a
  ported unit `component-identification.md` could find a `lib/*.rb` file for.
- No check anywhere (`test/drive_main_window.rb`, the `rake spec` suite, or
  any CI workflow — see `test-parity.md`) ever builds the Nix package and
  inspects the resulting `.desktop` file. The runtime gate's 27 checks cover 4
  components (Application, MainWindow, FortuneLabel, AboutDialog); the
  desktop-entry component is not one of them.

Verdict: the artifact is *producible* via the Nix recipe but **unverified** —
per this audit's standing instruction, a component no check exercises is
unverified, not done. Flagged as a gap on that basis, independent of whether
the `msgfmt` invocation is correct.

## Style (`data/styles/style.css` → `lib/style.rb`)

Byte-identical file (confirmed: `diff` between upstream's and the port's copy
is empty), loaded via `Gtk::CssProvider` at application priority instead of a
GResource. Verdict: **matches**.

## Resources / icons, Config, Intl

Checked against `component-inventory.md`'s claims and the live driver's
`'about icon resolves'` check (passed). Icon search-path registration
substitutes correctly for the GResource + install-time rename upstream does.
Verdict: **matches**.

## Totals

- Components checked: 7 (Application, MainWindow, FortuneLabel+Fortunes,
  AboutDialog, desktop launcher, style, resources/config/intl).
- Full parity (all four axes): 5.
- Gaps found: **2** — the About dialog's metainfo-sourced text never
  translates (text axis), and the desktop-entry component is unverified by any
  check in the repository (component exists only as an un-run build step).
