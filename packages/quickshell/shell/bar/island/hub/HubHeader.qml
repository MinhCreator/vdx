import QtQuick
import qs.apps.packages
import qs.bar.island
import qs.config
import qs.kit
import qs.modules.battery
import qs.modules.sysmon

// The hub's head: the date, the clock as the hero number, a status line (uptime,
// updates waiting, battery) and the settings and power buttons.
Item {
  id: root

  property date now: new Date()
  signal manager()
  signal power()

  implicitHeight: column.implicitHeight

  // the sampler (uptime) runs while the hub is on screen
  property bool held: false
  onVisibleChanged: sync()
  Component.onCompleted: sync()
  Component.onDestruction: if (held) SysmonService.release()
  function sync() {
    if (visible === held) return;
    held = visible;
    if (held) SysmonService.hold(); else SysmonService.release();
  }

  function uptime(s) {
    const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60);
    return s <= 0 ? "" : h > 0 ? "Up " + h + " h" : "Up " + m + " min";
  }
  // the numbers in the status line are bold
  readonly property string status: {
    const up = uptime(SysmonService.uptime);
    const rest = [];
    if (PackagesService.count > 0) rest.push("<b>" + PackagesService.count + " update" + (PackagesService.count === 1 ? "" : "s") + "</b> waiting");
    if (BatteryService.present) rest.push((rest.length || up === "" ? "battery" : "Battery") + " <b>" + BatteryService.capacity + "%</b>");
    return [up, rest.join(", ")].filter(x => x !== "").join(". ") + ".";
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right }
    spacing: 6

    Item {
      width: parent.width
      height: clock.height + date.height

      Column {
        anchors { left: parent.left; top: parent.top }
        KitText {
          id: date
          text: Qt.formatDateTime(root.now, "dddd, d MMMM")
          color: Theme.foreground2
          font.pixelSize: 13
        }
        KitText {
          id: clock
          text: Qt.formatDateTime(root.now, "HH:mm")
          font.pixelSize: 56
          font.letterSpacing: -1.6
        }
      }

      Row {
        anchors { right: parent.right; top: parent.top }
        spacing: 8

        Repeater {
          model: [{ icon: "settings", sig: "manager" }, { icon: "power", sig: "power" }]

          Rectangle {
            required property var modelData
            width: 40
            height: 40
            radius: 20
            color: area.containsMouse ? Theme.background3 : Theme.background2

            KitIcon { anchors.centerIn: parent; name: parent.modelData.icon; size: 16 }
            MouseArea {
              id: area
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: parent.modelData.sig === "manager" ? root.manager() : root.power()
            }
          }
        }
      }
    }

    KitText {
      width: parent.width
      text: root.status
      textFormat: Text.StyledText
      color: Theme.muted
      font.pixelSize: 12
      elide: Text.ElideRight
    }
  }
}
