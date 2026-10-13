import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

Item {
  id: root

  required property PanelWindow bar

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: Theme.iconMihomo + " VPN"
    color: MihomoService.serviceOn ? Theme.green : Theme.gray
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "mihomo"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: MihomoService.popupShown()
    onHidden: MihomoService.popupHidden()

    MihomoPopup {
      id: content
      anchors.fill: parent
      onCloseRequested: popup.visible = false
    }
  }
}
