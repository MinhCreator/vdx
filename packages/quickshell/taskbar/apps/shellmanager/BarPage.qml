import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: MONITOR (which bar, one bar everywhere, show it), LAYOUT and STYLE.
// LAYOUT: a small preview of the bar, then four columns — LEFT, CENTER, RIGHT
// and HIDDEN — of icon + name rows in bar order. Drag a row up or down, to
// another column, or into HIDDEN; a thin line marks where it lands. Columns
// grow downward, so any number of plugins fits and every name stays readable.
Column {
  id: root

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
  readonly property var columnZones: ["left", "center", "right", "hidden"]
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  readonly property int rowHeight: 28
  readonly property int columnGap: 16
  readonly property real columnWidth: (width - 3 * columnGap) / 4
  // every well as tall as the longest column, plus a row to drop into
  readonly property int maxRows: Math.max(1, ...columnZones.map(z => ids(z).length))

  function plugin(id) { return BarLayout.plugins.find(p => p.id === id) ?? null; }
  function ids(zone) { return zone === "hidden" ? BarLayout.unplaced(screenName) : BarLayout.visibleIn(zone, screenName); }

  // where the pointer would drop (columns coordinates): the column under x,
  // the row gap nearest to y below its title
  function track(x, y) {
    ghost.x = x + 10;
    ghost.y = y - ghost.height / 2;
    const col = Math.max(0, Math.min(3, Math.floor((x + columnGap / 2) / (columnWidth + columnGap))));
    dropZone = columnZones[col];
    dropIndex = Math.max(0, Math.min(ids(dropZone).length, Math.round((y - columns.listY) / rowHeight)));
  }

  // columns show placed plugins only; the stored order holds the rest too,
  // so the slot is translated through its visible neighbours
  function drop() {
    if (dragId !== "" && dropZone === "hidden") {
      BarLayout.setEnabled(dragId, false, screenName);
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

  // a glance at the bar; what does not fit a side shows as +N
  BarPreview {
    visible: root.barOn
    width: parent.width
    screenName: root.screenName
  }

  Item {
    id: columns
    visible: root.barOn
    width: parent.width
    height: columnRow.height

    readonly property real listY: 22      // rows start under the column titles

    Row {
      id: columnRow
      width: parent.width
      spacing: root.columnGap

      Repeater {
        model: root.columnZones

        Column {
          id: column

          required property string modelData

          readonly property var ids: root.ids(modelData)
          readonly property bool target: root.dragId !== "" && root.dropZone === modelData

          width: root.columnWidth

          KitText {
            height: columns.listY
            text: column.modelData.toUpperCase() + " · " + column.ids.length
            color: column.target ? Theme.foreground0 : Theme.muted
            font.pixelSize: Theme.fontSize - 3
            font.letterSpacing: 1
          }

          // an outlined column: where rows can be dropped
          Rectangle {
            width: parent.width
            height: (root.maxRows + 1) * root.rowHeight
            color: column.target ? Theme.background1 : "transparent"
            border.width: 1
            border.color: column.target ? Theme.foreground2 : Theme.background3

            Repeater {
              model: column.ids

              Rectangle {
                id: row

                required property string modelData
                required property int index

                y: index * root.rowHeight
                width: parent.width
                height: root.rowHeight
                color: rowArea.containsMouse && root.dragId === "" ? Theme.background1 : "transparent"
                opacity: root.dragId === modelData ? 0.25 : 1

                KitIcon {
                  id: rowIcon
                  anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                  name: BarLayout.icon(row.modelData)
                  tint: column.modelData === "hidden" ? Theme.muted : Theme.foreground2
                  solid: ShellSettings.solidIcons
                  size: 14
                }

                KitText {
                  anchors { left: rowIcon.right; leftMargin: 8; right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                  text: root.plugin(row.modelData)?.label ?? row.modelData
                  elide: Text.ElideRight
                  color: column.modelData === "hidden" ? Theme.muted : Theme.foreground0
                  font.pixelSize: Theme.fontSize - 1
                }

                MouseArea {
                  id: rowArea
                  anchors.fill: parent
                  hoverEnabled: true
                  preventStealing: true
                  cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                  onEntered: root.hoverId = row.modelData
                  onExited: if (root.hoverId === row.modelData) root.hoverId = ""
                  onPressed: mouse => {
                    root.dragId = row.modelData;
                    const p = mapToItem(columns, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onPositionChanged: mouse => {
                    if (root.dragId === "") return;
                    const p = mapToItem(columns, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onReleased: root.drop()
                }
              }
            }

            // empty column: a quiet hint where to drop
            KitText {
              visible: column.ids.length === 0
              x: 6
              height: root.rowHeight
              verticalAlignment: Text.AlignVCenter
              text: root.dragId !== "" ? "drop here" : "empty"
              color: Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }

            // where the dragged row lands
            Rectangle {
              visible: column.target
              y: root.dropIndex * root.rowHeight - 1
              width: parent.width
              height: 2
              color: Theme.foreground0
            }
          }
        }
      }
    }

    // the row being dragged, following the pointer
    KitText {
      id: ghost
      z: 10
      visible: root.dragId !== ""
      text: root.plugin(root.dragId)?.label ?? ""
      font.weight: Font.ExtraBold
    }
  }

  // what the pointer is on
  KitText {
    visible: root.barOn
    width: parent.width
    text: root.focusId !== "" ? (root.plugin(root.focusId)?.label ?? "") + " — " + (root.plugin(root.focusId)?.about ?? "")
                              : "Drag a row up or down, to another column, or into HIDDEN."
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
