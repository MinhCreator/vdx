import QtQuick
import qs.config
import qs.kit
import qs.plugins.windows

// Windows: how windows behave (hypr/components/windowmode.lua) — the mode
// (tiling, floating, scrolling), the options of the current one, the gaps,
// frames and shadows and the
// floating mode's taskbar. Applied at once: Hyprland reloads.
Column {
  id: root

  readonly property var ws: WindowsService
  readonly property var o: WindowsService.opts
  readonly property var mode: ws.modes.find(m => m.value === ws.mode) ?? ws.modes[0]

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "columns"
  readonly property string title: "Windows"
  readonly property string subtitle: mode.label.toUpperCase() + " · GAPS " + o.gapsIn + " / " + o.gapsOut
                                     + " · TASKBAR " + (o.dock ? "ON" : "OFF")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "mode",   label: "Mode",   y: modeGroup.y },
    { key: "layout", label: root.mode.label, y: layoutGroup.y },
    { key: "gaps",   label: "Look",   y: gapsGroup.y },
    { key: "dock",   label: "Taskbar", y: dockGroup.y }
  ]

  function pct(v) { return Math.round(v * 100) + "%"; }

  spacing: 14

  // ---- mode ----------------------------------------------------------------------------
  KitLabel { id: modeGroup; text: "MODE"; value: root.mode.label.toUpperCase() }

  KitRow {
    wide: true
    label: "Windows"
    hint: root.mode.about

    KitChoices {
      stretch: true
      model: root.ws.modes.map(m => ({ label: m.label, value: m.value }))   // icons don't fit three
      current: root.ws.mode
      onPicked: value => root.ws.setMode(value)
    }
  }

  KitRow {
    wide: true
    label: "Scroll binds"
    hint: "Arrows stand in without a mouse"

    KitChoices {
      stretch: true
      model: [{ label: "Wheel", value: "wheel" }, { label: "Arrows", value: "arrows" }, { label: "Both", value: "both" }]
      current: root.o.scrollKeys
      onPicked: value => root.ws.setOption("scrollKeys", value)
    }
  }

  KitLine {}

  // ---- the current mode's own options -------------------------------------------------
  KitLabel { id: layoutGroup; text: root.mode.label.toUpperCase() }

  KitRow {
    visible: root.ws.mode === "tiling"
    wide: true
    label: "Master size"
    hint: "The main window's share"

    KitChoices {
      stretch: true
      model: [0.4, 0.5, 0.6, 0.7].map(v => ({ label: root.pct(v), value: v }))
      current: root.o.mfact
      onPicked: value => root.ws.setOption("mfact", value)
    }
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
    hint: "Windows as the mode starts"

    KitChoices {
      stretch: true
      model: [{ label: "Cascade", value: "cascade" }, { label: "Grid", value: "grid" }, { label: "Center", value: "center" }]
      current: root.o.arrange
      onPicked: value => root.ws.setOption("arrange", value)
    }
  }

  KitLine {}

  // ---- gaps ----------------------------------------------------------------------------
  KitLabel { id: gapsGroup; text: "LOOK"; value: root.o.gapsIn + " / " + root.o.gapsOut + " PX" }

  KitRow {
    wide: true
    label: "Between windows"
    hint: "Pixels"

    KitChoices {
      stretch: true
      model: [0, 5, 10, 15].map(v => ({ label: String(v), value: v }))
      current: root.o.gapsIn
      onPicked: value => root.ws.setOption("gapsIn", value)
    }
  }

  KitRow {
    wide: true
    label: "Screen edges"
    hint: "Pixels"

    KitChoices {
      stretch: true
      model: [0, 10, 20, 30].map(v => ({ label: String(v), value: v }))
      current: root.o.gapsOut
      onPicked: value => root.ws.setOption("gapsOut", value)
    }
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
    hint: "Under every window"

    KitSwitch {
      checked: root.o.shadows
      onToggled: root.ws.setOption("shadows", !root.o.shadows)
    }
  }

  KitLine {}

  // ---- dock ----------------------------------------------------------------------------
  KitLabel { id: dockGroup; text: "TASKBAR" }

  KitRow {
    label: "Taskbar"
    hint: "Floating: this workspace's windows"

    KitSwitch {
      checked: root.o.dock
      onToggled: root.o.dock = !root.o.dock
    }
  }
}
