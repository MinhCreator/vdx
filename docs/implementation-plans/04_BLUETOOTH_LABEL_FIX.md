# 04 — Bluetooth "Scan" → "Rescan"

Status: Implemented, partially verified · Category: A · Depends on: nothing · Gate: none. Spec: §5.6.
Shell paths are under `packages/quickshell/shell/`.

## Objective

The scan button reads "Rescan" everywhere it appears; scanning is unchanged.

## Read first

`modules/bluetooth/BluetoothOverview.qml`, `apps/shellmanager/BluetoothPage.qml`,
`modules/bluetooth/BluetoothService.qml` (`scan`, `scanning` — read only).

## Findings (2026-10-19)

Buttons: `BluetoothOverview.qml:188`, `BluetoothPage.qml:194`. Hints that name
the button: `BluetoothOverview.qml:59` ("No devices yet. Scan finds the ones
nearby."), `BluetoothPage.qml:204` ("Scan finds devices nearby."). No
localisation layer, no tests on the label. Re-grep before editing (`grep -rn Scan`).

## Requirements

- Both buttons: "Rescan". A busy state label, if any, unchanged.
- Hints that name the button follow it ("Rescan finds …").
- Note in the report: "Rescan" before any scan ran is slightly odd; the owner
  asked for it — no conditional label unless the owner wants one.

## Acceptance

Popup and Shell Manager › Bluetooth show "Rescan"; clicking scans as before; button width fits (no elide).

## Validation

`./install.py check`; `qs -c shell ipc call bluetooth toggle`; `qs log -c shell`.

## Regressions

Footer layout of the popup; Shell Manager action-button width rule (`d855ef6`: settings rows share one width).

## Forbidden

Changing scan logic, IDs, or other labels.

## Report

Files and lines changed; validation.
