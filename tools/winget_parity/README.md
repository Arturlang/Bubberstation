# Skin parity harness (BYOND vs OpenDream)

The skin is interpreted client-side, so the only reliable way to see what an engine did
with `interface/skin.dmf` is to ask it. `winget()` is that oracle: it reports each
element's computed geometry *after* anchoring, splitting and layout.

This harness dumps that state from both engines and diffs it. Compared to screenshotting,
it says **which property on which element** is wrong instead of "the picture looks off",
and it is immune to font, DPI and anti-aliasing differences.

## Taking the dumps

1. Start the server and connect **DreamSeeker**.
2. Resize the game window to whatever size you want to test. Note it.
3. Run the admin verb **Debug → Dump Skin State** (needs `R_DEBUG`).
   It writes `data/winget_parity_byond.json` and reports the reference window size in chat.
4. Repeat under the **OpenDream client**, at the *same window size*.
   It writes `data/winget_parity_opendream.json`.

Window size matters: nearly every value is anchored to it, so dumps taken at different
sizes differ everywhere for reasons that have nothing to do with engine parity. The
differ refuses to compare mismatched sizes unless you pass `--allow-size-mismatch`.

## Diffing

```sh
python tools/winget_parity/compare_skin_dumps.py \
    data/winget_parity_byond.json \
    data/winget_parity_opendream.json
```

Exit status is `0` when the engines agree, `1` when they do not, and `2` when the dumps
are not comparable — so this can gate CI once a known-good baseline exists.

Example output for the CHILD splitter bug this was written to catch:

```
[info_button_child] show-splitter: byond='false' (False)  opendream='1' (True)
[info_button_child] splitter: byond='2' ([2.0])  opendream='10.000000' ([10.0])
[info_split] splitter: byond='97.5' ([97.5])  opendream='90' ([90.0])
```

## What gets compared

`code/modules/debugging/winget_parity.dm` enumerates every window and pane
(`winget(client, null, "windows")` / `"panes"`), then expands each one through the
`"<window>.*"` wildcard to reach its child controls. Every element is queried for the
common geometry params, plus params specific to its type (`CHILD` gets `splitter` /
`show-splitter` / `is-vert`, `MAP` gets `zoom` / `view-size`, and so on).

Values are recorded exactly as the engine returned them. All interpretation lives in the
differ, which normalises the things that are formatted differently but mean the same:

| kind | example |
|---|---|
| booleans | `"true"` vs `"1"` |
| vectors | `"640x480"` vs `"640x480.0"` |
| numbers | `"2"` vs `"2.000000"` |
| colours | `"#FFC41F"` vs `"#ffc41f"` |
| empty | `""` vs absent |

Anything left over is a real disagreement.

## Extending it

To cover more properties, add them to the lists at the top of
`code/modules/debugging/winget_parity.dm`. Params are queried per element *type*, so
adding one to the wrong bucket makes OpenDream log "not implemented" noise for elements
that never had it.

If a new param is a boolean, vector, number or colour, add it to the matching set at the
top of `compare_skin_dumps.py` too — otherwise it is compared as a plain string and
harmless formatting differences will show up as failures.

## Known limitation

Both dumps need a real connected client, so this is a two-command manual check rather
than a headless CI test. Automating it would mean driving DreamSeeker, which is why the
baseline-plus-exit-status design is there: capture a known-good BYOND dump once, commit
it, and diff future OpenDream builds against that instead.
