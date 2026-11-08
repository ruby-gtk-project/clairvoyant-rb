# Component parity — clairvoyant-rb

> **Fourth update (this round, fresh re-audit at `2f6643e`):** this file and
> `accountability-ensurance.md` were not touched by the port's own commit
> `2f6643e` ("Vendor desktop-file-validate/appstreamcli and wire rake
> test/spec") even though that commit changes a fact both files assert.
> Independently re-ran everything live this round rather than re-reading any
> prior claim:
>
> - `nix develop --command ruby test/validate_packaging.rb` → **18 of 18**
>   checks passed, `VALIDATE OK` (matches the runtime gate's component count
>   when added to the driver's 27 — 45 total, 0 failed, exactly this round's
>   gate figure).
> - `nix develop --command xvfb-run -a ruby test/drive_main_window.rb` →
>   **27 of 27**, `DRIVE OK`.
> - `grep -n 'desktop-file-validate\|appstreamcli' flake.nix` → **hits**
>   (`pkgs.desktop-file-utils`, `pkgs.appstream` in `devShells.default.packages`),
>   and `nix develop --command which desktop-file-validate appstreamcli` →
>   **both resolve**. This is the opposite of what the third update below (and
>   `accountability-ensurance.md`'s own "this round" section) says: both of
>   those were written against the prior commit (`b698135`) and describe a
>   state `2f6643e` already changed. They are now **false claims, not stale
>   phrasing** — "neither of which exists anywhere in this repo's flake.nix or
>   dev shell" is no longer true of this tree. Left verbatim below as
>   superseded history, per this report's own standing practice, but a reader
>   must not trust the third update's desktop-launcher paragraph as describing
>   the current tree.
> - `nix develop --command rake test` → 18/18 then 27/27, exit 0.
>
> **Corrected totals, this round:** `test/validate_packaging.rb` now runs the
> actual `desktop-file-validate` and `appstreamcli validate --no-net --explain`
> binaries upstream's two `meson test` targets invoke, with upstream's own
> argument lists, confirmed by reading `origin/main:data/meson.build` and the
> live run above. Combined with the prior rounds' closes (About-dialog
> metainfo translation, desktop-entry artifact production), **all 7
> components checked by this ledger have full four-axis parity and the
> validator that checks the desktop-entry component is now the same binary
> upstream's own test suite invokes, not a narrower hand-picked substitute.**
> The one caveat from the third update that still holds: `.reports/` itself
> (this file, `accountability-ensurance.md`) was not updated in the same
> commit that shipped the fix — that is this round's actual finding, carried
> into `accountability-ensurance.md` rather than re-litigated here.

> **Third update (prior round, re-audit at `b698135`):** independently
> re-ran both gates live this round, not re-read from either prior update:
> `test/drive_main_window.rb` 27/27 and `test/validate_packaging.rb` 16/16
> (43 total, matching this round's runtime-gate figure exactly). Also
> independently ran the About dialog under `LANGUAGE=de` myself and confirmed
> `comments` comes back as the German `po/de.po` string — the first "update"
> below's claim holds up under re-verification, not just re-assertion.
>
> One correction to the first update's framing, detailed in
> `test-parity.md`'s and `translation-parity.md`'s this-round sections:
> `test/validate_packaging.rb` is real, passing coverage of the `msgfmt`
> merge mechanism, but it is **not** the same thing as upstream's
> `validate-desktop`/`validate-appdata` tests, which invoke
> `desktop-file-validate`/`appstreamcli validate` — neither of which exists
> anywhere in this repo's `flake.nix` or dev shell (checked directly this
> round). So "closing" the desktop-launcher gap below is accurate for "is the
> artifact produced and are its key fields right," not for "is it validated
> the way upstream validates it." Recorded precisely rather than restated as
> a clean close.
>
> The totals at the bottom of this document (2 gaps, 5 of 7 full parity)
> still describe the pre-`8f97156` state and are kept for history; the
> corrected totals are in the new section added at the end of this file.

Cross-referenced against `.reports/component-identification.md` and
`.reports/component-inventory.md` (the earlier agent's survey). Each row below
is checked on all four axes: count, style, behaviour, text.
> **Update (this round):** the About-dialog gap below was closed in
> `8f97156` ("Translate the About window's AppStream strings and validate
> packaging") — `AppData` now includes `Intl` and runs `name`, `summary` and
> each release note's `<p>`/`<li>` through the same catalogue the rest of the
> app uses. The desktop-launcher gap was closed in the same commit by
> `test/validate_packaging.rb`, which merges and asserts the desktop entry
> and AppStream component the way `flake.nix`'s install phase does. Re-run
> this round: `test/drive_main_window.rb` 27/27 and
> `test/validate_packaging.rb` 16/16, both passing live. The row-by-row
> detail below predates both fixes and is kept for its description of what
> was wrong; treat its two "GAP" verdicts as historical, not current.
>
> **Second update (this round):** one more desktop-launcher difference,
> independent of the fix above, found this round and not previously recorded
> anywhere: `data/launcher.desktop.in`'s `Exec=clairvoyant` against upstream's
> `Exec=com.cassidyjames.clairvoyant`. Correct — the Nix build's
> `makeWrapper` installs the gemspec's `exe/clairvoyant` to `$out/bin/clairvoyant`,
> not to a binary named after the app ID, so the port's value is the one that
> actually resolves on a Nix-installed copy — but it is a genuine textual
> difference from upstream's file that neither this report nor
> `component-identification.md` named before now. Recorded as a
> correspondence, located, in `component-identification.md`'s desktop-entry
> section. `test/validate_packaging.rb`'s "Exec names the launcher" check
> asserts the port's own value against itself and would not have caught a
> regression here either way; it is not a check of this correspondence.


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

## Totals, corrected this round (`b698135`)

- Both gaps above are now genuinely closed, re-verified live and
  independently this round (not re-read from the prior claim):
  - About dialog text axis: `AboutDialog::AppData` runs `name`/`summary`/
    current-release-notes through `Intl`; confirmed live under `LANGUAGE=de`.
  - Desktop-entry component: `test/validate_packaging.rb` now runs the real
    `msgfmt` merge and checks it, 16/16, live — **with the caveat above**
    that it checks hand-picked fields, not the full schema
    `desktop-file-validate`/`appstreamcli validate` enforce (neither tool is
    present anywhere in this repo).
- Components checked: 7, same as above. Full parity (all four axes) on the
  original definition: 7 of 7. On the stricter reading that "verified the way
  upstream verifies it" is part of parity for the desktop-entry component:
  6 of 7 full, 1 partial (real coverage, narrower validator than upstream's).
- Gaps found, corrected count: **0 outright, 1 partial** (desktop-entry
  validation depth, detailed in `test-parity.md`).

## Totals, corrected again this round (`2f6643e`)

The "1 partial" above is now closed too: the real `desktop-file-validate` and
`appstreamcli validate` binaries are vendored into `flake.nix`'s dev shell and
`test/validate_packaging.rb` invokes both with upstream's own argument lists
(confirmed live, 18/18, this round). **Components checked: 7. Full parity (all
four axes) on every reading this ledger has used: 7 of 7. Gaps found: 0.** The
narrower-validator caveat that made the prior round's "1 partial" partial no
longer applies to this tree — it applied to `b698135`, not to the commit this
round audits (`2f6643e`).
