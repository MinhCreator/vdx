import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: where things are. Groups in one rhythm — a caps title, its rows, a
// line: MONITOR (one bar everywhere or Main / Extra, show bar), LAYOUT (three
// zones and a tray of what is not on this bar; drag between them), STYLE
// (icons, every bar). Switching a plugin off altogether is on the Plugins page.
Column {
  id: root

  property string dragId: ""
  property string dropZone: ""        // left | center | right | tray
  property int dropIndex: -1
  property string hoverId: ""

  // a monitor in the role being set up (main first)
  property string screenName: BarLayout.mainScreen()
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property var layout: BarLayout.layout(screenName)
  readonly property bool barOn: BarLayout.barOn(screenName)
  readonly property var tray: BarLayout.unplaced(screenName)
  readonly property int placed: BarLayout.zones.reduce((n, z) => n + BarLayout.visibleIn(z, screenName).length, 0)

  readonly property int chipSize: 30
  readonly property int chipSpacing: 4
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  // three equal zone boxes, all as tall as the fullest one
  readonly property int zoneSpacing: 8
  readonly property real zoneWidth: (width - 2 * zoneSpacing) / 3
  readonly property int perRow: Math.max(1, Math.floor((zoneWidth - 12 + chipSpacing) / (chipSize + chipSpacing)))
  readonly property int zoneRows: Math.max(1, ...BarLayout.zones.map(z => Math.ceil(BarLayout.visibleIn(z, screenName).length / perRow)))

  // Drop slot under the pointer (zone area coordinates): the tray below the
  // zones, or the zone box under x and the chip slot in reading order.
  function track(x, y) {
    ghost.x = x - ghost.width / 2;
    ghost.y = y - ghost.height / 2;
    if (y > trayBox.y - 6) { dropZone = "tray"; dropIndex = 0; return; }
    for (let i = 0; i < zoneBoxes.count; i++) {
      const box = zoneBoxes.itemAt(i);
      if (x < box.x - zoneRow.spacing / 2 || x > box.x + box.width + zoneRow.spacing / 2) continue;
      let index = 0;
      for (let j = 0; j < box.chips.count; j++) {
        const chip = box.chips.itemAt(j);
        const c = chip.mapToItem(zoneArea, chip.width / 2, chip.height / 2);
        if (c.y < y - root.chipSize / 2 || (Math.abs(c.y - y) <= root.chipSize / 2 && c.x < x)) index = j + 1;
      }
      dropZone = box.zoneName;
      dropIndex = index;
      return;
    }
    dropZone = "";
  }

  // The zones show only placed plugins; the stored order also holds the rest,
  // so the slot is translated through its visible neighbours.
  function drop() {
    if (dragId !== "" && dropZone === "tray") {
      BarLayout.setEnabled(dragId, false, screenName);
    } else if (dragId !== "" && dropZone !== "") {
      if (tray.includes(dragId)) BarLayout.setEnabled(dragId, true, screenName);
      const visible = BarLayout.visibleIn(dropZone, screenName);
      const current = visible.indexOf(dragId);
      const slot = current >= 0 && dropIndex > current ? dropIndex - 1 : dropIndex;
      const others = visible.filter(id => id !== dragId);
      const full = layout[dropZone].filter(id => id !== dragId);
      const index = slot < others.length ? full.indexOf(others[slot])
                  : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
                  : full.length;
      BarLayout.move(dragId, dropZone, index, screenName);
    }
    dragId = "";
    dropZone = "";
    dropIndex = -1;
  }

  spacing: 14

  KitHeader {
    icon: "layout"
    title: "Bar"
    subtitle: Quickshell.screens.filter(s => BarLayout.barOn(s.name)).length + " OF "
      + Quickshell.screens.length + " MONITORS · " + (ShellSettings.solidIcons ? "SOLID ICONS" : "OUTLINE ICONS")
  }

  KitLine {}

  // ---- monitor -------------------------------------------------------------------
  KitLabel {
    text: "MONITOR"
    value: Quickshell.screens.length === 1 ? root.screenName.toUpperCase()
         : BarLayout.shared ? "ONE BAR ON ALL " + Quickshell.screens.length
         : (BarLayout.roleOf(root.screenName) === "main" ? "MAIN · " : "EXTRA · ") + root.screenName.toUpperCase()
  }

  KitRow {
    visible: Quickshell.screens.length > 1
    label: "Same bar everywhere"
    hint: BarLayout.shared ? "every monitor shows the Main bar" : "Main and Extra are set up apart"

    KitSwitch {
      checked: BarLayout.shared
      onToggled: {
        BarLayout.setShared(!BarLayout.shared);
        root.screenName = BarLayout.mainScreen();
      }
    }
  }

  // the monitor being arranged; with one bar everywhere there is nothing to pick
  KitText {
    visible: Quickshell.screens.length > 1 && BarLayout.shared
    width: parent.width
    text: "One layout on every monitor — switch off Same bar everywhere to arrange each apart."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 2
  }

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
    label: "Show bar"
    hint: Quickshell.screens.length > 1 && !BarLayout.shared
      ? "Main: the external monitor, or the laptop alone · Extra: the laptop while docked"
      : root.barOn ? root.placed + " modules placed" : "no bar"

    KitSwitch {
      checked: root.barOn
      onToggled: BarLayout.setBarOn(root.screenName, !root.barOn)
    }
  }

  KitLine { visible: root.barOn }

  // ---- layout ----------------------------------------------------------------------
  Item {
    visible: root.barOn
    width: parent.width
    height: layoutActions.height

    KitLabel {
      anchors { left: parent.left; right: layoutActions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
      text: "LAYOUT"
    }

    Row {
      id: layoutActions
      anchors.right: parent.right
      spacing: 6

      KitButton {
        icon: "trash"
        text: "Clear"
        disabled: root.placed === 0
        onClicked: BarLayout.clear(root.screenName)
      }

      KitButton {
        icon: "rotate-ccw"
        text: "Reset"
        disabled: !BarLayout.customized(root.screenName)
        onClicked: BarLayout.reset(root.screenName)
      }
    }
  }

  // three zones, then the tray; every box is a drop target and wraps its icons
  Item {
    id: zoneArea
    visible: root.barOn
    width: parent.width
    height: trayBox.y + trayBox.height

    Row {
      id: zoneRow
      width: parent.width
      spacing: root.zoneSpacing

      Repeater {
        id: zoneBoxes
        model: BarLayout.zones

        Column {
          id: box

          required property string modelData

          readonly property string zoneName: modelData
          readonly property var ids: BarLayout.visibleIn(modelData, root.screenName)
          readonly property bool target: root.dragId !== "" && root.dropZone === zoneName
          readonly property alias chips: flow.chips

          width: root.zoneWidth
          spacing: 4

          KitText {
            text: box.modelData.toUpperCase() + " · " + box.ids.length
            color: box.target ? Theme.foreground0 : Theme.muted
            font.pixelSize: Theme.fontSize - 3
            font.letterSpacing: 1
          }

          Rectangle {
            width: parent.width
            height: root.zoneRows * (root.chipSize + root.chipSpacing) - root.chipSpacing + 12
            color: box.target ? Theme.background1 : "transparent"
            border.width: Theme.frameWidth
            border.color: box.target ? Theme.foreground2 : Theme.gray

            BarChips {
              id: flow
              x: 6
              y: 6
              width: parent.width - 12
              page: root
              dragArea: zoneArea
              ids: box.ids
              zone: box.zoneName
            }

            KitText {
              visible: box.ids.length === 0
              anchors.centerIn: parent
              text: root.dragId !== "" ? "drop here" : "empty"
              color: Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }
          }
        }
      }
    }

    // not on this bar: switched on, but not placed here
    Column {
      id: trayBox

      readonly property bool target: root.dragId !== "" && root.dropZone === "tray"

      y: zoneRow.height + 12
      width: parent.width
      spacing: 4

      KitText {
        text: "NOT ON THIS BAR · " + root.tray.length
        color: trayBox.target ? Theme.foreground0 : Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      Rectangle {
        width: parent.width
        height: Math.max(root.chipSize, trayChips.implicitHeight) + 12
        color: trayBox.target ? Theme.background1 : "transparent"
        border.width: Theme.frameWidth
        border.color: trayBox.target ? Theme.foreground2 : Theme.gray

        BarChips {
          id: trayChips
          x: 6
          y: 6
          width: parent.width - 12
          page: root
          dragArea: zoneArea
          ids: root.tray
          zone: "tray"
        }

        KitText {
          visible: root.tray.length === 0
          anchors.centerIn: parent
          text: root.dragId !== "" ? "drop here to take it off this bar" : "everything is on the bar"
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }

    // the icon being dragged, following the pointer
    Rectangle {
      id: ghost
      visible: root.dragId !== ""
      width: root.chipSize
      height: root.chipSize
      color: Theme.background3
      border.width: Theme.frameWidth
      border.color: Theme.foreground2

      KitIcon {
        anchors.centerIn: parent
        name: BarLayout.icon(root.dragId)
        solid: ShellSettings.solidIcons
        size: 16
      }
    }
  }

  // what the pointer is on
  KitText {
    visible: root.barOn
    width: parent.width
    text: root.focusId !== "" ? BarLayout.label(root.focusId) + " — " + BarLayout.about(root.focusId)
                              : "Drag an icon between zones, or down to take it off this bar."
    color: root.focusId !== "" ? Theme.foreground2 : Theme.muted
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 1
  }

  KitLine {}

  // ---- style (every bar) -------------------------------------------------------------
  KitLabel { text: "STYLE" }

  KitRow {
    label: "Icons"
    hint: "outlines or filled shapes, on every bar"

    KitChoices {
      model: [
        { label: "Outline", value: false },
        { label: "Solid",   value: true }
      ]
      current: ShellSettings.solidIcons
      onPicked: value => ShellSettings.set("solidIcons", value)
    }
  }
}
