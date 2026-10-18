import QtQuick
import qs.components
import qs.config
import qs.kit

// One device: its kind, name, and on the right its battery or state. A click
// connects or disconnects it (a new one is paired first).
Rectangle {
  id: root
  radius: Theme.radiusControl

  required property var modelData

  readonly property bool busy: BluetoothService.busyMac === modelData.mac
  readonly property string glyph: modelData.icon.startsWith("audio") ? "headphones"
    : modelData.icon.startsWith("input-keyboard") ? "keyboard"
    : modelData.icon === "computer" ? "laptop" : "bluetooth"

  height: 30
  color: modelData.connected ? Theme.background3 : hover.hovered ? Theme.background1 : Theme.clear
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  HoverHandler { id: hover }

  // the whole row: connect or disconnect
  MouseArea {
    anchors.fill: parent
    enabled: !root.busy
    cursorShape: Qt.PointingHandCursor
    onClicked: BluetoothService.toggleDevice(root.modelData)
  }

  KitIcon {
    id: kind
    x: 10
    anchors.verticalCenter: parent.verticalCenter
    name: root.glyph
    tint: root.modelData.connected ? Theme.foreground0 : Theme.foreground2
    size: Theme.iconSmall
  }

  KitText {
    id: name
    anchors { left: kind.right; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
    width: Math.min(implicitWidth, state.x - x - Theme.gapMedium)
    text: root.modelData.name
    elide: Text.ElideRight
    color: root.modelData.connected || hover.hovered ? Theme.foreground0 : Theme.foreground2
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    font.weight: root.modelData.connected ? Font.ExtraBold : Font.DemiBold
  }

  KitText {
    id: state
    anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    visible: !root.busy
    text: root.modelData.connected ? (root.modelData.battery !== null ? root.modelData.battery + " %" : "Connected")
      : root.modelData.paired ? "Paired" : "New"
    color: root.modelData.connected && root.modelData.battery !== null ? Theme.qualityColor(root.modelData.battery, 60, 25)
      : Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  KitSpinner {
    anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    visible: root.busy
  }
}
