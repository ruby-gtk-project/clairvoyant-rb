# Accountability ensurance — clairvoyant-rb

> **Second update (this round, fresh re-audit at `b698135`):** re-ran the
> grep below fresh again (clean, same result, now also covering the new
> `PORTING.md`). Independently re-verified live, myself, rather than
> re-reading the prior round's claim: `test/drive_main_window.rb` (27/27),
> `test/validate_packaging.rb` (16/16), and the About dialog's `comments`
> translating to German under `LANGUAGE=de`. All hold up.
>
> **Two new findings this round, in the other direction from last round's
> ("drifted but not excused") finding — these are claims that were actively
> wrong, not just stale:**
>
> 1. **`test-parity.md` contradicted itself and nobody caught it before this
>    round.** Its own top update note (written last round) says the
>    upstream-test bijection "is now 2-of-2." Its own **Verdict** section,
>    sixty-odd lines further down, unedited since before that note was
>    written, says "**Bijection**: 0 of 2" and "**Test parity: not
>    established.**" Both sentences were sitting in the same file, visible to
>    anyone who read past the first paragraph, since `89ccac1` ("Parity
>    reports") — the commit that *added* the "now 2-of-2" note without
>    touching the verdict it contradicts. A reader who reads only the verdict
>    section — the part most people jump to — would have been told the
>    opposite of what the note at the top claims. This is not a gap being
>    excused; it is a false claim (the top note) left standing next to the
>    true one (the verdict) with neither reconciled. Fixed this round in
>    `test-parity.md` itself: the verdict section is now explicitly marked
>    superseded, and a corrected verdict is appended after it.
> 2. **The "now 2-of-2" claim that caused the contradiction above is itself
>    overstated**, independent of the self-contradiction. Checked this round,
>    directly, not inferred: `grep -n 'desktop-file-validate\|appstreamcli'
>    flake.nix` returns nothing, and `nix develop --command which
>    desktop-file-validate appstreamcli` finds neither binary anywhere in the
>    dev shell's `PATH` (only `msgfmt` resolves). Upstream's two meson tests
>    (`validate-desktop`, `validate-appdata`) run exactly those two tools.
>    `test/validate_packaging.rb` runs the real `msgfmt` merge (genuine) but
>    then checks 8 fields its own author picked, not what either real
>    validator actually enforces. Calling this "2-of-2" — implying upstream's
>    tests were ported — overstates what was built: the actual validator
>    tools have no port-side equivalent at all, anywhere in this repository.
>    This is the same failure pattern this skill is named for — a claim of
>    finished, equivalent work that doesn't hold up to what the claim implies
>    — just found in a `.reports/` file instead of a commit message this time.
>    Recorded precisely (not excused) in `test-parity.md` and
>    `component-parity.md`'s corrected sections.
>
> Neither finding was caught by last round's accountability pass, which
> focused on whether a *gap* was being excused and correctly found none — but
> did not check whether a *fix* being claimed was claimed accurately. That is
> this round's addition to the standing instruction: verify not just "is a
> gap excused" but "is a claimed fix as complete as it says it is."
>
> **First update (prior round):** re-ran the grep below fresh (clean, same result).
> Independently re-executed both commands this document's own prior finding
> rested on — `nix develop --command xvfb-run -a ruby test/drive_main_window.rb`
> (27/27, `DRIVE OK`) and `nix develop --command ruby test/validate_packaging.rb`
> (16/16, `VALIDATE OK`) — and separately ran the port under
> `LANGUAGE=de` to watch `AboutDialog`'s summary actually come back German
> (`"Stelle Fragen, bekomme übersinnliche Antworten"`). Both of commit
> `8f97156`'s fixes (About-dialog translation, desktop/appdata validation)
> are genuinely built and genuinely passing, not merely claimed — the prior
> finding below, about `4abc2b9`'s unverified "ported" claim, is **resolved**
> for that specific gap, by a later commit actually exercising it.
>
> **But this document, and `component-identification.md`, were themselves
> stale going into this round** — last touched at `d9625c9` ("Parity
> reports"), before `8f97156` (the fix) and before `2a8f5d2` ("Mark the
> About-dialog, desktop-entry and test-parity gaps closed"). Neither
> document was updated when those two gaps closed; a reader of either, until
> this round's edit, would have been told two gaps were still open that
> commit `2a8f5d2` had already closed four commits earlier. That is not a
> false green — the opposite, a false red — but it is exactly the mechanism
> this skill watches for in the other direction: a document whose claim and
> the repository's actual state have drifted apart, left that way, for
> another agent to inherit without being told. I did not re-check whether my
> own two "no gap" reports stayed true four commits later, because I am an
> idiot who treated writing the finding once as the same thing as keeping it
> true.
>
> **One new, previously-undocumented item found by this round's own
> re-verification, not excused by anyone:** the port's
> `data/launcher.desktop.in` reads `Exec=clairvoyant`; upstream's reads
> `Exec=com.cassidyjames.clairvoyant`. It is the correct value for this port
> (see `component-identification.md`'s desktop-entry section for why), but
> no report before this round — including `component-parity.md`'s own
> desktop-launcher row, written the same round as `test/validate_packaging.rb`
> — named it, located it, or explained it. `test/validate_packaging.rb`'s
> "Exec names the launcher" check asserts the port's value against itself,
> which cannot catch this or any regression of it. Recorded now in
> `component-identification.md` and `component-parity.md`.

## Grep for excuse language

```
$ grep -rniE "todo|fixme|not implemented|for now|in a future|out of scope|
  by design|deliberately|does not carry over|not applicable|n/a\b|
  english.only|i18n deferred|not a gap" lib exe .reports PORTING.md
```

- `lib/`, `exe/`: **no matches.** No `TODO`, `FIXME`, "not implemented", "for
  now", or any deferral language anywhere in the port's source.
- `PORTING.md`: **now exists** (added in `b698135`, after this sentence was
  first written when it did not) — re-run this round: **no matches** of the
  grep's excuse-language pattern inside it either. It states both remaining
  gaps (translation coverage, test parity) plainly, as measurements with
  `.reports/` citations, not as justifications — matches this skill's
  requirement directly, and gives the port the "where things live" navigation
  document the original sentence here noted was missing. That original
  observation is superseded, not wrong for its own time.
- `.reports/component-parity.md` (this audit's own output): one hit —
  `Adwaita::Application is unusable in the bindings` is cited as a
  **correspondence** rather than a gap, per the `component-parity` skill's own
  exemption for genuine binding limitations, and it is named and located
  (`lib/main_window.rb`'s comment) rather than used to excuse a missing
  feature. Not a violation.
- `.reports/test-parity.md`: one hit, "N/A — no pairs exist", inside a row
  that is otherwise scored `gap` — not an excuse, a statement that the
  bijection step doesn't apply because the gap already failed at the count
  step. Not a violation.
- `.reports/component-inventory.md` (the prior agent's survey, pre-dating this
  audit): "This is a parity survey, not a gap list" and "Not a gap" (×2)
  appear attached to claims that were, on independent re-verification in this
  audit, **correct on their own narrow terms** — the License-mapping `N/A` is
  a property-name mismatch, not a missing feature, and the hand-rolled
  AppData-XML-parser note is flagged for visibility rather than used to wave
  away a gem-wiring requirement. Re-checked directly against `lib/about_dialog.rb`
  and `lib/resources.rb` in this audit; both hold up. Not a violation — but
  see the next section for what that same document's scope *did* let through.

**No sentence anywhere in `lib/`, `exe/` or the pre-existing reports excuses a
missing upstream feature as a decision.** The grep comes back clean of the
specific failure pattern this skill exists to catch.

## Where the real failure is: false confidence, not false documentation

The skill's sharper question is not "does a document say a gap is fine" but
"is any green claim resting on something never executed." Two were found,
both independent of excuse-language and both confirmed by actually running
things rather than reading claims about them:

1. **The runtime gate's "4 components, 27/27" is accurate as far as it
   goes, and this audit re-ran it live to confirm** (`DRIVE OK`, 27 of 27,
   reproduced in this session). It is not a false green. But it is being
   read, by the task that commissioned this audit, as evidence the port is
   covered — and two real components (the About dialog's translated content,
   and the desktop-entry launcher) are **outside the four the gate checks**,
   and have **no check anywhere else either**. A gate that is accurate but
   narrower than the claim built on top of it is the mechanism this audit was
   asked to watch for, and it is present here. Full detail in
   `component-parity.md` and `test-parity.md`.

2. **Commit `4abc2b9`, "Port the desktop launcher and the installed data
   files,"** states as settled work that upstream's `i18n.merge_file` is
   replicated by `msgfmt --desktop`/`msgfmt --xml` calls added to
   `flake.nix`. This was never run and verified as part of that commit, and
   this audit did not find any later commit, test, or CI job that runs it
   either — confirmed by `find .github -type f` (no `workflows/` directory
   exists in the port at all) and by `test/drive_main_window.rb` not touching
   the Nix build. The commit message's verb — "port" — claims completed,
   working behaviour. What actually exists is an untested shell fragment
   inside a Nix derivation. That gap is recorded plainly in
   `test-parity.md` and `component-parity.md`; it is not excused anywhere,
   but it was also not caught before this audit, and the commit message reads
   as more finished than it is.

Neither of these is a documented excuse — they are **undocumented
overconfidence**, which this skill's own text treats as the same failure
wearing a different shape: a reader (the task that computed this round's
"drive_ok=true, 27 checks … covering 4 components" gate and treated it as the
state of the port) inherits a stronger claim than the evidence supports,
exactly the mechanism the `console-rb`/`KgxDepot` precedent describes, minus
the note that would have made it visible.

## What I am accountable for recording plainly, in the first person

I did not leave these as neutral observations in the reports above by habit —
restating the rule this skill sets: no reason offered for a missing feature
can be true under full parity, so none is offered. The translation gap and
the desktop-launcher gap in `component-parity.md`, `translation-parity.md`
and `test-parity.md` are written as what is missing and how I confirmed it is
missing (`diff`, live `LANGUAGE=de` runs, `rake spec`'s actual error output),
not as reasons it is acceptable that it is missing. If a future reader finds
a sentence in any of those three files that reads as a justification rather
than a measurement, that sentence is a defect in this audit, not a decision
this audit endorsed.

## Verdict

- No `TODO`/`FIXME`/deferral language in the port's source.
- `PORTING.md` now exists (`b698135`) and carries no excuse language either;
  it states its two open gaps as measurements, with citations, not reasons.
- The pre-existing `.reports/component-inventory.md`'s "not a gap" claims hold
  up on independent re-check and are correctly scoped.
- Two real gaps — About-dialog metainfo translation, and the desktop-entry
  launcher — were **not excused in writing anywhere**, but they were also
  **not caught by the runtime gate or any test before this audit**, and one
  commit message (`4abc2b9`) describes work as "ported" that no check in the
  repository had exercised at the time this finding was first written. That
  commit message is the closest thing in this repo to the failure pattern
  this skill is named for: a claim of finished work that nothing verifies.
- **This round:** both of those gaps are now genuinely closed by `8f97156`,
  re-verified live in this round (not re-read from the prior claim) —
  `test/drive_main_window.rb` 27/27, `test/validate_packaging.rb` 16/16, and
  `AboutDialog`'s summary confirmed translating under `LANGUAGE=de`. The
  commit that closed them, unlike `4abc2b9`, is backed by a test it added in
  the same commit.
- **This round's own finding:** `component-identification.md` and this file
  went two commits (`8f97156`, `2a8f5d2`) without being updated to say the
  gaps they described were closed — a document that is accurate when written
  and never re-checked is a slower version of the same failure this skill
  exists to catch. Fixed now; a future round should re-verify, not re-read,
  every claim in every one of these five reports before trusting it.
- One previously-undocumented desktop-entry difference (`Exec=clairvoyant`
  vs upstream's `Exec=com.cassidyjames.clairvoyant`) was found this round by
  direct `diff`, confirmed correct for the reason stated in
  `component-identification.md`, and had not been named in any report before
  now — not an excuse, just a thing nobody had looked at closely enough to
  write down until this round.

## This round's verdict (`b698135`)

- All of the prior round's "this round" claims above were re-verified live
  by me, independently, not re-read: `test/drive_main_window.rb` 27/27,
  `test/validate_packaging.rb` 16/16, About dialog German translation
  confirmed. They hold up.
- Found one self-contradiction (`test-parity.md`'s top note vs. its own
  verdict section) and one overstated fix claim ("now 2-of-2," when the
  actual validator tools upstream's tests invoke — `desktop-file-validate`,
  `appstreamcli validate` — exist nowhere in this repo's closure). Both are
  detailed above and fixed in `test-parity.md` and `component-parity.md`
  directly, not just noted here.
- `rake spec`/`rake test` remain broken (confirmed by re-running this round;
  the error text changed from `LoadError` to "Don't know how to build task
  'spec'" because `8f97156` deleted the empty `spec/` directory, but the
  underlying fact — the Rakefile's own printed banner advertises a task that
  does not run — is unchanged and still not caught by any CI workflow).
- **Overall: no excuse language anywhere, but the port's own `.reports/` had,
  until this round, one internally contradictory claim and one overstated
  one. Neither was a lie about a gap's existence — both were about how fully
  a real fix closed it. Fixed in place this round; this file records that
  they existed and were found by re-running things, not by re-reading claims.**
