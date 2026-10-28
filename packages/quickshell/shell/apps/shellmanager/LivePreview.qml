import QtQuick
import qs.config
import qs.kit

// A sample of one live activity as the island shows it: the island's surface,
// frame and corners in the current theme, with the activity's face (Bar › Live).
// Sample data.
Rectangle {
  id: root

  property string kind: ""

  implicitWidth: face.implicitWidth + 36
  implicitHeight: Theme.islandHeight + 4
  // the island's own surface, frame and corners (Island.qml): the theme's, sharp or round
  radius: Math.min(Theme.barRadiusFor(height), Theme.islandRadius)
  color: Theme.background0
  border.width: Theme.islandFrameWidth
  border.color: Theme.background2

  Row {
    id: face
    anchors.centerIn: parent
    spacing: 10

    // volume and brightness: the level as thin ticks
    KitIcon { visible: root.kind === "volume"; name: "volume"; size: 16; tint: Theme.foreground2; anchors.verticalCenter: parent.verticalCenter }
    Row {
      visible: root.kind === "volume"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3
      Repeater {
        model: 20
        Rectangle { required property int index; width: 3; height: 14; radius: 1.5; color: index < 13 ? Theme.foreground1 : Theme.background3 }
      }
    }
    KitText { visible: root.kind === "volume"; text: "62"; color: Theme.foreground1 }

    // low battery
    KitIcon { visible: root.kind === "battery"; name: "battery-0"; size: 16; tint: Theme.red; anchors.verticalCenter: parent.verticalCenter }
    KitText { visible: root.kind === "battery"; text: "Battery"; color: Theme.foreground1 }
    KitText { visible: root.kind === "battery"; text: "9%"; color: Theme.red }
    KitText { visible: root.kind === "battery"; text: "· 14 min left"; color: Theme.muted }

    // a device connected
    KitIcon { visible: root.kind === "bluetooth"; name: "bluetooth"; size: 16; tint: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
    KitText { visible: root.kind === "bluetooth"; text: "AirPods Pro"; color: Theme.foreground1 }
    KitText { visible: root.kind === "bluetooth"; text: "80%"; color: Theme.blue }

    // an incoming notification
    Rectangle {
      visible: root.kind === "notice"
      anchors.verticalCenter: parent.verticalCenter
      width: 24; height: 24; radius: 8
      color: Theme.background3
      KitText { anchors.centerIn: parent; text: "T"; font.weight: Font.Medium }
    }
    KitText { visible: root.kind === "notice"; text: "Nikita"; color: Theme.foreground1 }
    KitText { visible: root.kind === "notice"; text: "· Telegram"; color: Theme.muted }

    // recording
    Rectangle { visible: root.kind === "recording"; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.red }
    KitText { visible: root.kind === "recording"; text: "Recording"; color: Theme.foreground2 }
    KitText { visible: root.kind === "recording"; text: "14:32"; color: Theme.foreground1 }

    // update
    KitIcon { visible: root.kind === "update"; name: "download"; size: 16; tint: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
    KitText { visible: root.kind === "update"; text: "Installing 12 packages"; color: Theme.foreground1 }
    Rectangle {
      visible: root.kind === "update"
      anchors.verticalCenter: parent.verticalCenter
      width: 60; height: 4; radius: 2
      color: Theme.background3
      Rectangle { width: parent.width * 0.47; height: parent.height; radius: 2; color: Theme.blue }
    }
    KitText { visible: root.kind === "update"; text: "47%"; color: Theme.blue }

    // backup
    KitText { visible: root.kind === "backup"; text: "BKP"; color: Theme.foreground1; font.letterSpacing: 1 }
    Rectangle {
      visible: root.kind === "backup"
      anchors.verticalCenter: parent.verticalCenter
      width: 70; height: 4; radius: 2
      color: Theme.background3
      Rectangle { width: parent.width * 0.46; height: parent.height; radius: 2; color: Theme.green }
    }
    KitText { visible: root.kind === "backup"; text: "1.2 GB"; color: Theme.foreground2 }

    // music
    Rectangle {
      visible: root.kind === "music"
      anchors.verticalCenter: parent.verticalCenter
      width: 24; height: 24; radius: 12
      color: Theme.background3
      KitIcon { anchors.centerIn: parent; name: "music"; size: 12; tint: Theme.foreground2 }
    }
    KitText { visible: root.kind === "music"; text: "Eye of the Tiger"; color: Theme.foreground1 }
    KitText { visible: root.kind === "music"; text: "· Survivor"; color: Theme.muted }
    Row {
      visible: root.kind === "music"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      Repeater {
        model: [0.45, 1, 0.65, 0.85]
        Rectangle { required property real modelData; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 14 * modelData; radius: 1; color: Theme.green }
      }
    }
  }
}
