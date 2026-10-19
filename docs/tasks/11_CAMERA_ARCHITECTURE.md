# 11 — Capture ("camera") app and module architecture

Status: Not started · Category: C (proposal only) · Depends on: D-11 answered (a restructure after the
proposal waits for 01-E, which edits `CaptureService.qml`) · Gate: proposal approved before any restructuring. Spec: §11.
Shell paths are under `packages/quickshell/shell/`.

## Objective

A clear, predictable split of what the Capture app, its window and its bar
module do — or a justified decision to keep it.

## Interpretation (D-11, ask the owner first)

The repo has no webcam code; the camera-icon feature is **Capture** (screenshots
and screen recording). This plan assumes the spec means Capture. If the owner
means a webcam app, this file is rewritten as a new-app research task (V4L2 /
PipeWire camera portal) before anything else.

## Read first

`apps/capture/*.qml` (9 files, ~1.7k lines), `modules/capture/*.qml`,
`apps/apps.json` (capture: ipc `captures`, module `capture`), the Hyprland
bind (`packages/hypr/components/keybinds.lua`, Super+Shift+S → `capture open`),
`shell/README.md` › Apps (Capture, Capture (window)), `components.toml` (quickshell packages: grim, gpu-screen-recorder).

## Current (from listing; draw the real diagram in phase 1)

```
Super+Shift+S ─ ipc capture open ─ CaptureService ─ CaptureOverlay (region/window/screen, shot | record)
                                        │                 └ CaptureControls, CaptureSave
                                        ├ CaptureRecording (gpu-screen-recorder)
bar module capture (camera / red dot) ──┤   CapturePopup, CaptureFallback
ipc captures ─ CaptureWindow ─ CaptureLibrary (shots and recordings)
```

## Phase 1 — proposal

- Audit responsibilities, entry points (bind, bar, IPC ×2, launcher), hardware
  access (screencopy, encoder), dependencies, interactions (notifications,
  clipboard, PopupManager freezing, Files).
- Problems found (e.g. two IPC targets, overlay vs library naming, what the bar module shows).
- Options, at least: (1) keep one app + one module, fix responsibilities;
  (2) split into separate apps (capture tool / library) and modules
  (capture / recording indicator) — only if it gives a clear user and code benefit; (3) any better alternative with evidence.
  For each: UX, complexity, reuse, integration, regressions, maintenance, fit.
- Reference: Windows Snipping Tool + Game Bar recording indicator (behaviour
  only), macOS Screenshot (Cmd+Shift+5), GNOME screenshot UI; record sources.
- Recommendation, migration plan (IPC names, binds, settings keys), acceptance criteria.

## Agents

None.

## Forbidden

Any restructuring before approval; changing capture behaviour in this phase.

## Report

Research format; current-architecture diagram; decision record draft.
