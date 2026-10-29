import QtQuick
import qs.config
import qs.kit

// Password for a secured network that isn't saved yet.
Column {
  id: root

  spacing: Theme.sectionGap

  onVisibleChanged: if (visible) field.input.forceActiveFocus()

  KitLine {}

  Column {
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel { text: "PASSWORD" }

    KitInput {
      id: field
      placeholder: "••••••••"
      echoMode: TextInput.Password
      text: WifiService.password
      onTextEdited: WifiService.password = text
      onAccepted: WifiService.submitPassword()
    }

    KitText {
      width: parent.width
      visible: WifiService.connectError !== ""
      text: WifiService.connectError
      color: Theme.red
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }
  }

  KitLine {}

  Row {
    anchors.right: parent.right
    spacing: Theme.gapMedium

    KitButton {
      text: "Cancel"
      onClicked: WifiService.showList()
    }

    KitButton {
      icon: "check"
      text: "Connect"
      selected: true
      busy: WifiService.connectionBusy
      disabled: WifiService.password === "" || WifiService.connectionBusy
      onClicked: WifiService.submitPassword()
    }
  }
}
