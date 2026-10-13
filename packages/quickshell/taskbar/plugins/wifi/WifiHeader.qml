import QtQuick
import qs.components
import qs.config

// Wi-Fi header; nested views (password, speed test) swap it for back + title.
Item {
  id: root

  readonly property bool nested: WifiService.view !== "list"
  readonly property var titles: ({ password: "CONNECT", speedtest: "SPEED TEST" })

  implicitHeight: header.implicitHeight

  PopupHeader {
    id: header
    width: parent.width
    visible: !root.nested
    glyph: Theme.iconWifi
    title: "WI-FI"
    subtitle: WifiService.connected ? "CONNECTED" : "DISCONNECTED"
    subtitleColor: WifiService.connected ? Theme.green : Theme.muted

    PopupButton {
      anchors.verticalCenter: parent.verticalCenter
      glyph: Theme.iconSpeedtest
      glyphSize: Theme.headerButtonSize
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      disabled: !WifiService.connected
      onClicked: WifiService.showSpeedtest()
    }

    PopupSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: WifiService.radioOn
      onToggled: WifiService.toggleRadio()
    }
  }

  PopupButton {
    id: back
    visible: root.nested
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    glyph: Theme.iconArrowLeft
    glyphSize: Theme.fontSize + 2
    tint: Theme.foreground0
    frameless: true
    hoverBackground: false
    onClicked: WifiService.showList()
  }

  ThemeText {
    visible: root.nested
    anchors { left: back.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
    text: root.titles[WifiService.view] ?? ""
    font.letterSpacing: 1
  }
}
