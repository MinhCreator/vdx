import QtQuick
import Quickshell
import qs.config
import qs.kit

// What a locked screen shows (Lock.qml puts it on every monitor): the time,
// the date, the user and a password field; a wrong password says so in red.
Rectangle {
  id: root

  required property var lock                 // Lock.qml: user, busy, error, tryUnlock()

  color: Theme.background0

  SystemClock { id: clock; precision: SystemClock.Minutes }

  Column {
    anchors.centerIn: parent
    width: 360
    spacing: 14

    KitText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatTime(clock.date, "HH:mm")
      font.pixelSize: 72
      font.weight: Font.ExtraBold
    }

    KitText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDate(clock.date, "dddd, d MMMM").toUpperCase()
      color: Theme.muted
      font.letterSpacing: 1
    }

    Item { width: 1; height: 24 }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      KitIcon { anchors.verticalCenter: parent.verticalCenter; name: "lock"; size: 16; tint: Theme.foreground2 }
      KitText { anchors.verticalCenter: parent.verticalCenter; text: root.lock.user }
    }

    KitInput {
      id: field
      width: parent.width
      echoMode: TextInput.Password
      placeholder: "Password"
      enabled: !root.lock.busy
      onAccepted: { root.lock.tryUnlock(text); text = ""; }
      Component.onCompleted: input.forceActiveFocus()
    }

    KitText {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.lock.busy ? "Checking…" : root.lock.error !== "" ? root.lock.error : "Enter to unlock"
      color: root.lock.error !== "" && !root.lock.busy ? Theme.red : Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }
  }
}
