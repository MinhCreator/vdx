import QtQuick
import qs.bar
import qs.config
import qs.kit
import qs.modules.battery

// One block of Bar › Live, a settings section: a small-caps caption, then its rows (the page's KitGrouper boxes them) — a drag
// handle, a same-size sample of the pill, the name, a switch. The row order is
// the priority; drag a row by its handle to move it.
Column {
  id: root

  property string section: ""
  property string title: ""
  property string about: ""
  property var info: ({})                      // kind -> { label, hint }

  readonly property var kinds: ShellSettings.liveOrdered(section)
  readonly property int rowHeight: 52

  // the rows keep their items while one is dragged: a ListModel moves them, a
  // new array would rebuild them and drop the grip's press
  readonly property ListModel order: ListModel {}
  function sync() {
    if (root.order.count === kinds.length && kinds.every((k, i) => root.order.get(i).kind === k)) return;
    root.order.clear();
    for (const k of kinds) root.order.append({ kind: k });
  }
  onKindsChanged: sync()
  Component.onCompleted: sync()

  // the dragged row goes to the slot under the pointer (y in this column)
  function dragTo(kind, y) {
    const first = rows.itemAt(0);
    if (!first) return;
    const at = Math.max(0, Math.min(root.order.count - 1, Math.floor((y - first.y) / (rowHeight + spacing))));
    let from = -1;
    for (let i = 0; i < root.order.count; i++) if (root.order.get(i).kind === kind) from = i;
    if (from < 0 || from === at) return;
    root.order.move(from, at, 1);
    const list = [];
    for (let i = 0; i < root.order.count; i++) list.push(root.order.get(i).kind);
    ShellSettings.liveSetOrder(section, list);
  }

  KitLabel { text: root.title; about: root.about }

  Repeater {
    id: rows
    model: root.order

    Item {
      id: row
      required property string kind
      required property int index
      readonly property bool on: ShellSettings.liveKind(kind)
      // what is not here cannot run: the row says so and keeps its switch out of reach
      readonly property string missing: kind === "vpn" && !BarLayout.installed("mihomo") ? "Not installed"
        : kind === "backup" && !BarLayout.installed("backup") ? "Not installed"
        : kind === "battery" && !BatteryService.present ? "No battery in this machine"
        : kind === "music" && !BarLayout.installed("music") ? "Not installed" : ""

      width: root.width
      height: root.rowHeight
      z: grip.pressed ? 5 : 0
      scale: grip.pressed ? 1.02 : 1
      Behavior on scale { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }

      // lifted while dragged: a raised plate with a frame under the row
      Rectangle {
        anchors { fill: parent; margins: -Theme.gapSmall }
        z: -1
        visible: grip.pressed
        radius: Theme.radiusControl
        color: Theme.pickFill
        border.width: Theme.frameWidth
        border.color: Theme.controlLineHover
      }

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
          onPositionChanged: mouse => { if (pressed) root.dragTo(row.kind, mapToItem(root, mouse.x, mouse.y).y); }
        }
      }

      LivePreview {
        id: preview
        anchors { left: handle.right; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        kind: row.kind
        opacity: row.on && ShellSettings.liveEnabled && row.missing === "" ? 1 : 0.45
      }

      Column {
        anchors { left: preview.right; leftMargin: Theme.gapWide; right: sw.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight
        KitText { width: parent.width; text: root.info[row.kind]?.label ?? row.kind; elide: Text.ElideRight }
        KitText { width: parent.width; text: row.missing !== "" ? row.missing : (root.info[row.kind]?.hint ?? ""); color: Theme.muted; font.pixelSize: Theme.fontSize - 1; elide: Text.ElideRight }
      }

      KitSwitch {
        id: sw
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        checked: row.on
        enabled: row.missing === ""
        onToggled: row.kind === "notice"
          ? ModuleSettings.set("notifications", "appear", checked ? "card" : "live")
          : ShellSettings.setLook("live" + row.kind.charAt(0).toUpperCase() + row.kind.slice(1), !checked, "island")
      }
    }
  }

  KitGrouper {}
}
