import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: MONITOR (which bar, one bar everywhere, show it) and LAYOUT: a small
// preview of the bar, then a row per band — LEFT, CENTER, RIGHT, FOLDER and
// HIDDEN — its chips in bar order (KitChipBands). Drag a chip along a band or
// to another one; this page decides what each drop means. Under it the icon size.
// Island style (STYLE): the bands are the island's — LEFT and RIGHT beside the
// clock in the resting pill, HUB for the chips when it opens, HIDDEN.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "layout"
  readonly property string title: "Bar"
  readonly property string subtitle: Quickshell.screens.filter(s => BarLayout.barOn(s.name)).length + " OF "
    + Quickshell.screens.length + " MONITORS"

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "bars",    label: "Bars",    y: barsGroup.y },
    { key: "monitor", label: "Monitor", y: root.barId === "main" ? mainBar.y + monitorGroup.y : -2 },
    { key: "style",   label: "Style",   y: root.barId === "main" ? mainBar.y + styleGroup.y : -2 },
    { key: "layout",  label: "Layout",  y: root.barId === "main" && root.barOn ? mainBar.y + layoutGroup.y : -2 }
  ].filter(j => j.y > -2)

  // the bar set up below: "main" or a child bar's id
  property string barId: "main"

  readonly property string focusId: chips.dragId !== "" ? chips.dragId : chips.hoverId

  // a monitor in the role being set up (main first)
  property string screenName: BarLayout.mainScreen()
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property string other: roles.find(n => n !== screenName) ?? ""
  readonly property var layout: BarLayout.layout(screenName)
  readonly property bool barOn: BarLayout.barOn(screenName)
  readonly property bool island: Theme.island
  readonly property var columnZones: island ? ["start", "end", "hub", "hidden"] : ["left", "center", "right", "folder", "hidden"]

  function module(id) { return BarLayout.modules.find(p => p.id === id) ?? null; }
  function ids(zone) {
    if (island) return zone === "hidden" ? BarLayout.islandHidden(screenName) : BarLayout.islandIn(zone, screenName);
    return zone === "hidden" ? BarLayout.unplaced(screenName)
         : zone === "folder" ? BarLayout.inFolder(screenName)
         : BarLayout.visibleIn(zone, screenName);
  }

  // the bands show placed modules only; the stored order holds the rest too,
  // so the slot is translated through its visible neighbours
  function drop(id, zone, index) {
    if (island) {
      // a slot among the band's chips is a slot in its list: no hidden ones in between
      const current = BarLayout.islandIn(zone, screenName).indexOf(id);
      BarLayout.islandMove(id, zone, current >= 0 && index > current ? index - 1 : index, screenName);
    } else if (zone === "hidden") {
      BarLayout.setEnabled(id, false, screenName);
    } else if (zone === "folder") {
      BarLayout.setFolder(id, index, screenName);
    } else {
      if (BarLayout.unplaced(screenName).includes(id)) BarLayout.setEnabled(id, true, screenName);
      const visible = BarLayout.visibleIn(zone, screenName);
      const current = visible.indexOf(id);
      const slot = current >= 0 && index > current ? index - 1 : index;
      const others = visible.filter(v => v !== id);
      const full = layout[zone].filter(v => v !== id);
      const at = slot < others.length ? full.indexOf(others[slot])
               : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
               : full.length;
      BarLayout.move(id, zone, at, screenName);
    }
  }

  spacing: Theme.gapGroup

  // ---- bars ----
  // the main bar and its child bars; the page below sets up the one picked
  KitLabel { id: barsGroup; text: "BARS"; value: (1 + BarLayout.bars.length) + " IN ALL" }

  Item {
    width: parent.width
    height: addButton.height

    KitChoices {
      anchors { left: parent.left; right: addButton.left; rightMargin: Theme.gapSmall }
      stretch: true
      model: [{ label: "Main", value: "main", icon: "layout" }].concat(BarLayout.bars.map((b, i) => ({
        label: "Bar " + (i + 2) + " · " + b.side, value: b.id, icon: "circle" })))
      current: root.barId
      onPicked: value => root.barId = value
    }

    KitButton {
      id: addButton
      anchors.right: parent.right
      icon: "plus"
      text: "Add bar"
      onClicked: root.barId = BarLayout.addBar()
    }
  }

  KitLine {}

  Column {
    id: mainBar
    visible: root.barId === "main"
    width: parent.width
    spacing: Theme.gapGroup

    // ---- monitor ----
    KitLabel { id: monitorGroup; text: "MONITOR" }

    KitChoices {
      visible: root.roles.length > 1 && !BarLayout.shared
      width: parent.width
      stretch: true
      model: root.roles.map(n => ({ label: (BarLayout.roleOf(n) === "main" ? "Main · " : "Extra · ") + n, value: n,
                                    icon: BarLayout.isInternal(n) ? "laptop" : "monitor" }))
      current: root.screenName
      onPicked: value => root.screenName = value
    }

    KitRow {
      visible: Quickshell.screens.length > 1
      label: "Same bar everywhere"
      hint: BarLayout.shared ? "Every monitor shows one bar" : "Main: external monitor, or the laptop alone · Extra: laptop while docked"

      KitSwitch {
        checked: BarLayout.shared
        onToggled: {
          BarLayout.setShared(!BarLayout.shared);
          root.screenName = BarLayout.mainScreen();
        }
      }
    }

    KitRow {
      label: "Show bar"
      hint: root.barOn ? "On " + root.screenName : "No bar on " + root.screenName

      KitSwitch {
        checked: root.barOn
        onToggled: BarLayout.setBarOn(root.screenName, !root.barOn)
      }
    }

    KitLine {}

    // ---- style ----
    // the bar's shape: one strip, or the island alone with every module in it
    KitLabel { id: styleGroup; text: "STYLE"; value: root.island ? "ISLAND" : "SOLID" }

    KitRow {
      wide: true
      label: "Shape"
      hint: "Strip, or one live island"

      KitChoices {
        stretch: true
        model: [
          { label: "Solid",  value: "solid" },
          { label: "Island", value: "island" }
        ]
        current: ShellSettings.barStyle
        onPicked: value => ShellSettings.set("barStyle", value)
      }
    }

    KitRow {
      visible: root.island
      label: "Open on hover"
      hint: "Resting on the clock opens the hub"

      KitSwitch {
        checked: ShellSettings.islandHover
        onToggled: ShellSettings.set("islandHover", !checked)
      }
    }

    KitRow {
      visible: root.island
      label: "Clock"
      hint: "Off and nothing beside it: hidden"

      KitSwitch {
        checked: BarLayout.islandClock(root.screenName)
        onToggled: BarLayout.setIslandClock(root.screenName, !checked)
      }
    }

    KitLine { visible: root.barOn }

    // ---- layout ----
    Item {
      id: layoutGroup
      visible: root.barOn
      width: parent.width
      height: layoutActions.height

      KitLabel {
        anchors { left: parent.left; right: layoutActions.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        text: "LAYOUT"
        // what the pointer is on, or how this works
        value: root.focusId !== "" ? (root.module(root.focusId)?.label ?? "").toUpperCase() + " — " + (root.module(root.focusId)?.about ?? "").toUpperCase()
                                   : root.island ? "LEFT AND RIGHT SIT BESIDE THE CLOCK" : "DRAG CHIPS TO ARRANGE"
        valueColor: root.focusId !== "" ? Theme.foreground2 : Theme.muted
      }

      Row {
        id: layoutActions
        anchors.right: parent.right
        spacing: Theme.gapSmall

        KitButton {
          visible: root.other !== "" && !BarLayout.shared
          icon: BarLayout.isInternal(root.other) ? "laptop" : "monitor"
          text: "Same as " + root.other
          onClicked: root.island ? BarLayout.islandCopy(root.other, root.screenName)
                                 : BarLayout.copyLayout(root.other, root.screenName)
        }

        KitButton {
          icon: "rotate-ccw"
          text: "Reset"
          disabled: root.island ? !BarLayout.islandCustomized(root.screenName) : !BarLayout.customized(root.screenName)
          onClicked: root.island ? BarLayout.islandReset(root.screenName) : BarLayout.reset(root.screenName)
        }
      }
    }

    // a glance at the bar; what does not fit a side shows as +N
    BarPreview {
      visible: root.barOn
      width: parent.width
      screenName: root.screenName
    }

    // a band per zone, the folder and HIDDEN: chips in bar order, dragged between bands
    KitChipBands {
      id: chips
      visible: root.barOn
      width: parent.width
      zones: root.columnZones
      idsOf: zone => root.ids(zone)
      labelOf: id => root.module(id)?.label ?? id
      iconOf: id => BarLayout.icon(id)
      zoneLabel: zone => ({ start: "LEFT", end: "RIGHT" })[zone] ?? zone.toUpperCase()
      emptyText: zone => zone === "hidden" ? "nothing hidden"
                       : zone === "start" || zone === "end" ? "empty — beside the clock while it rests"
                       : zone === "hub" ? "empty — chips when the island opens"
                       : zone === "folder" ? "empty — modules here open from the Folder icon" : "empty"
      onDropped: (id, zone, index) => root.drop(id, zone, index)
    }
  }

  ChildBarOptions {
    visible: root.barId !== "main"
    width: parent.width
    barId: root.barId === "main" ? "" : root.barId
    onRemoved: root.barId = "main"
  }

  KitLine {}

  // the icons' size: for every bar
  KitRow {
    wide: true
    label: "Icon size"
    hint: "Pixels added to the bar's icons"

    KitChoices {
      stretch: true
      model: [
        { label: "Small",  value: 0 },
        { label: "Normal", value: 2 },
        { label: "Large",  value: 4 }
      ]
      current: ShellSettings.barIconGrow
      onPicked: value => ShellSettings.set("barIconGrow", value)
    }
  }

  // a right click on a module opens its options (the module's own page)
  KitRow {
    label: "Settings on right click"
    hint: "Opens a module's options"

    KitSwitch {
      checked: ShellSettings.barRightSettings
      onToggled: ShellSettings.set("barRightSettings", !checked)
    }
  }
}
