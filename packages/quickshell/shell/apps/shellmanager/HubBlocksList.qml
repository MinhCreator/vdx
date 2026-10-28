import QtQuick
import qs.config
import qs.kit

// The hub's blocks, in the order they have on the hub: the clock and day stand first and
// stay; each other block has a handle (drag to reorder), its name and what it holds, its
// one choice (a size, a mode) and a switch that shows or hides it. Stored by HubBlocks.
Column {
  id: root

  signal arrange()                              // the Hub row of Layout

  readonly property int rowHeight: 56

  // the rows keep their items while one is dragged (a ListModel moves them; a new array rebuilds)
  readonly property ListModel order: ListModel {}
  function sync() {
    const o = HubBlocks.order;
    if (order.count === o.length && o.every((k, i) => order.get(i).id === k)) return;
    order.clear();
    for (const k of o) order.append({ id: k });
  }
  Connections { target: HubBlocks; function onOrderChanged() { root.sync(); } }
  Component.onCompleted: sync()

  function dragTo(id, y) {
    const first = rows.itemAt(0);
    if (!first) return;
    const at = Math.max(0, Math.min(order.count - 1, Math.floor((y - first.y) / (rowHeight + spacing))));
    let from = -1;
    for (let i = 0; i < order.count; i++) if (order.get(i).id === id) from = i;
    if (from < 0 || from === at) return;
    order.move(from, at, 1);
    const list = [];
    for (let i = 0; i < order.count; i++) list.push(order.get(i).id);
    HubBlocks.setOrder(list);
  }

  KitLabel { text: "BLOCKS"; about: "Drag a row to move it on the hub; the switch shows or hides it" }

  // the clock and the day: always the first
  Item {
    width: root.width
    height: root.rowHeight
    Column {
      anchors { left: parent.left; leftMargin: 26; right: fixedTag.left; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapTight
      KitText { width: parent.width; text: "Clock and day" }
      KitText { width: parent.width; text: "The date, the clock and the settings and power buttons"; color: Theme.muted; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
    }
    KitText { id: fixedTag; anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: "ALWAYS ON"; color: Theme.dim; font.pixelSize: Theme.fontSize - 2; font.letterSpacing: 1 }
  }

  Repeater {
    id: rows
    model: root.order

    Item {
      id: row
      required property string id
      required property int index
      readonly property bool on: HubBlocks.shown(id)

      width: root.width
      height: root.rowHeight

      // the handle: two columns of three dots
      Item {
        id: handle
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 12
        height: 22
        Grid {
          anchors.centerIn: parent
          columns: 2
          spacing: 3
          Repeater { model: 6; Rectangle { width: 2; height: 2; color: grip.pressed ? Theme.foreground0 : Theme.dim } }
        }
        MouseArea {
          id: grip
          anchors { fill: parent; margins: -8 }
          preventStealing: true
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          onPositionChanged: mouse => { if (pressed) root.dragTo(row.id, mapToItem(root, mouse.x, mouse.y).y); }
        }
      }

      // lifted while dragged
      Rectangle {
        anchors { fill: parent; margins: -Theme.gapSmall }
        z: -1
        visible: grip.pressed
        radius: Theme.radiusControl
        color: Theme.pickFill
        border.width: Theme.frameWidth
        border.color: Theme.controlLineHover
      }

      Column {
        anchors { left: handle.right; leftMargin: Theme.gapWide; right: choice.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight
        opacity: row.on ? 1 : 0.5
        KitText { width: parent.width; text: HubBlocks.names[row.id]; elide: Text.ElideRight }
        KitText { width: parent.width; text: HubBlocks.notes[row.id]; color: Theme.muted; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
      }

      // the block's one choice
      Item {
        id: choice
        anchors { right: sw.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        width: Math.max(1, choiceRow.implicitWidth)
        height: choiceRow.implicitHeight
        opacity: row.on ? 1 : 0.4
        enabled: row.on

        Row {
          id: choiceRow
          spacing: Theme.gapSmall
          KitSegments {
            visible: row.id === "tiles"
            width: 112
            model: [{ label: "2 ×", value: 2 }, { label: "4 ×", value: 4 }]
            current: ModuleSettings.get("hub", "tileColumns", 2)
            onPicked: value => ModuleSettings.set("hub", "tileColumns", value)
          }
          KitSegments {
            visible: row.id === "week"
            width: 150
            model: [{ label: "Week", value: "week" }, { label: "Month", value: "month" }]
            current: ModuleSettings.get("hub", "calendarMode", "week")
            onPicked: value => ModuleSettings.set("hub", "calendarMode", value)
          }
          KitSegments {
            visible: row.id === "player"
            width: 150
            model: [{ label: "Card", value: "card" }, { label: "Compact", value: "compact" }]
            current: ModuleSettings.get("hub", "playerSize", "card")
            onPicked: value => ModuleSettings.set("hub", "playerSize", value)
          }
          KitSegments {
            visible: row.id === "night"
            width: 190
            model: [{ label: "Always", value: false }, { label: "With night mode", value: true }]
            current: ModuleSettings.get("hub", "nightAuto", true)
            onPicked: value => ModuleSettings.set("hub", "nightAuto", value)
          }
          KitButton { visible: row.id === "modules" || row.id === "tiles"; text: "Arrange…"; onClicked: root.arrange() }
        }
      }

      KitSwitch {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        checked: row.on
        onToggled: HubBlocks.setShown(row.id, !checked)
      }
    }
  }

  KitGrouper {}
}
