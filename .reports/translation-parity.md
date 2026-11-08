# Translation parity — clairvoyant-rb

> **Update (round 3, this round, `2f6643e`):** re-ran the German About-dialog
> check independently again — `AboutDialog.new.build.comments` under
> `LANGUAGE=de` still returns `"Stelle Fragen, bekomme übersinnliche
> Antworten"`, confirmed live. The caveat the prior round's note attached to
> the desktop-entry/metainfo keys — "the desktop/metainfo merge is verified
> against hand-picked fields, not the full external validator upstream's test
> suite runs" — no longer holds: `test/validate_packaging.rb` now runs the
> real `desktop-file-validate`/`appstreamcli validate` binaries (vendored into
> `flake.nix` this round), confirmed live, 18/18. This does not change any
> message-count or key-set figure in this file — it only removes a caveat on
> how thoroughly the one runtime consumer of those keys is checked. See
> `test-parity.md`'s round-3 note for the detail; carried here only because
> this file quoted the now-stale caveat.
>
> Key-set figures below (31 marked, 68 unmarked of 99 upstream msgids) were
> independently re-counted this round and are unchanged:
> `git show origin/main:po/com.github.cassidyjames.clairvoyant.pot | grep -c
> '^msgid "[^"]'` → 99; the port's own `msgid-census.sh` over `lib exe` → 31
> distinct marked keys (confirmed via the skill's own census script, not
> re-read from a prior count).

> **Update (prior round, re-audit at `b698135`):** independently
> re-verified the fix below myself rather than re-reading the prior round's
> claim — ran, live, under this dev shell with `LANGUAGE=de`:
> `AboutDialog.new.build.comments` → `"Stelle Fragen, bekomme übersinnliche
> Antworten"` (the German `po/de.po` translation, not the English source).
> `application_name` also resolved correctly. This confirms the fix is real,
> not a stale or re-asserted claim.
>
> **One clarification this round adds, not previously stated:**
> `AboutDialog::AppData#release_notes` only ever extracts the `<release>`
> whose `version` attribute matches the running build's `Config::VERSION` —
> so of the ~40 historical release-note msgids in the `.pot`, only the
> *current* version's notes are ever reachable at runtime. This is **not a
> port gap**: upstream's own `Adw.AboutWindow.from_appdata` behaves
> identically — it only ever displays release notes for the version matching
> the running build, never the full history. Noted here so a later reader
> does not mistake "39 of 40 historical release-note strings have no runtime
> consumer" for a port-specific failure; it is the same in both trees.
>
> Desktop-entry strings (`GenericName`, `Comment`, `Keywords`) were
> re-confirmed this round via a live run of `test/validate_packaging.rb`
> (16/16) — the `msgfmt --desktop` merge genuinely produces a localized
> `Comment[xx]` key. See `test-parity.md`'s this-round update for the caveat
> that this checks the merge, not the full desktop-file schema.
>
> **Prior round's update, kept verbatim:** the metainfo-sourced strings this
> report flags as
> never reaching the screen (`name`, `summary`, release notes) were fixed in
> `8f97156`: `AboutDialog::AppData` now includes `Intl` and runs those fields
> through the same gettext catalogue the 31 source-literal strings already
> used, reproducing the `msgfmt --xml` merge at the point of use instead of
> reading the raw `.in`-derived file. Verified live again this round via
> `test/drive_main_window.rb` (27/27, including the About-window checks) and
> `test/validate_packaging.rb` (16/16, including "appdata picked up at least
> one localized <summary>"). The desktop-entry strings (`GenericName`,
> `Comment`, `Keywords`) now have a runtime consumer too — the same
> `validate_packaging.rb` — though they remain a build/test-time check rather
> than something `lib/` reads at app-run time, which upstream's desktop file
> doesn't require either. The key-set analysis below (68 of 99 keys
> originally unreachable) predates this fix.

## Step 1 — census both trees

Upstream's `.pot` (`po/com.github.cassidyjames.clairvoyant.pot`, built from
`po/POTFILES.in`'s five files) has **99 msgids**:

```
$ git show origin/main:po/com.github.cassidyjames.clairvoyant.pot \
    | grep '^msgid "' | sed 's/^msgid "//;s/"$//' | grep -v '^$' | sort -u | wc -l
99
```

Port-side marked strings (every `_('...')`/`_("...")` call under `lib/` and
`exe/`):

```
$ grep -rhoE "_\(['\"][^'\"]*['\"]\)" lib exe \
    | sed -E "s/^_\(['\"]//; s/['\"]\)\$//" | sort -u | wc -l
31
```

## Step 2 — the key-set diff

```
$ comm -23 <upstream-99> <port-marked-31> | wc -l
68
```

