# Test parity — clairvoyant-rb

> **Update (this round, fresh re-audit at `b698135`):** Independently re-ran
> both scripts live rather than trusting the prior round's numbers:
> `nix develop --command xvfb-run -a ruby test/drive_main_window.rb` → 27/27,
> `DRIVE OK`; `nix develop --command ruby test/validate_packaging.rb` → 16/16,
> `VALIDATE OK`. 27+16 = 43, matching this round's runtime-gate figure exactly.
> `.github/workflows/drive.yml` exists and runs both on every push/PR,
> confirmed by reading it. So far this matches the prior round's claim.
>
> **But two things the prior round's own update note got wrong or left
> unreconciled, found by this round's independent check, not by re-reading the
> claim:**
>
> 1. **This file contradicts itself and was never fixed.** The paragraph below
>    says the "0-of-2" bijection "is now 2-of-2" — but the **Verdict** section
>    further down this same file, untouched since before that note was
>    written, still reads "**Bijection**: 0 of 2 upstream tests have a named
>    port counterpart" and concludes "**Test parity: not established.**" A
>    reader who skips the update note and reads only the verdict — the part of
>    a report most readers go straight to — gets the pre-fix answer. A report
>    whose own top note and own bottom verdict disagree is exactly the kind of
>    drift `accountability-ensurance` is supposed to catch; it is caught here,
>    now, and the stale verdict section below is left word-for-word as
>    historical record, same as this file's own established practice for
>    earlier superseded findings — but flagged here so no one reads past this
>    note and trusts it.
> 2. **"2-of-2" itself overstates what was built.** Upstream's two meson tests
>    invoke real external validators: `desktop-file-validate` and
>    `appstreamcli validate`. Checked this round, directly: `grep -n
>    'desktop-file-validate\|appstreamcli' flake.nix` — no hits, anywhere, not
>    in the build, not in the dev shell's `nativeBuildInputs`; and `nix
>    develop --command which desktop-file-validate appstreamcli` — neither
>    binary exists in the dev shell's `PATH` (only `msgfmt` resolved).
>    `test/validate_packaging.rb` does run the real `msgfmt --desktop`/`--xml`
>    merge (genuine, confirmed live) but then checks only the 8 fields its own
>    source names per artifact (`Name` non-empty, `GenericName` ==
>    `'Fortune Teller'`, etc.) — a hand-picked subset the port's author chose,
>    not the full desktop-entry/AppStream schema `desktop-file-validate` and
>    `appstreamcli validate` actually enforce (required-key completeness,
>    AppStream XML-schema conformance, icon-theme lookups, and more). This is
>    real, executed coverage of the *merge mechanism* — not a false green —
>    but calling it "now 2-of-2" implies the upstream tests were ported
>    one-for-one, and they were not: the actual validator tools are absent
>    from this repository's closure entirely. Corrected verdict below.
>
> `8f97156` added `test/validate_packaging.rb`, a
> direct port of upstream's two meson tests (`validate-desktop`,
> `validate-appdata`): it runs the same `msgfmt --desktop`/`--xml` merges
> `flake.nix`'s install phase does and asserts the merged desktop entry's and
> AppStream component's required fields. It also removed the empty, broken
> `spec/` scaffolding this report flags below. Re-run this round, both live:
> `test/drive_main_window.rb` 27/27, `test/validate_packaging.rb` 16/16. Both
> are now wired into `.github/workflows/drive.yml`, which runs on every push
> and PR. The upstream-test-count analysis below predates this fix; the
> bijection it describes as 0-of-2 is now 2-of-2.

## Step 1 — census the upstream suite

```
$ git show origin/main:meson.build | grep -i test
(no output)
```

`data/meson.build` registers exactly two `test()` targets:
`validate-desktop` (`desktop-file-validate` against the merged `.desktop`) and
`validate-appdata` (`appstreamcli validate` against the merged metainfo), both
conditional on the validator binaries being found. There is no `tests/`
directory, no unit test of `Application`, `MainWindow` or `FortuneLabel`
anywhere in `origin/main`. **Upstream's test census is N = 2**, both schema
validators over build output, not behavioural tests of app code.

## Step 2 — census the port's suite

```
$ find spec test -type f
spec/README.md
spec/spec_helper.rb
test/drive_main_window.rb
test/gtk_driver.rb
```

- `spec/` — the RSpec suite the gemspec's `kettle-test`/`turbo_tests2`
  tooling and `rake spec` are wired to. **It contains zero spec files.**
  `spec_helper.rb` and `README.md` only. Running it:

  ```
  $ ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(
      ["--format","progress","--require","spec_helper","spec"])'
  An error occurred while loading spec_helper. - Did you mean?
  Failure/Error: require "kettle/test/rspec"
  LoadError: cannot load such file -- kettle/test/rspec
  0 examples, 0 failures, 2 errors occurred outside of examples
  ```

  Confirmed by direct execution inside the project's own dev shell (the
  command the dev shell's own banner prints as "run the specs"): the suite
  does not load — `kettle/test/rspec` is not an installed dependency in this
  environment — and even if it did load, it contains no examples. **This is
  not a suite with full coverage and a broken harness; it is an empty
  directory wired to a task that cannot currently run at all.**

- `test/drive_main_window.rb` + `test/gtk_driver.rb` — a hand-written,
  non-RSpec driver that opens the real app under Xvfb and runs 29 named
  `d.check` assertions grouped into 7 steps. Running it (confirmed live):

  ```
  $ nix develop --command xvfb-run -a ruby test/drive_main_window.rb
  27 of 27 checks passed
  DRIVE OK
  ```

  (27 of the 29 `d.check`/`d.shot` calls are boolean checks; 2 are
  screenshots, not counted as checks — matching the runtime gate's own
  "27 checks passed" figure exactly.)

## Step 3 — the bijection

Upstream's only two tests are the meson `validate-desktop` and
`validate-appdata` targets. Mapping them to the port:

| Upstream test | Behaviour pinned | Port counterpart | State |
|---|---|---|---|
| `validate-desktop` | the merged `.desktop` entry is well-formed | nothing — no test runs `desktop-file-validate` against the Nix-produced `.desktop`, and nothing in `test/` or `spec/` even builds that file | **gap** |
| `validate-appdata` | the merged metainfo XML is valid AppStream | nothing — no test runs `appstreamcli validate` (or any AppStream validation) against either the raw `data/metainfo.appdata.xml` the port reads or the Nix-merged copy it never reads | **gap** |

`test/drive_main_window.rb`'s 27 checks are real, genuinely run, and genuinely
exercise behaviour — but they are not a port of either upstream test, and no
upstream test authorizes their *absence* either. They are additional coverage
the port wrote for itself; they do not close the two-test gap above, because
neither upstream target is a GTK-behaviour check the driver happens to
subsume — they are schema-validation checks of installed artifacts the
driver never touches (the driver runs against `lib/` directly; it never
invokes the Nix build at all).

The driver's 27 checks also are not a *ported* test in the sense this skill
requires regardless: there is no named 1:1 mapping from an upstream test to
each one, because there is no upstream test to map from. They stand as the
port's own, uncensused coverage — valuable, but outside the bijection this
report is required to draw.

## Verdict

- **Count**: upstream 2, port-as-ported 0. **Not equal.**
- **Bijection**: 0 of 2 upstream tests have a named port counterpart.
- **Each pair tests the same thing**: N/A — no pairs exist.
- The one test-looking thing the port *does* run and pass (`test/drive_main_window.rb`,
  27/27, confirmed live) is real, executed, and not a false green — but it is
  not test parity with upstream's suite, and it is not wired into any
  automated entry point (`rake spec`, `rake test`, or a GitHub Actions
  workflow — the port's `.github/` has no `workflows/` directory at all,
  confirmed by listing it, so nothing runs `test/drive_main_window.rb` on
  push, PR or schedule). A human (or this audit) has to remember to run it by
  hand.
- `rake spec`, the task the gemspec, `Rakefile`, and the dev-shell banner all
  point a user at as "the tests", does not run — confirmed by executing it —
  and would report 0 examples even if its missing dependency were installed.

**Test parity: not established — superseded verdict, kept for history; see
this file's top update note for both the fix and this round's correction.**
Two upstream validation tests have no port counterpart and nothing in the
repo checks for either property. The port's nominal test suite (`spec/`) is
empty and its load path is broken in the project's own dev shell. The only
suite that passes (`test/drive_main_window.rb`) is real and does pass, but
runs only when a person remembers to type the command by hand — it is not
continuously verified, and its 27/27 says nothing about the 2 upstream tests
it does not cover.

## Verdict, corrected this round (`b698135`)

- `test/drive_main_window.rb` (27/27) and `test/validate_packaging.rb` (16/16)
  both genuinely run and pass, live, and are both wired into
  `.github/workflows/drive.yml` on push/PR — confirmed by reading the workflow
  file and re-running both scripts independently this round.
- `test/validate_packaging.rb` is a **real but partial** counterpart to
  upstream's `validate-desktop`/`validate-appdata`: it runs the actual
  `msgfmt` merge upstream's install phase runs, then checks 8 hand-picked
  fields per artifact. It does **not** invoke `desktop-file-validate` or
  `appstreamcli validate` — confirmed absent from both `flake.nix` and the dev
  shell's `PATH` this round — so it does not enforce the full schema either of
  those tools enforce. Call this **2 of 2 nominal counterparts exist and pass,
  neither is the actual validator upstream's test runs.**
- `rake spec` / `rake test` remain broken: re-run this round
  (`bundle exec rake spec`), the failure is now "Don't know how to build task
  'spec'" (the task simply doesn't exist, since `8f97156` deleted the empty
  `spec/` scaffolding and no RSpec task is registered without `kettle-dev`) —
  a different error from the prior round's `LoadError`, same underlying fact:
  the entry point the gemspec, `Rakefile` banner and dev-shell banner all
  point at as "the tests" does not run, and isn't exercised by
  `.github/workflows/drive.yml` either.
- **Test parity: still not fully established**, but closer than the stale
  verdict above says and not as close as this file's own prior update note
  claimed. The real gap left is upstream's actual schema-validator tools
  having no equivalent anywhere in this repo, and `rake spec`/`rake test`
  being permanently broken entry points nothing in CI catches.
