# Test parity — clairvoyant-rb

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

**Test parity: not established.** Two upstream validation tests have no port
counterpart and nothing in the repo checks for either property. The port's
nominal test suite (`spec/`) is empty and its load path is broken in the
project's own dev shell. The only suite that passes (`test/drive_main_window.rb`)
is real and does pass, but runs only when a person remembers to type the
command by hand — it is not continuously verified, and its 27/27 says nothing
about the 2 upstream tests it does not cover.
