# 02 — Filepicker refresh and duplicate microphone

Two independent parts; run either alone. Spec: §5.2, §5.3.
Shell paths are under `packages/quickshell/shell/`.

---

## Part A — Filepicker shows stale files

Status: Implemented, partially verified (2026-10-19; Files window and portal picker checked, `Choose…` not checked) · Category: A · Depends on: nothing · Gate: none (report the refresh strategy in the report).

### Objective

The picker (and the Files window) always shows the folder's current contents.

### Scope

In: `apps/files/FilesService.qml` (show, open, listing cache, poll, `run`
queue, picker `begin`/`finishPick`), `apps/files/FilesWindow.qml` (`active`),
`scripts/files.py list`, `scripts/files_portal.py` only if the portal path differs.
Out: new watcher daemons (inotify) unless evidence demands it; Files features; UI.

### Read first

`FilesService.qml` in full (≈ 700 lines), `FilesWindow.qml`, `scripts/files.py`
(`list`), `scripts/files_portal.py`, `tests/test_files.py`, audit §5.2.

### Findings so far (hypothesis)

`show()` shows `listing[path]` then `refresh()`; poll 1 s while `active` and
not `searching`; `open()` does nothing when `path` is set; `run()` keeps one
`next` request while busy; replies for a folder left behind are dropped.
Last change 2026-10-18 (`d14e745`) may already fix it — reproduce first.

Reproduced 2026-10-19 on the running shell: not reproduced. A file created after
the Files window opened (Files window, and portal picker via `ipc call files choose`)
appears within 1.5 s; a file created before a reopen shows. The poll from `d14e745`
covers the visible case. The gap left: `open()` did nothing when the folder was
already shown, so a reopened window showed its cached rows until the first 1 s tick.
Fix: `open()` reads the shown folder at once (`FilesService.qml`). Refresh strategy:
unchanged poll (1 s while visible), `open()` + `show()` read at once, one listing in
flight per folder (`run()` keeps the latest request).
Not checked: `Choose…` from Shell Manager; a stalled read (a hung mount) would block
the queue — no evidence of it here.

### Requirements

- Opening the picker/window shows the current listing (cached rows MAY show first, replaced by the fresh read).
- Entering a folder reads it; returning to one follows the same rule.
- Create / delete / rename (by the shell or another program) appear within the poll interval while visible.
- No duplicate rows; no request storm (≤ one listing in flight per folder).
- Filters (picker patterns), hidden files, sort order unchanged.

### Steps

1. Reproduce on `main`: open picker (e.g. a GTK app's Open via portal, and a
   Shell Manager `Choose…`), in a terminal `touch`/`rm`/`mv` in that folder, observe; close and reopen.
2. Find the path that misses the refresh (log `listProc` runs with `console.warn`, removed after).
3. Fix at that point (e.g. `open()`/`begin()` refreshes the shown folder; poll runs while the picker is up).
4. If logic is moved into `files.py`, add a test in `tests/test_files.py`.

### Acceptance

Each requirement observed for both entry points (portal picker, `Choose…`) and the Files window.

### Validation

`./install.py check`, `qs log -c shell`, manual steps above; `python -m unittest tests.test_files`.

### Regressions

Picker filters and Save mode (name field); multiple selection; hidden toggle;
sort; search (Ctrl+F / Ctrl+K); Miller columns; trash view; undo; the picker size setting; `lastPath`.

### Forbidden

Visual changes; new dependencies; a permanent watcher without evidence.

---

## Part B — Duplicate microphone entries

Status: Implemented, partially verified (2026-10-19, model A for inputs and outputs; the switch to a headset not tested live) · Category: A (B if the device model changes) · Depends on: nothing ·
Gate: approval of the device model (step 3) before changing what the list shows.

### Objective

The input list shows what the user can really choose, once each; selection is not what makes an entry vanish.

### Scope

In: `modules/audio/AudioService.qml` (`entriesOf`, `jackIn`, `select`),
`modules/audio/AudioDeviceDropdown.qml`, `scripts/audio.sh`.
Out: WirePlumber config changes unless the cause is there (then a proposal);
the `/etc` quirk `system/etc/tmpfiles.d/headset-mic.conf` (sudo, owner).

