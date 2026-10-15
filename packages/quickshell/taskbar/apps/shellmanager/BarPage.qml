import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: MONITOR (which bar, one bar everywhere, show it), LAYOUT and STYLE.
// LAYOUT: a small preview of the bar, then four rows — LEFT, CENTER, RIGHT
// and HIDDEN — the zone's name on the left, its icon + name chips in bar
// order on the right, wrapping (Material chips); thin lines, no boxes. Drag a chip along a band, to another band or into
// HIDDEN; a thin line marks where it lands.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "layout"
  readonly property string title: "Bar"
  readonly property string subtitle: Quickshell.screens.filter(s => BarLayout.barOn(s.name)).length + " OF "
    + Quickshell.screens.length + " MONITORS · " + ShellSettings.underlineAnimation.toUpperCase() + " UNDERLINE"

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "monitor", label: "Monitor", y: monitorGroup.y },
    { key: "layout",  label: "Layout",  y: root.barOn ? layoutGroup.y : -2 },
    { key: "style",   label: "Style",   y: styleGroup.y }
  ].filter(j => j.y > -2)

  property string dragId: ""
  property string dropZone: ""        // left | center | right | hidden
  property int dropIndex: -1
  property string hoverId: ""

  // a monitor in the role being set up (main first)
  property string screenName: BarLayout.mainScreen()
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property string other: roles.find(n => n !== screenName) ?? ""
  readonly property var layout: BarLayout.layout(screenName)
  readonly property bool barOn: BarLayout.barOn(screenName)
  readonly property var columnZones: ["left", "center", "right", "folder", "hidden"]
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  readonly property int chipHeight: 28

  function plugin(id) { return BarLayout.plugins.find(p => p.id === id) ?? null; }
  function ids(zone) {
    return zone === "hidden" ? BarLayout.unplaced(screenName)
         : zone === "folder" ? BarLayout.inFolder(screenName)
         : BarLayout.visibleIn(zone, screenName);
  }

  // where the pointer would drop (zones coordinates): the zone band under y,
  // then the chip slot in reading order — chips on earlier lines, or left of
  // the pointer on its line, come before it
  function track(x, y) {
    ghost.x = x + 10;
    ghost.y = y - ghost.height / 2;
    for (let i = 0; i < bands.count; i++) {
      const band = bands.itemAt(i);
      if (y < band.y - 6 || y > band.y + band.height + 6) continue;
      let index = 0;
      const chips = band.chips;
      for (let j = 0; j < chips.count; j++) {
        const c = chips.itemAt(j);
        const p = c.mapToItem(zonesArea, c.width / 2, c.height / 2);
        if (p.y < y - root.chipHeight / 2 || (Math.abs(p.y - y) <= root.chipHeight / 2 && p.x < x)) index = j + 1;
      }
      dropZone = band.zone;
      dropIndex = index;
      return;
    }
    dropZone = "";
  }

  // the bands show placed plugins only; the stored order holds the rest too,
  // so the slot is translated through its visible neighbours
  function drop() {
    if (dragId !== "" && dropZone === "hidden") {
      BarLayout.setEnabled(dragId, false, screenName);
    } else if (dragId !== "" && dropZone === "folder") {
      BarLayout.setFolder(dragId, dropIndex, screenName);
    } else if (dragId !== "" && dropZone !== "") {
      if (BarLayout.unplaced(screenName).includes(dragId)) BarLayout.setEnabled(dragId, true, screenName);
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

  // ---- monitor -------------------------------------------------------------------
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
    hint: BarLayout.shared ? "every monitor shows one bar" : "Main: external monitor, or the laptop alone · Extra: laptop while docked"

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
    hint: root.barOn ? "on " + root.screenName : "no bar on " + root.screenName

    KitSwitch {
      checked: root.barOn
      onToggled: BarLayout.setBarOn(root.screenName, !root.barOn)
    }
  }

  KitLine { visible: root.barOn }

  // ---- layout ----------------------------------------------------------------------
  Item {
    id: layoutGroup
    visible: root.barOn
    width: parent.width
    height: layoutActions.height

    KitLabel {
      anchors { left: parent.left; right: layoutActions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
      text: "LAYOUT"
      // what the pointer is on, or how this works
      value: root.focusId !== "" ? (root.plugin(root.focusId)?.label ?? "").toUpperCase() + " — " + (root.plugin(root.focusId)?.about ?? "").toUpperCase()
                                 : "DRAG CHIPS TO ARRANGE"
      valueColor: root.focusId !== "" ? Theme.foreground2 : Theme.muted
    }

    Row {
      id: layoutActions
      anchors.right: parent.right
      spacing: 6

      KitButton {
        visible: root.other !== "" && !BarLayout.shared
        icon: BarLayout.isInternal(root.other) ? "laptop" : "monitor"
        text: "Same as " + root.other
        onClicked: BarLayout.copyLayout(root.other, root.screenName)
      }

      KitButton {
        icon: "rotate-ccw"
        text: "Reset"
        disabled: !BarLayout.customized(root.screenName)
        onClicked: BarLayout.reset(root.screenName)
      }
    }
  }

  // a glance at the bar; what does not fit a side shows as +N
  BarPreview {
    visible: root.barOn
    width: parent.width
    screenName: root.screenName
  }

  // four bands, one per zone and HIDDEN: chips of icon + name in bar order
  // that wrap across the width, so even a full zone takes a line or two
  Column {
    id: zonesArea
    visible: root.barOn
    width: parent.width
    spacing: 0

    Repeater {
      id: bands
      model: root.columnZones

      // a settings-style row: the zone's name on the left, its chips on the
      // right, a thin line between rows; no boxes
      Item {
        id: band

        required property string modelData
        required property int index

        readonly property string zone: modelData
        readonly property var ids: root.ids(modelData)
        readonly property bool target: root.dragId !== "" && root.dropZone === modelData
        readonly property alias chips: chipRepeater

        width: zonesArea.width
        height: area.height + 12

        KitText {
          y: 8 + (root.chipHeight - height) / 2
          text: band.zone.toUpperCase() + " · " + band.ids.length
          color: band.target ? Theme.foreground0 : Theme.muted
          font.pixelSize: Theme.fontSize - 3
          font.letterSpacing: 1
        }

        // the chips; a faint fill marks the row a chip is dragged over
        Rectangle {
          id: area
          x: 110
          y: 8
          width: parent.width - x
          height: Math.max(root.chipHeight, flow.implicitHeight)
          color: band.target ? Theme.background1 : "transparent"

          Flow {
            id: flow
            width: parent.width
            spacing: 6

            Repeater {
              id: chipRepeater
              model: band.ids

              Rectangle {
                id: chip

                required property string modelData
                required property int index

                width: chipRow.implicitWidth + 20
                height: root.chipHeight
                color: chipArea.containsMouse && root.dragId === "" ? Theme.background3 : Theme.background1
                opacity: root.dragId === modelData ? 0.25 : 1

                Row {
                  id: chipRow
                  anchors.centerIn: parent
                  spacing: 6

                  KitIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: BarLayout.icon(chip.modelData)
                    tint: band.zone === "hidden" ? Theme.muted : Theme.foreground2
                    size: 14
                  }

                  KitText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.plugin(chip.modelData)?.label ?? chip.modelData
                    color: band.zone === "hidden" ? Theme.muted : Theme.foreground0
                    font.pixelSize: Theme.fontSize - 1
                  }
                }

                // insertion marker before this chip, or after the last one
                Rectangle {
                  readonly property bool after: chip.index === band.ids.length - 1 && root.dropIndex === band.ids.length
                  visible: band.target && (root.dropIndex === chip.index || after)
                  x: after ? parent.width + 2 : -4
                  width: 2
                  height: parent.height
                  color: Theme.foreground0
                }

                MouseArea {
                  id: chipArea
                  anchors.fill: parent
                  hoverEnabled: true
                  preventStealing: true
                  cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                  onEntered: root.hoverId = chip.modelData
                  onExited: if (root.hoverId === chip.modelData) root.hoverId = ""
                  onPressed: mouse => {
                    root.dragId = chip.modelData;
                    const p = mapToItem(zonesArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onPositionChanged: mouse => {
                    if (root.dragId === "") return;
                    const p = mapToItem(zonesArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onReleased: root.drop()
                }
              }
            }
          }

          KitText {
            visible: band.ids.length === 0
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: root.dragId !== "" ? "drop here" : band.zone === "hidden" ? "nothing hidden"
                : band.zone === "folder" ? "empty — modules here open from the Folder icon" : "empty"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
        }
      }
    }

    // the chip being dragged, following the pointer
    KitText {
      id: ghost
      z: 10
      visible: root.dragId !== ""
      text: root.plugin(root.dragId)?.label ?? ""
      font.weight: Font.ExtraBold
    }
  }


  KitLine {}

  // ---- style (every bar) -------------------------------------------------------------
  KitLabel { id: styleGroup; text: "STYLE" }

  KitRow {
    wide: true
    label: "Underline"
    hint: "the line under an open module"

    KitChoices {
      stretch: true
      model: [
        { label: "None",  value: "none" },
        { label: "Grow",  value: "grow" },
        { label: "Slide", value: "slide" }
      ]
      current: ShellSettings.underlineAnimation
      onPicked: value => ShellSettings.set("underlineAnimation", value)
    }
  }
}
