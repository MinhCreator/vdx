import QtQuick
import qs.config
import qs.kit
import qs.modules.windows

// Windows: how windows behave (hypr/components/windowmode.lua) — the mode
// (tiling, floating, scrolling), the options of the current one, the gaps,
// frames and shadows, and FLOATING: the switcher and the taskbar, which only
// the floating mode has. Applied at once: Hyprland reloads.
KitColumn {
  id: root

  readonly property var ws: WindowsService
  readonly property var o: WindowsService.opts
  readonly property var mode: ws.current
  readonly property bool floating: ws.mode === "floating"

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "app-window"
  readonly property string title: "Windows"
  readonly property string subtitle: mode.label.toUpperCase() + " · GAPS " + o.gapsIn + " / " + o.gapsOut
                                     + (floating ? " · TASKBAR " + (o.taskbar ? "ON" : "OFF") : "")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`; FLOATING
  // is only there in the floating mode
  readonly property var jumps: [
    { key: "mode",   label: "Mode",   y: modeGroup.y },
    { key: "layout", label: root.mode.label, y: layoutGroup.y },
    { key: "floating", label: "Floating", y: floating ? floatingGroup.y : -2 },
    { key: "gaps",   label: "Decoration", y: gapsGroup.y }
  ].filter(j => j.y > -2)

  function pct(v) { return Math.round(v * 100) + "%"; }

  spacing: Theme.gapGroup

  // ---- mode ----
  KitLabel { id: modeGroup; text: "MODE"; value: root.mode.label.toUpperCase() }

  KitRow {
    wide: true
    label: "Windows"
    hint: root.mode.about

    KitChoices {
      stretch: true
      model: root.ws.choices
      current: root.ws.mode
      onPicked: value => root.ws.setMode(value)
    }
  }

  KitRow {
    wide: true
    label: "Scroll with"
    hint: "Arrows: no mouse needed"

    KitChoices {
      stretch: true
      model: [{ label: "Wheel", value: "wheel" }, { label: "Arrows", value: "arrows" }, { label: "Both", value: "both" }]
      current: root.o.scrollKeys
      onPicked: value => root.ws.setOption("scrollKeys", value)
    }
  }

  KitLine {}

  // ---- the current mode's own options ----
  KitLabel { id: layoutGroup; text: root.mode.label.toUpperCase() }

  // 0.30–0.80 in steps of 0.05; setOption reloads Hyprland, so it runs on release
  KitSliderRow {
    id: master
    visible: root.ws.mode === "tiling"
    label: "Master size"
    snaps: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(i => i / 10)
    value: (root.o.mfact - 0.3) / 0.5
    text: root.pct(0.3 + (master.pressed ? master.dragValue : master.value) * 0.5)
    onReleased: value => root.ws.setOption("mfact", Math.round((0.3 + value * 0.5) * 20) / 20)
  }

  KitRow {
    wide: true
    visible: root.ws.mode === "tiling"
    label: "New window"
    hint: "Where it opens"

    KitChoices {
      stretch: true
      model: [{ label: "Master", value: "master" }, { label: "Stack", value: "slave" }]
      current: root.o.newStatus
      onPicked: value => root.ws.setOption("newStatus", value)
    }
  }

  KitRow {
    wide: true
    visible: root.ws.mode === "scrolling"
    label: "Column width"
    hint: "A new column's share"

    KitChoices {
      stretch: true
      model: [{ label: "1/3", value: 0.333 }, { label: "1/2", value: 0.5 }, { label: "2/3", value: 0.667 }, { label: "Full", value: 1 }]
      current: root.o.columnWidth
      onPicked: value => root.ws.setOption("columnWidth", value)
    }
  }

  KitRow {
    wide: true
    visible: root.ws.mode === "floating"
    label: "Arrange"
    hint: "On switching to floating"

    KitChoices {
      stretch: true
      model: [{ label: "Cascade", value: "cascade" }, { label: "Grid", value: "grid" }, { label: "Centre", value: "center" }]
      current: root.o.arrange
      onPicked: value => root.ws.setOption("arrange", value)
    }
  }

  KitLine {}

  // ---- floating only: the switcher and the taskbar ----
  KitLabel { id: floatingGroup; visible: root.floating; text: "FLOATING" }

  KitRow {
    visible: root.floating
    label: "Switcher"
    hint: "Super + Tab: this workspace's windows"

    KitSwitch {
      checked: root.o.switcher
      onToggled: root.o.switcher = !root.o.switcher
    }
  }

  KitRow {
    visible: root.floating
    label: "Taskbar"
    hint: "This workspace's windows, in a bar"

    KitSwitch {
      checked: root.o.taskbar
      onToggled: root.o.taskbar = !root.o.taskbar
    }
  }

  KitLine { visible: root.floating }

  // ---- gaps ----
  KitLabel { id: gapsGroup; text: "DECORATION"; value: root.o.gapsIn + " / " + root.o.gapsOut + " PX" }

  // inner 0–20 px in steps of 1, outer 0–40 px in steps of 2; released, as above
  KitSliderRow {
    id: innerGap
    label: "Inner gap"
    snaps: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].map(i => i / 20)
    value: root.o.gapsIn / 20
    text: Math.round((innerGap.pressed ? innerGap.dragValue : innerGap.value) * 20) + " px"
    onReleased: value => root.ws.setOption("gapsIn", Math.round(value * 20))
  }

  KitSliderRow {
    id: outerGap
    label: "Outer gap"
    snaps: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].map(i => i / 20)
    value: root.o.gapsOut / 40
    text: Math.round((outerGap.pressed ? outerGap.dragValue : outerGap.value) * 20) * 2 + " px"
    onReleased: value => root.ws.setOption("gapsOut", Math.round(value * 20) * 2)
  }

  KitRow {
    label: "Frames"
    hint: "A 2px frame round every window"

    KitSwitch {
      checked: root.o.borders
      onToggled: root.ws.setOption("borders", !root.o.borders)
    }
  }

  KitRow {
    label: "Shadows"
    hint: ""

    KitSwitch {
      checked: root.o.shadows
      onToggled: root.ws.setOption("shadows", !root.o.shadows)
    }
  }

}
