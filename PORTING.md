# Porting status — clairvoyant-rb

## Upstream

`clairvoyant-rb`, ported to Ruby + GTK4/Libadwaita. Spec is the `origin/main`
ref of this same repository (upstream Vala source), currently at
`f4f3a605` ("ci: only mirror on pushes to main"). Never checked out or
merged — read with `git show origin/main:<path>` and
`git ls-tree -r --name-only origin/main`.

## Done

Components implemented and observed working under the live drive/validation
runs (see Runtime below):

- `lib/application.rb` — ported from `src/Application.vala`
- `lib/main_window.rb` — ported from `src/MainWindow.vala`
- `lib/fortune_label.rb` + `lib/fortunes.rb` — ported from `src/FortuneLabel.vala`
- `lib/about_dialog.rb` — ported from the inline `Adw.AboutWindow.from_appdata`
  construction in `src/MainWindow.vala` plus `data/metainfo.appdata.xml.in`;
  `AboutDialog::AppData` now runs `name`, `summary` and each release note
  through the app's gettext catalogue (fixed in `8f97156`, re-verified live
  this round under `LANGUAGE=de`: the About window's summary comes back
  German)
- `lib/style.rb` — byte-identical copy of `data/styles/style.css`, loaded via
  `Gtk::CssProvider` at application priority
- `lib/config.rb`, `lib/resources.rb`, `lib/intl.rb` — build-time constants,
  icon search-path registration, gettext binding, substituting for upstream's
  `Config.vala.in` and GResource bundle
- `data/launcher.desktop.in` + `data/metainfo.appdata.xml.in` installation —
  produced by `flake.nix`'s `msgfmt --desktop`/`msgfmt --xml` install step and
  now exercised by `test/validate_packaging.rb` (18/18 passing live), closing
  the previously-unverified desktop-entry gap
- Round 2: `desktop-file-validate` (package `desktop-file-utils`) and
  `appstreamcli` (package `appstream`) — the two actual tools upstream's
  `data/meson.build` `validate-desktop`/`validate-appdata` tests invoke — are
  now vendored into `flake.nix`'s dev shell, and `test/validate_packaging.rb`
  runs both for real against the Nix-merged desktop entry and metainfo, with
  upstream's exact `appstreamcli validate --no-net --explain` arguments.
  Previously only 8 hand-picked fields per artifact were checked and neither
  validator binary existed anywhere in this repo's closure; both now pass
  live (confirmed this round).
- Round 2: `rake test` now runs `test/validate_packaging.rb` followed by
  `test/drive_main_window.rb` under `xvfb-run` (confirmed live: 18/18 then
  27/27, `rake test` exits 0). `rake spec` — which the gemspec, `Rakefile`
  banner, and dev-shell banner all advertise — aliases to the same task when
  nothing else (e.g. `kettle-dev`, absent offline) defines `spec` first, so
  neither entry point fails with "Don't know how to build task" any more.

## Runtime

Drive command and result, re-run live this session:

```
nix develop --command xvfb-run -a ruby test/drive_main_window.rb
```

`drive_ok=true`, 27 passed / 0 failed, 4 components covered (Application,
MainWindow, FortuneLabel, AboutDialog). Also runs via `rake test` (and its
`rake spec` alias) now — see Done, above.

Packaging validation, also re-run live this session:

```
nix develop --command ruby test/validate_packaging.rb
```

`VALIDATE OK`, 18 of 18 checks passed — now including the real
`desktop-file-validate` and `appstreamcli validate` calls, not only the
hand-picked field checks.

## Not started

No upstream widget-tree file is without a `lib/*.rb` counterpart — every
class in `src/*.vala` has been ported. The two items this section used to
list — wiring the validators into CI, and giving `test/validate_packaging.rb`
a real counterpart to `desktop-file-validate`/`appstreamcli validate` rather
than a hand-picked field check — were closed by `8f97156` and this round
respectively; see Done, above, and `.github/workflows/drive.yml` /
`test/validate_packaging.rb`. Nothing else is unstarted.

## Open gaps

Per `.reports/`, as of the latest audit (`.reports/accountability-ensurance.md`,
re-verified live this session):

- **Translation coverage (`.reports/translation-parity.md`)** — 68 of
  upstream's 99 `.pot` msgids (69%) are never marked with `_()` anywhere in
  the port and are never emitted for translation, even though all 196
  language catalogues are carried over unchanged in `po/`. Of those 68, the
  one that has a runtime consumer in the port (the About dialog's `summary`)
  was fixed this round (`8f97156`) and confirmed translating live. The
  remaining 68-minus-the-fixed-subset have no runtime consumer in the port
  at all (e.g. desktop-entry `Keywords`, most metainfo `<description>`/
  `<release>` text), so they can never display translated regardless of
  locale or how the app is built/run.
- **Test parity (`.reports/test-parity.md`)** — closed this round:
  `test/validate_packaging.rb` now runs the actual `desktop-file-validate`
  and `appstreamcli validate --no-net --explain` upstream's `meson test`
  targets invoke (both vendored into `flake.nix`'s dev shell), giving
  upstream's 2 validation tests a real, passing, named port-side
  counterpart (18/18, confirmed live). `rake test` now runs it plus
  `test/drive_main_window.rb` (27/27) in one command, and `rake spec` — the
  entry point the gemspec, `Rakefile`, and dev-shell banner all advertise —
  aliases to it, so both entry points that previously failed with "Don't
  know how to build task" now work. Remaining: `.github/workflows/drive.yml`
  still invokes the two test scripts directly rather than through
  `rake test`, so a reader following only the Rakefile/gemspec story and not
  the workflow file would not see that CI already covers this.
- A previously-undocumented desktop-entry difference, found and recorded this
  audit round: the port's `data/launcher.desktop.in` has `Exec=clairvoyant`
  against upstream's `Exec=com.cassidyjames.clairvoyant`. Confirmed correct
  for this port in `.reports/component-identification.md` (the port installs
  under a different executable name), not a defect, but previously unnamed
  anywhere.

Two gaps that were open as of the prior round of `.reports/component-parity.md`
— the About dialog's untranslated metainfo text, and the desktop-entry
component being producible but unverified by any check — were closed this
history (`8f97156`) and are re-verified live above; they are listed under
Done, not here.

## Blockers

- `Adw.Application` cannot be used as the port's application base class —
  the Ruby bindings expose it as unusable (noted directly in
  `lib/main_window.rb`'s comment). The port uses plain `Gtk::Application`
  with `Adwaita.init` instead; this is a binding limitation, not a missing
  feature, and is named at its point of use.
- `rake spec`'s underlying RSpec suite (the gemspec's `kettle-test`/
  `turbo_tests2` tooling) still cannot run offline — `kettle/test/rspec` is
  not resolvable without network access to install dev dependencies. `rake
  spec` itself no longer fails, though: it aliases to `rake test`, this
  round's fix, rather than remaining an undefined task.
- `bundle exec rubocop` still cannot be run offline either: the root
  `Gemfile`'s dev dependencies (including `rubocop`) need `bundle install`
  against rubygems.org, which this environment has no network access for.
