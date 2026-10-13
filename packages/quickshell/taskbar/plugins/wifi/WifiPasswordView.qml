import QtQuick
import qs.components
import qs.config

Column {
  id: root

  spacing: Theme.popupPadding

  onVisibleChanged: if (visible) field.input.forceActiveFocus()

  PopupInfoRow {
    width: parent.width
    label: "NETWORK"
    value: WifiService.selected?.ssid ?? ""
  }

  PopupInput {
    id: field
    width: parent.width
    label: "PASSWORD"
    placeholder: "••••••••"
    echoMode: TextInput.Password
    text: WifiService.password
    onTextEdited: WifiService.password = text
    onAccepted: WifiService.submitPassword()
  }

  Row {
    anchors.right: parent.right
    spacing: 6

    PopupButton {
      label: "CANCEL"
      tint: Theme.foreground0
      onClicked: WifiService.showList()
    }

    PopupButton {
      label: "CONNECT"
      tint: Theme.foreground0
      busy: WifiService.connectingSsid !== ""
      status: WifiService.connectStatus
      disabled: WifiService.password === ""
      onClicked: WifiService.submitPassword()
    }
  }

  PopupError { text: WifiService.connectError }
}
