# Accountability ensurance — clairvoyant-rb

> **Update (this round):** re-ran the grep below fresh (clean, same result).
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
- `PORTING.md`: **does not exist** in this repository at all — there is no
  document of this name to audit, which also means no agent has been able to
  cite it as authority for a skip (the specific failure mode this skill is
  named for), but it also means the port's own "where things live" navigation
  document is missing.
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
- No `PORTING.md` exists to be cited as false authority.
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
