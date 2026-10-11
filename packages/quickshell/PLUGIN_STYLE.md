# Plugin Philosophy for quickshell

This document describes the conceptual foundation and design philosophy for
quickshell plugins. It is not a style guide — those live in the component
docs — but rather the "why" behind the approach.

## 1. Core Principles

### 1.1 Separation of Concerns
Every plugin consists of exactly three logical layers, each with a single
responsibility:

- **Service** (`<Name>Service.qml`) — the only layer that talks to the
  outside world. It owns all `Process`/`Timer` objects, calls shell scripts,
  parses JSON output, and maintains the runtime state. Nothing in the bar or
  popup ever creates a process or timer.

- **Popup** (`<Name>Popup.qml`) — pure presentation. It knows nothing about
  processes, scripts, or system state. It only reads properties from the
  Service and renders them. If it needs data, it asks the Service.

- **Bar module** (`<Name>.qml`) — the bar's visible widget. It provides the
  label, the click area, and a `BarPopup` wrapper. It delegates everything
  else to the Service and Popup.

This three-layer contract is the single most important rule. Breaking it —
even slightly — creates "bit rot" where state becomes inconsistent and bugs
are nearly impossible to trace.

### 1.2 Single Source of Truth
The Service is the single source of truth for its domain. The bar label and
popup display are *derived* from the Service state, not independent sources.
When the Service state changes, the display updates automatically. There is
no separate "state in the bar" and "state in the popup" — there is only one.

### 1.3 Minimalism by Default
Decorations are not free. Every pixel, color, animation, and shadow has a
cost in cognitive load. The default is nothing — no radius, no shadow, no
gradient, no tooltip. Anything added must earn its keep by solving a real
problem, not by default.

### 1.4 Reusability Over Customization
The system provides a set of shared components (`BarPopup`, `PopupManager`,
`PopupButton`, `PopupSwitch`, `PopupInput`, `PopupSeparator`, `PopupSpinner`)
that every plugin should use. Writing a new component from scratch is
discouraged — instead, extend or configure the existing one.

If a plugin needs a behavior that no existing component supports, the correct
approach is to file an enhancement for the shared component, not to build a
new one. The goal is that all plugins look and feel like they belong to the
same system, even if they manage completely different domains.

### 1.5 State Stability
Popups are transient — they appear, users interact, they close. The system
guarantees that at most one popup is open at a time (via `PopupManager`).
Modules should not track popup state themselves — `BarPopup` and `PopupManager`
handle registration, focus grabbing, `closedAt` timing, and dismissal.

## 2. The Plugin Lifecycle

### 2.1 Creation
1. Write the shell script (`scripts/<name>.sh`) that emits JSON to stdout.
2. Write the Service (`<Name>Service.qml`) that spawns the script, parses
   its output, and maintains state.
3. Write the Popup (`<Name>Popup.qml`) that reads Service properties and
   renders them using shared components.
3. Write the bar module (`<Name>.qml`) that provides the label and wraps the
   Popup in `BarPopup`.
4. Register the module in `Bar.qml`.

### 2.2 Operation
- The bar shows a concise label reflecting the Service state.
- Clicking the label toggles the popup.
- The popup displays derived state (traffic, status, lists, inputs) using
  shared layout patterns.
- Only one popup may be open across the entire bar at any time.
- The Service continues running even when the popup is closed.

### 2.3 Cleanup
When a module is removed from `Bar.qml`, its Service and Popup are discarded.
No manual cleanup is needed — Quickshell handles singleton lifecycle.

## 3. Design Philosophy

### 3.1 "Just Text, Usually"
The bar's primary mode is text. Icons, colors, and status indicators exist
to enhance that text, not replace it. A plugin should first ask: "What is the
minimum text needed to convey status?" and build from there.

### 3.2 State as Derived, Not Stored
Avoid storing state in QML properties that could also be computed from the
Service. If the Service has the "truth," let the QML read it. This prevents
the two sources of truth from drifting apart.

### 3.3 Bounded Interaction
User interaction with a plugin is bounded: click to open popup, interact,
close. There are no persistent drag-and-drop, no long-running gestures, no
modal dialogs that block the bar indefinitely. This keeps the system fast
and predictable.

### 3.4 Integration, Isolation
Each plugin is designed to be plugged in or out without affecting others.
The bar's layout, the PopupManager, and the shared chrome are the glue. But
each plugin's internals — its script, its Service its Popup — are isolated.
A bug in Mihomo should not affect Wi-Fi, and vice versa.

### 3.5 Incremental Adoption
Plugins can be added one at a time. The `Bar.qml` file is the entry point —
add a `Row { ... }` entry and the module appears. No core redesign is needed.
This is by design — the system should grow organically.

## 4. The Shared Component Ecosystem

The shared components (`BarPopup`, `PopupManager`, `PopupButton`, etc.) are
not just convenience — they are the structural backbone. They enforce:

- **Consistent anchoring** — every popup appears in the same way relative to
  its module.
- **Consistent focus** — `grabFocus: true` inside popups, `HyprlandFocusGrab`
  for outside-click dismissal.
- **Consistent state** — `PopupManager.current` tracks what's open; `closedAt`
  prevents race conditions.
- **Consistent dismissal** — closing one popup closes the previous one.

Writing a new plugin without using these shared components is possible but
discouraged — the cost is not just development time, but long-term
inconsistency across the system.

## 5. The Big Picture

quickshell plugins are not standalone widgets. They are three pieces of a
larger whole:

1. **A shell script** that knows how to talk to the system.
2. **A QML Service** that manages that script and its state.
3. **Two QML layers** (bar module + popup) that present that state using
   shared visual primitives.

The philosophy is that *constraints breed creativity*. By forcing a small
set of patterns (three layers, shared chrome, single source of truth),
the system becomes greater than the sum of its parts. New plugins can be
added in hours, not days, because the structural decisions have already been
made.

And the goal is always: *does this plugin feel like it belongs here?*

If a new plugin looks, feels, and behaves like the others — even if it
manages a completely different domain — the philosophy has succeeded.