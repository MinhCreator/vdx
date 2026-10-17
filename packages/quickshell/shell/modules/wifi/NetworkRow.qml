import QtQuick
import qs.components
import qs.config
import qs.kit

// One nearby network: name, lock for secured ones, check on the current one,
// signal bars. The current row sits in the raised tone; click connects.
Rectangle {
  radius: Theme.radiusControl
  id: root

  required property var modelData

  readonly property bool current: WifiService.connected && modelData.ssid === WifiService.ssid
  readonly property bool connecting: WifiService.connectingSsid === modelData.ssid

  height: 30
  color: current ? Theme.background3 : hover.hovered ? Theme.background1 : "transparent"

  HoverHandler { id: hover }

  KitText {
    id: name
    x: 10
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, check.x - x - 8 - (lock.visible ? lock.width + 6 : 0))
    text: root.modelData.ssid
    elide: Text.ElideRight
    color: root.current || hover.hovered ? Theme.foreground0 : Theme.foreground2
    font.weight: root.current ? Font.ExtraBold : Font.DemiBold
  }

  KitIcon {
    id: lock
    visible: root.modelData.secure
    anchors { left: name.right; leftMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
    name: "lock"
    tint: Theme.muted
    size: 12
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: root.current ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: WifiService.connectTo(root.modelData)
  }

  KitIcon {
    id: check
    anchors { right: bars.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    opacity: root.current ? 1 : 0
    name: "check"
    tint: Theme.green
    size: Theme.iconSmall
  }

  Item {
    id: bars
    anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    width: 18
    height: 14

    SignalBars {
      anchors.centerIn: parent
      visible: !root.connecting
      strength: root.modelData.signal
    }

    KitSpinner {
      anchors.centerIn: parent
      visible: root.connecting
    }
  }
}
