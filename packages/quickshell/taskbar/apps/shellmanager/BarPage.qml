import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: MONITOR (which bar, one bar everywhere, show it), LAYOUT — a strip
// drawn like the bar itself: icons sit left, centre and right as they do on
// screen; drag one along it, or down to the hidden ones and back — and STYLE.
// No boxes: while dragging, a thin line marks where the icon lands.
Column {
  id: root

  property string dragId: ""
  property string dropZone: ""        // left | center | right | hidden
  property int dropIndex: -1
  property real markerX: 0
  property string hoverId: ""

  // the strip's three icon groups, registered by them for track()
  property var groups: ({})

  // a monitor in the role being set up (main first)
  property string screenName: BarLayout.mainScreen()
  readonly property var roles: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))
    .filter((n, i, all) => all.findIndex(o => BarLayout.roleOf(o) === BarLayout.roleOf(n)) === i)
  readonly property string other: roles.find(n => n !== screenName) ?? ""
  readonly property var layout: BarLayout.layout(screenName)
  readonly property bool barOn: BarLayout.barOn(screenName)
  readonly property var hiddenIds: BarLayout.unplaced(screenName)
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  // icons tighten to fit the strip, like the bar fitting its modules
  // the fuller side decides: each side fits its half, so the centre stays centred
  readonly property int centerCount: BarLayout.visibleIn("center", screenName).length
  readonly property int sideCount: Math.max(BarLayout.visibleIn("left", screenName).length,
                                            BarLayout.visibleIn("right", screenName).length)
  readonly property real iconGap: Math.max(2, Math.min(14,
    ((width - (centerCount * 20 + Math.max(0, centerCount - 1) * 14)) / 2 - 12 - 24 - sideCount * 20) / Math.max(1, sideCount - 1)))

  function plugin(id) { return BarLayout.plugins.find(p => p.id === id) ?? null; }

  // where the pointer would drop (strip coordinates): below the strip is
  // the hidden row; on it, the zone by thirds and the slot by icon centres
  function track(x, y) {
    ghost.x = x - ghost.width / 2;
    ghost.y = y - ghost.height / 2;
    if (y > strip.height + 6) { dropZone = "hidden"; dropIndex = 0; return; }
    const zone = x < strip.width / 3 ? "left" : x < 2 * strip.width / 3 ? "center" : "right";
    const group = groups[zone];
    if (!group) return;
    const icons = group.icons;
    let index = 0;
    for (let i = 0; i < icons.count; i++) {
      const it = icons.itemAt(i);
      if (it.mapToItem(strip, it.width / 2, 0).x < x) index = i + 1;
    }
    dropZone = zone;
    dropIndex = index;
    markerX = icons.count === 0 ? group.x + group.width / 2
            : index < icons.count ? group.x + icons.itemAt(index).x - 8
            : group.x + icons.itemAt(icons.count - 1).x + icons.itemAt(icons.count - 1).width + 6;
  }

  // the strip shows placed plugins only; the stored order holds the rest
  // too, so the slot is translated through its visible neighbours
  function drop() {
    if (dragId !== "" && dropZone === "hidden") {
      BarLayout.setEnabled(dragId, false, screenName);
    } else if (dragId !== "" && dropZone !== "") {
      if (hiddenIds.includes(dragId)) BarLayout.setEnabled(dragId, true, screenName);
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
  KitLabel { text: "MONITOR" }

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

  Item {
    id: editor
    visible: root.barOn
    width: parent.width
    height: hiddenRow.y + hiddenRow.height

    // the strip: a bar in miniature, icons grouped as on screen
    Rectangle {
      id: strip
      width: parent.width
      height: 40
      color: Theme.background1

      Repeater {
        model: BarLayout.zones

        Row {
          id: group

          required property string modelData

          readonly property alias icons: groupIcons

          anchors.verticalCenter: parent.verticalCenter
          // the centre group keeps clear of its neighbours
          x: modelData === "left" ? 12
           : modelData === "right" ? strip.width - width - 12
           : Math.max(root.groups.left ? root.groups.left.x + root.groups.left.width + 24 : 0,
                      Math.min((strip.width - width) / 2,
                               root.groups.right ? root.groups.right.x - width - 24 : strip.width))
          spacing: root.iconGap

          Component.onCompleted: {
            const g = Object.assign({}, root.groups);
            g[modelData] = group;
            root.groups = g;
          }

          Repeater {
            id: groupIcons
            model: BarLayout.visibleIn(group.modelData, root.screenName)

            Item {
              id: icon

              required property string modelData

              width: 20
              height: 20
              opacity: root.dragId === modelData ? 0.25 : 1

              KitIcon {
                anchors.centerIn: parent
                name: BarLayout.icon(icon.modelData)
                tint: root.hoverId === icon.modelData ? Theme.foreground0 : Theme.foreground2
                solid: ShellSettings.solidIcons
                size: 16
              }

              MouseArea {
                anchors { fill: parent; margins: -5 }
                hoverEnabled: true
                preventStealing: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onEntered: root.hoverId = icon.modelData
                onExited: if (root.hoverId === icon.modelData) root.hoverId = ""
                onPressed: mouse => {
                  root.dragId = icon.modelData;
                  const p = mapToItem(strip, mouse.x, mouse.y);
                  root.track(p.x, p.y);
                }
                onPositionChanged: mouse => {
                  if (root.dragId === "") return;
                  const p = mapToItem(strip, mouse.x, mouse.y);
                  root.track(p.x, p.y);
                }
                onReleased: root.drop()
              }
            }
          }
        }
      }

      // where the dragged icon lands
      Rectangle {
        visible: root.dragId !== "" && root.dropZone !== "" && root.dropZone !== "hidden"
        x: root.markerX
        y: 8
        width: 2
        height: strip.height - 16
        color: Theme.foreground0
      }
    }

    // zone names under their groups
    Item {
      id: captions
      y: strip.height + 6
      width: parent.width
      height: 14

      Repeater {
        model: BarLayout.zones

        KitText {
          required property string modelData
          required property int index
          readonly property bool target: root.dragId !== "" && root.dropZone === modelData
          x: index === 0 ? 0 : index === 1 ? (parent.width - width) / 2 : parent.width - width
          text: modelData.toUpperCase() + " · " + BarLayout.visibleIn(modelData, root.screenName).length
          color: target ? Theme.foreground0 : Theme.muted
          font.pixelSize: Theme.fontSize - 3
          font.letterSpacing: 1
        }
      }
    }

    // hidden on this bar: on, but not placed here
    Column {
      id: hiddenRow

      readonly property bool target: root.dragId !== "" && root.dropZone === "hidden"

      y: captions.y + captions.height + 16
      width: parent.width
      spacing: 8

      KitText {
        text: "HIDDEN ON THIS BAR · " + root.hiddenIds.length
        color: hiddenRow.target ? Theme.foreground0 : Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      Flow {
        width: parent.width
        spacing: 18

        Repeater {
          model: root.hiddenIds

          Item {
            id: chip

            required property string modelData

            width: chipRow.implicitWidth
            height: chipRow.implicitHeight
            opacity: root.dragId === modelData ? 0.25 : 1

            Row {
              id: chipRow
              spacing: 6

              KitIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: BarLayout.icon(chip.modelData)
                tint: chipArea.containsMouse ? Theme.foreground0 : Theme.muted
                solid: ShellSettings.solidIcons
                size: 14
              }

              KitText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.plugin(chip.modelData)?.label ?? chip.modelData
                color: chipArea.containsMouse ? Theme.foreground0 : Theme.muted
                font.pixelSize: Theme.fontSize - 1
              }
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
                const p = mapToItem(strip, mouse.x, mouse.y);
                root.track(p.x, p.y);
              }
              onPositionChanged: mouse => {
                if (root.dragId === "") return;
                const p = mapToItem(strip, mouse.x, mouse.y);
                root.track(p.x, p.y);
              }
              onReleased: root.drop()
            }
          }
        }
      }

      KitText {
        visible: root.hiddenIds.length === 0
        text: root.dragId !== "" ? "drop here to hide it on this bar" : "Nothing hidden — drag an icon down here to hide it."
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }
    }

    // the icon being dragged
    KitIcon {
      id: ghost
      z: 10
      visible: root.dragId !== ""
      name: BarLayout.icon(root.dragId)
      solid: ShellSettings.solidIcons
      size: 18
    }
  }

  // what the pointer is on
  KitText {
    visible: root.barOn
    width: parent.width
    text: root.focusId !== "" ? (root.plugin(root.focusId)?.label ?? "") + " — " + (root.plugin(root.focusId)?.about ?? "")
                              : "Drag icons along the bar to arrange them."
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
