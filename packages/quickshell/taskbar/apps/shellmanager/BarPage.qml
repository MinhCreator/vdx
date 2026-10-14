import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: the icon style shared by every bar, then one monitor at a time —
// whether it has a bar, its three zones to arrange (drag an icon within a zone
// or into another one) and every module with its on / off switch.
Column {
  id: root

  property string dragId: ""
  property string dropZone: ""
  property int dropIndex: -1
  property string hoverId: ""

  // a monitor in the role being set up (main first)
  property string screenName: BarLayout.mainScreen()
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property var layout: BarLayout.layout(screenName)
  readonly property var hidden: BarLayout.hidden(screenName)
  readonly property bool barOn: BarLayout.barOn(screenName)

  readonly property int chipSize: 30
  readonly property int chipSpacing: 4
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  readonly property int onCount: BarLayout.plugins.length - hidden.length
  // three equal zone boxes, all as tall as the fullest one
  readonly property int zoneSpacing: 8
  readonly property real zoneWidth: (width - 2 * zoneSpacing) / 3
  readonly property int perRow: Math.max(1, Math.floor((zoneWidth - 12 + chipSpacing) / (chipSize + chipSpacing)))
  readonly property int zoneRows: Math.max(1, ...BarLayout.zones.map(z => Math.ceil(BarLayout.visibleIn(z, screenName).length / perRow)))

  function zoneOf(id) { return BarLayout.zones.find(z => layout[z].includes(id)) ?? ""; }

  // Drop slot under the pointer (zones coordinates): the zone box under x, then
  // the chip slot in reading order — chips on earlier rows, or left of the
  // pointer on its row, come before it.
  function track(x, y) {
    ghost.x = x - ghost.width / 2;
    ghost.y = y - ghost.height / 2;
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

  // The zones show only plugins that are on; the stored order also holds the
  // off ones, so the slot is translated through its visible neighbours.
  function drop() {
    if (dragId !== "" && dropZone !== "") {
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

  // ---- every bar -------------------------------------------------------------
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

  KitLine {}

  // ---- this monitor ------------------------------------------------------------
  KitLabel {
    text: "MONITOR"
    value: Quickshell.screens.length > 1 ? "SETTINGS BELOW APPLY TO THIS ONE" : "MAIN · " + root.screenName
  }

  KitChoices {
    visible: root.roles.length > 1
    width: parent.width
    stretch: true
    model: root.roles.map(n => ({ label: (BarLayout.roleOf(n) === "main" ? "Main · " : "Extra · ") + n, value: n, icon: BarLayout.isInternal(n) ? "laptop" : "monitor" }))
    current: root.screenName
    onPicked: value => root.screenName = value
  }

  KitText {
    width: parent.width
    text: "Main is the external monitor when one is connected, otherwise the laptop — unplug it and the laptop takes over the main bar. Extra is the laptop screen while docked."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 2
  }

  KitRow {
    label: "Show bar"
    hint: root.barOn ? root.onCount + " modules on " + root.screenName : "no bar on " + root.screenName

    KitSwitch {
      checked: root.barOn
      onToggled: BarLayout.setBarOn(root.screenName, !root.barOn)
    }
  }

  // ---- layout ------------------------------------------------------------------
  Column {
    visible: root.barOn
    width: parent.width
    spacing: 8

    Item {
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
          disabled: root.onCount === BarLayout.plugins.filter(p => p.fixed).length
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

    // three framed zones; each is a drop target and wraps its icons
    Item {
      id: zoneArea
      width: parent.width
      height: zoneRow.height

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
            readonly property alias chips: chipRepeater

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

              Flow {
                id: flow
                x: 6
                y: 6
                width: parent.width - 12
                spacing: root.chipSpacing

                Repeater {
                  id: chipRepeater
                  model: box.ids

                  Rectangle {
                    id: chip

                    required property string modelData
                    required property int index

                    readonly property bool hot: root.hoverId === modelData && root.dragId === ""

                    width: root.chipSize
                    height: root.chipSize
                    color: hot ? Theme.background3 : "transparent"
                    border.width: 1
                    border.color: hot ? Theme.foreground2 : Theme.background3
                    opacity: root.dragId === modelData ? 0.25 : 1

                    KitIcon {
                      anchors.centerIn: parent
                      name: BarLayout.icon(chip.modelData)
                      solid: ShellSettings.solidIcons
                      size: 16
                    }

                    // insertion marker before this chip, or after the last one
                    Rectangle {
                      readonly property bool after: chip.index === box.ids.length - 1 && root.dropIndex === box.ids.length
                      visible: box.target && (root.dropIndex === chip.index || after)
                      x: after ? parent.width + 1 : -3
                      width: 2
                      height: parent.height
                      color: Theme.foreground0
                    }

                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      preventStealing: true
                      cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                      onEntered: root.hoverId = chip.modelData
                      onExited: if (root.hoverId === chip.modelData) root.hoverId = ""
                      onPressed: mouse => {
                        root.dragId = chip.modelData;
                        const p = mapToItem(zoneArea, mouse.x, mouse.y);
                        root.track(p.x, p.y);
                      }
                      onPositionChanged: mouse => {
                        if (root.dragId === "") return;
                        const p = mapToItem(zoneArea, mouse.x, mouse.y);
                        root.track(p.x, p.y);
                      }
                      onReleased: root.drop()
                    }
                  }
                }
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
      width: parent.width
      text: root.focusId !== "" ? BarLayout.label(root.focusId) + " — " + BarLayout.about(root.focusId)
                                : "Drag an icon to reorder it or move it to another zone."
      color: root.focusId !== "" ? Theme.foreground2 : Theme.muted
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize - 1
    }
  }

  KitLine { visible: root.barOn }

  // ---- modules ---------------------------------------------------------------
  KitLabel {
    visible: root.barOn
    text: "MODULES"
    value: root.onCount + " / " + BarLayout.plugins.length + " ON"
  }

  Column {
    visible: root.barOn
    width: parent.width
    spacing: 2

    Repeater {
      model: BarLayout.plugins

      Rectangle {
        id: module

        required property var modelData

        readonly property bool shown: !root.hidden.includes(modelData.id)

        width: parent.width
        height: 44
        color: moduleArea.containsMouse || root.hoverId === modelData.id ? Theme.background1 : "transparent"

        KitIcon {
          id: moduleIcon
          anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
          name: module.modelData.icon
          tint: module.shown ? Theme.foreground0 : Theme.gray
          solid: ShellSettings.solidIcons
          size: 16
        }

        Column {
          anchors {
            left: moduleIcon.right; leftMargin: 12
            right: moduleTrail.left; rightMargin: 12
            verticalCenter: parent.verticalCenter
          }
          spacing: 2

          KitText {
            width: parent.width
            text: module.modelData.label
            color: module.shown ? Theme.foreground0 : Theme.foreground2
            elide: Text.ElideRight
          }

          KitText {
            width: parent.width
            text: module.modelData.about
            color: Theme.muted
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 2
          }
        }

        MouseArea {
          id: moduleArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: module.modelData.fixed ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: if (!module.modelData.fixed) BarLayout.setEnabled(module.modelData.id, !module.shown, root.screenName)
        }

        Row {
          id: moduleTrail
          anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
          spacing: 12

          KitText {
            anchors.verticalCenter: parent.verticalCenter
            text: module.modelData.fixed ? "ALWAYS ON" : module.shown ? root.zoneOf(module.modelData.id).toUpperCase() : "OFF"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 3
            font.letterSpacing: 1
          }

          KitSwitch {
            anchors.verticalCenter: parent.verticalCenter
            checked: module.shown
            disabled: module.modelData.fixed ?? false
            onToggled: BarLayout.setEnabled(module.modelData.id, !module.shown, root.screenName)
          }
        }
      }
    }
  }
}
