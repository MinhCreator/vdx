# 07 — File manager: storage home page, custom sidebar, fewer frames

Status: Not started · Depends on: 02-A (listing fixes land first, same files) ·
Spec: §8. Shell paths are under `packages/quickshell/shell/`.
Three parts, run in order A → B → C or independently (they touch different files mostly; A and B both touch `FilesSidebar.qml` — not in parallel).

## Read first (all parts)

`apps/files/*.qml` (start with `FilesService.qml`, `FilesWindow.qml`,
`FilesSidebar.qml`, `FilesPlace.qml`, `FilesSettings.qml`), `scripts/files.py`
(`places`, `devices`, `stat`), `tests/test_files.py`, `docs/SHELL_DESIGN_SYSTEM.md`.

---

## Part A — Home page with storage overview

Category: B · Gate: proposal (what is shown, data source) approved.

- Proposal: a "This computer" view (sidebar entry + start-folder option?) listing
  filesystems the user can open: mounted local filesystems (from
  `/proc/self/mountinfo` or `findmnt -J`, or udisks2 which `files.py devices`
  already uses), removable media, network mounts (if mounted: nfs, cifs,
  sshfs, gvfs fuse) — each with used/free bar (`statvfs`), and unmounted
  removable partitions (mount on click, existing `mountDevice`).
- Distinguish disk / partition / filesystem / mount point; don't list
  pseudo filesystems (tmpfs, overlay, efivarfs …) or bind mounts twice
  (same device + root → one row; btrfs subvolumes of one fs → one row with its mounts listed).
- States: unavailable, permission denied, unmounting, refresh (on open + udisks change, not a fast poll).
- Data in `files.py` (new command, e.g. `volumes`) with a test on a fake mountinfo.
- References (record): Windows File Explorer "This PC", GNOME Files "Other Locations", KDE Dolphin "Devices"; `findmnt(8)`, `statvfs(3)`, udisks2 D-Bus docs.

Acceptance: every mounted real fs once; free/used match `df -h`; USB stick
appears/disappears; unmounted partition mounts on click; no pseudo fs.

## Part B — Customisable sidebar

Category: B · Gate: proposal approved.

- Audit current sections (places from backend, bookmarks, devices) and actions (bookmark/unbookmark).
- Proposal: one ordered list of pinned entries (places + bookmarks), show/hide per default place, drag to reorder, add current folder, remove, "Restore defaults"; devices section stays automatic.
- Persistence: `ModuleSettings` "files" keys (migrate existing `bookmarks`).
- Empty state when nothing pinned.

Acceptance: order survives restart; hide/show default places; restore defaults; old bookmarks migrated.

## Part C — Remove redundant frames

Category: A (visual, needs owner look) · Gate: one screen prototype approved (`shell/CLAUDE.md`: new look on one surface first).

- Inventory frames in `apps/files/` (KitFrame, borders, `frames` setting from 2026-10-18).
- Keep frames that separate panes the user resizes; replace decorative ones with spacing / `KitLine` per the popup rule "no backgrounds under groups".
- Decide with the owner whether the `frames` setting stays.

Acceptance: owner approves the screenshot; no layout jumps; dark/light themes; sharp/round.

---

## Validation (all)

`./install.py check`; `python -m unittest tests.test_files`; `qs log -c shell`;
`qs -c shell ipc call files open`; picker mode (`Choose…`) unaffected.

## Regressions

Picker (compact mode has no sidebar); devices mount/unmount; bookmarks;
Miller columns; drag strips; properties panel device free space.

## Agents

None by default. Part A's `files.py volumes` + test is a bounded candidate if the owner asks.

## Forbidden

Changing navigation/keys; other Files features; picker layout.

## Report

Per part, README formats.