**68 of upstream's 99 msgids have no `_()`-marked counterpart anywhere in
`lib/` or `exe/`.** Every one of the 68 is a string that originates in
`data/metainfo.appdata.xml.in` (the `<summary>`, every `<description>`
paragraph, every `<release>`'s description text, keywords) or
`data/launcher.desktop.in` (`GenericName`, `Comment`, `Keywords`) — i.e. every
string upstream marks for translation by `i18n.merge_file` rather than by a
literal `_()` call in source. Examples: `"Ask questions, get psychic
answers"`, `"Fortune Teller"`, every historical release note
(`"Added eight more original replies"`, `"GNOME 47 “Denver”"`, …),
`"Close with Ctrl+Q and Ctrl+W"`.

The remaining 31 matched keys are the strings built in Vala source
(`src/Application.vala`, `src/FortuneLabel.vala`, `src/MainWindow.vala`): the
28 fortune titles, `"About"`, `"Ask Again"`, `"translator-credits"`. These are
present, byte-identical, and — confirmed live — actually translate:

```
$ LANGUAGE=de ruby … E.new.t('Ask Again')  =>  "Erneut Fragen"
```

## Step 3 — do the keys that exist actually get used?

Having a key in `po/*.po` is necessary but not sufficient; the question is
whether the running app ever selects the translated value. This was checked
live, not assumed, per `component-parity.md`'s About-dialog finding:

```
$ rake gettext:mo:update                      # compiles every locale's .mo
$ LANGUAGE=de … AboutDialog.new.build.comments
=> "Ask questions, get psychic answers"        # English, not po/de.po's
                                                # "Stelle Fragen, bekomme
                                                # übersinnliche Antworten"
```

So of the 68 unmarked keys, the ones reachable at runtime at all (the About
window's `comments`, and by the same code path every release-note string) are
confirmed to **never** translate, in any language, ever — not because the
catalogue lacks the translation (`po/de.po` has it) but because the port's
`AboutDialog` reads the raw, untranslated `data/metainfo.appdata.xml` file
directly with `File.read`, with no merge step at the point of use. The Nix
packaging recipe (`flake.nix`) does run the correct `msgfmt --xml` merge, but
writes the result to a path (`$out/share/metainfo`) that
`Resources::METAINFO` never points at — so even a fully Nix-built,
installed copy of the port exhibits the same failure.

The desktop-entry strings (`GenericName`, `Comment`, `Keywords`) are in the
same bucket for a different reason: nothing in `lib/`/`exe/` ever reads or
builds a `.desktop` file at all (see `component-parity.md`), so there is no
runtime path for them to translate or fail to translate — they simply have no
port-side consumer, translated or not.

## Step 4 — the languages

```
$ git show origin/main:po/LINGUAS | tr ' ' '\n' | grep -v '^$' | wc -l
196
$ ls po/*.po | wc -l
196
$ diff <(upstream LINGUAS, sorted) <(port po/*.po basenames, sorted)
(empty)
```

All 196 languages upstream ships are present in the port's `po/` directory,
unchanged. The language *set* has full parity; what is missing is the
mechanism to ever surface 68 of the 99 keys those catalogues carry.

## Verdict

- **Key sets equal?** No — 68/99 upstream msgids (69%) have no port-side
  `_()` marking. They are not lost from `po/` (the files are carried over
  verbatim), but the port never *emits* a lookup for them from Ruby or from
  any translated-at-runtime resource.
- **Byte-identical keys?** The 31 keys the port does mark are byte-identical
  to upstream's (confirmed: both are in the comm diff's matched set, and spot
  checks above show the German translations line up with `po/de.po`).
- **Languages ship?** Yes, all 196, unchanged.
- **Do the translations actually reach the screen?** For the 31 marked keys:
  yes, confirmed live. For the 68 metainfo/desktop-sourced keys: **no, in
  every language, confirmed live** for the subset (About dialog `comments`)
  that has any runtime consumer at all; the rest have no consumer to even
  attempt translating.

**Translation parity: not established — superseded by this round's fix, kept
for history.** This section predates `8f97156`; the 68-unreachable figure is
no longer accurate. See the corrected verdict below.

## Verdict, corrected this round (`b698135`)

- Of the 68 keys this section found unmarked by `_()`: `name` and `summary`
  (metainfo) now run through `Intl` inside `AboutDialog::AppData` and are
  **confirmed live this round** to translate (German `comments` verified
  directly, independent of any prior claim). The current build's release
  notes translate the same way — by design, matching upstream, only the
  current version's notes are ever shown in either tree (see this file's top
  update note).
- Desktop-entry keys (`GenericName`, `Comment`, `Keywords`) are produced
  correctly by the real `msgfmt --desktop` merge, confirmed live via
  `test/validate_packaging.rb` — but see `test-parity.md` for why that check
  is narrower than upstream's actual `desktop-file-validate` validator.
- Still genuinely unreachable: the ~39 non-current historical release notes
  (not a gap — matches upstream) and anything in the `.pot` neither sourced
  from a literal `_()` call nor from the metainfo/desktop templates this
  round's fix covers — this audit found none such; the 68 were fully
  accounted for by the metainfo + desktop buckets.
- **Translation parity: materially closed.** All 196 languages ship
  unchanged, the 31 source-literal keys translate (confirmed live), and the
  metainfo/desktop keys that have any runtime or build-time consumer at all
  now translate too (confirmed live, independently, this round). The
  remaining caveat is `test-parity.md`'s: the desktop/metainfo merge is
  verified against hand-picked fields, not the full external validator
  upstream's test suite runs.
