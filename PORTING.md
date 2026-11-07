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
  now exercised by `test/validate_packaging.rb` (16/16 passing live, added in
  `8f97156`), closing the previously-unverified desktop-entry gap

## Runtime

Drive command and result, re-run live this session:

```
nix develop --command xvfb-run -a ruby test/drive_main_window.rb
```

`drive_ok=true`, 27 passed / 0 failed, 4 components covered (Application,
MainWindow, FortuneLabel, AboutDialog). Specs (`rake spec`) not run — see
Open gaps.

Packaging validation, also re-run live this session:

```
nix develop --command ruby test/validate_packaging.rb
```

`VALIDATE OK`, 16 of 16 checks passed.

## Not started

No upstream widget-tree file is without a `lib/*.rb` counterpart — every
class in `src/*.vala` has been ported. What has not been started:

- Wiring either the drive script or `test/validate_packaging.rb` into any
  CI workflow or `rake` task. `.github/` has no `workflows/` directory, and
  `rake spec` does not run (`spec/` is empty and its load path is broken in
  the dev shell), so both checks above still have to be run by hand.
- A port-side counterpart to upstream's 2 packaging-validation tests (the
  ones `desktop-file-validate`/`appstreamcli validate` stand in for via
  `meson test`) with a named, bijective mapping to `test/validate_packaging.rb`.

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
- **Test parity (`.reports/test-parity.md`)** — 0 of upstream's 2 validation
  tests have a named port-side counterpart with the same count/behaviour,
  and `rake spec` — the entry point the gemspec, `Rakefile`, and the dev-shell
  banner all point at — does not run (confirmed by executing it: missing
  dependency, would report 0 examples even if fixed). The port's one real,
  passing check (`test/drive_main_window.rb`, 27/27) is not wired into any
  automated entry point, so nothing currently re-runs it without a human
  remembering to.
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
- `rake spec` cannot currently be fixed without further investigation: its
  failure is a missing/broken load path in the project's own dev shell, not
  something this round traced to a specific dependency fix.