### Read first

`AudioService.qml`, `AudioDeviceDropdown.qml`, `AudioPopup.qml`, `scripts/audio.sh`,
`system/etc/tmpfiles.d/headset-mic.conf`, `packages/wireplumber/wireplumber.conf.d/`, audit §5.3.

### Findings so far

One source node, ports `analog-input-internal-mic` and `analog-input-mic`
(jack, quirk, no presence detect, both "availability unknown"). `entriesOf`
lists a port when it is active → the jack mic shows while active, vanishes
after Internal is chosen.

Cause (2026-10-19, from code and `pactl list sources`; no headset plugged, so the
plug path is not seen): `entriesOf` always lists `…internal-mic` (`p.name.includes("internal")`),
and lists `…analog-input-mic` only when it is the active port, or when it is
available and not "unknown" (jack mic with `jackIn`). Selecting Internal
(`select()` → `pactl set-source-port`) makes the mic entry vanish: the list's shape
depends on the selection. The mic port is kept by WirePlumber: its
`~/.local/state/wireplumber/default-routes` has an `analog-input-mic` entry, so
the port stays after a restart. No auto-switch expected: the tmpfiles quirk
(`headset-mic.conf`) keeps the port without presence detect.

Proposal for the gate (Model A, recommended): the list depends on `jackIn` only,
never on the selection. Internal Microphone is always listed. Headset Microphone
is listed while `jackIn` (a headset in the jack is seen on the output side, which
has presence detect) and labelled by its port. If the mic is the active source
while `jackIn` is false, no second entry: the dropdown shows a hint ("Microphone ·
not detected") on the current choice. Remove the "or when it is the one in use"
clause of `entriesOf`. Model B (not recommended): the mic always listed, dimmed
with "not detected" when `jackIn` is false.
Question for the owner: A or B.

Correction (2026-10-19, the owner: the bug was on the output side, Speakers): the
same mechanism is in `outputs` (`entriesOf(sinks)`). The built-in sink has
`analog-output-speaker` (Speaker, "availability unknown", listed always) and
`analog-output-headphones` (Headphones, "not available" without a plug; listed only
while active or available). With headphones in, the codec reports the speaker
"not available", so `entriesOf` lists it only while it is the active port. Choosing
Headphones makes the Speakers entry vanish: the list depends on the selection
again. Not seen live: no headset is plugged and the output routing is the user's
audio, so no `pactl set-sink-port` test was run.
Model A extends to outputs: the list depends on availability only. A port that is
"not available" is not listed; the active one that is not available gets a hint on
the current choice. Speakers are listed while the codec does not say "not available";
Headphones while available. The output side is a behaviour change, so the plan's
"Forbidden: output-side behaviour changes" needs the owner's approval first.
Question for the owner: approve model A for inputs and outputs (or B for each)?

### Requirements

- Product model, proposed: an entry = a selectable input (port of a card, or a
  device without ports). A port whose presence cannot be known is listed only
  when the user can plausibly use it (headphones in, per `jackIn`) — and when
  it is active without that, it is listed **with a state hint** (e.g. "not detected")
  rather than as an equal peer. Owner approves this or another model.
- Identity by node name + port name; never by index or label text.
- Plug / unplug updates the list (ports refresh on Pipewire changes).

### Steps

1. Reproduce: log in fresh, open Audio popup; `pactl list sources` (active port). Find who sets `analog-input-mic` (WirePlumber state `~/.local/state/wireplumber/`, a plug event).
2. Write the cause + model proposal → gate.
3. Implement in `entriesOf` (and the dropdown label for the hint).

### Acceptance

No headset: one input "Internal Microphone". Headset plugged: both, labelled.
After any selection the list does not change shape. Selection still sets port + default source.

### Validation

`pactl list sources`; `pactl set-source-port …` from a terminal and watch the popup; `qs log -c shell`.

### Regressions

Outputs list (speakers/headphones/HDMI hiding), mute switch, AirPods / Bluetooth
sources, `AudioPause`, volume OSD.

### Forbidden

Deduplication by label or index; `/etc` changes; output-side behaviour changes.

---

## Report

Per README › Report format, one per part.
