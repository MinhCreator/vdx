# 0005 — Capture: freeze first, a toolbar on the overlay

Status: Accepted (2026-10-20, owner, chat: "Подход одобряю. Правки удаляем. Задержку сделай опциональной в настройках.")
Phase: tasks/11_CAMERA_ARCHITECTURE.md (done, deleted)

## Context

Super+Shift+S opened the Capture module's popup (mode, kind, sound, cursor,
Start); Start froze the screens. The popup obeys the one-open rule
(`PopupManager.open`), and in the island style it takes the island's place
(`Island.showPopup`), so the popup one wanted to shoot was closed before the
still was taken. Workarounds piled up: the hub started at once
(`PopupManager.hubScreen`), an "Own window" popup outside the rule, a
fallback popup from the bar's centre with no module (`CaptureFallback`), a
three-way "Shortcut opens" option. Options lived in four places (Apps ›
Capture, Bar modules › Capture, the popup, old values in `capture.json`).

## Options

1. Keep the popup, fix the island: let Capture's popup open beside others.
   Two windows to place, one-open exceptions in BarPopup, PopupCatcher, the island.
2. Freeze first (GNOME screenshot UI, macOS Cmd+Shift+5, Windows Win+Shift+S):
   the shortcut freezes at once, the choices are a toolbar on the overlay.
3. No UI: the last mode at once, choices only in Settings. Cheapest, but
   switching region / window / recording becomes a trip to Settings.

## Decision: option 2

- `capture open` freezes every screen as it is (popups, island, hub, menus:
  `PopupManager.holding` / `frozen` already kept them) and shows
  `CaptureToolbar` on the focused one: what (R W S), as (Tab), the sound, the
  pointer (C), Delay, Library, Cancel. Again: cancel; while recording: stop.
- Window picks the shell's own surfaces too: each bar answers
  `CaptureService.targetsAsked` with its island, child islands, open popup or
  strip (`Bar.captureTargets`).
- The bar module is a button for the same, and shows a recording (red dot,
  time; a click stops). No popup. `CaptureRecording`'s panel shows only where no
  module is seen, in a corner the recorded area leaves free.
- Delay: an option (Apps › Capture › TOOLBAR › Delay button, Off by default).
  On: a toolbar button lets the screens go, counts down (`CaptureCountdown`,
  bottom centre; a click or the shortcut cancels) and freezes them again.
- One IPC target `capture`: `open | stop | close | library | shot <region|window|screen>`;
  `captures` is gone (apps.json opens `capture library`). Super+P is `capture
  shot screen` (follows Capture's saving options) instead of `grim | wl-copy`.
- Options: all in Apps › Capture; Bar modules › Capture keeps the face only.
  `shortcut`, `detached`, `detachedSide`, `popupFps`, `popupSound` dropped
  (settings migration 5); fps / quality / encoder / codec no longer fall back
  to `capture.json`, which keeps only the toolbar's last picks.

## Consequences

- Removed: `CapturePopup`, `CaptureFallback`, `CaptureControls`, BarPopup's
  `detached`, `PopupManager.hubScreen`.
- A recording still records a fixed rectangle (a moved window leaves it).
- Save as is still a path field; the Files picker can replace it once the
  portal FileChooser is in.

## Verification

Live: the overlay with the toolbar (screenshot); the Wi-Fi popup open in the
island stays in the still and after cancel; Window's targets from the bar
(island 370 × 600 with the popup open); no errors in the log; migration test.
Not done here: a recording, the countdown, keys by hand, a second monitor, the
strip (non-island) style.
