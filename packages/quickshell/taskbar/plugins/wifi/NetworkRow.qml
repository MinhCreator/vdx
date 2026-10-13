import QtQuick
import qs.components
import qs.config

Rectangle {
  id: root

  required property var modelData

  readonly property bool current: WifiService.connected && modelData.ssid === WifiService.ssid
  readonly property bool connecting: WifiService.connectingSsid === modelData.ssid

  height: Theme.rowHeight
  color: hover.hovered ? Theme.background2 : "transparent"

  HoverHandler { id: hover }

  Rectangle {
    visible: root.current
    width: 2
    height: parent.height
    color: Theme.foreground0
  }

  ThemeText {
    id: name
    x: 12
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, check.x - x - 8 - (lock.visible ? lock.width + 6 : 0))
    text: root.modelData.ssid
    elide: Text.ElideRight
    color: root.current || hover.hovered ? Theme.foreground0 : Theme.foreground2
  }

  ThemeText {
    id: lock
    visible: root.modelData.secure
    anchors { left: name.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
    text: Theme.iconLock
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 1
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: root.current ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: WifiService.connectTo(root.modelData)
  }

  ThemeText {
    id: check
    anchors { right: bars.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
    opacity: root.current ? 1 : 0
    text: Theme.iconOk
    color: Theme.green
    font.pixelSize: Theme.fontSize - 1
  }

  Item {
    id: bars
    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    width: 18
    height: 14

    SignalBars {
      anchors.centerIn: parent
      visible: !root.connecting
      strength: root.modelData.signal
    }

    PopupSpinner {
      anchors.centerIn: parent
      visible: root.connecting
      tint: Theme.foreground0
    }
  }
}
