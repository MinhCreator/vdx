import QtQuick
import qs.config
import qs.kit

// A sample of one live activity as the island shows it: the island's surface,
// frame and corners in the current theme, a fixed size so a list of them lines
// up (Bar › Live). Sample data.
Rectangle {
  id: root

  property string kind: ""

  implicitWidth: 190
  implicitHeight: 36
  radius: Math.min(Theme.barRadiusFor(height), Theme.islandRadius)
  color: Theme.background0
  border.width: Theme.islandFrameWidth
  border.color: Theme.background2
  clip: true

  function wave(c) { return [0.3, 0.7, 0.45, 1, 0.55, 0.8, 0.35]; }

  Row {
    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 14 }
    spacing: 8

    // messages
    Rectangle { visible: root.kind === "notice"; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.blue }
    KitText { visible: root.kind === "notice"; text: "Nikita: скину"; font.pixelSize: Theme.fontSize - 1 }

    // low battery
    Rectangle { visible: root.kind === "battery"; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.red }
    KitText { visible: root.kind === "battery"; text: "9% · 14m"; font.pixelSize: Theme.fontSize - 1 }

    // a device connected
    Rectangle { visible: root.kind === "bluetooth"; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.green }
    KitText { visible: root.kind === "bluetooth"; text: "AirPods 80"; font.pixelSize: Theme.fontSize - 1 }

    // recording
    Rectangle { visible: root.kind === "recording"; anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: Theme.red }
    KitText { visible: root.kind === "recording"; text: "00:03"; font.pixelSize: Theme.fontSize - 1 }
    Row {
      visible: root.kind === "recording"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      Repeater { model: root.wave(); Rectangle { required property real modelData; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 14 * modelData; radius: 1; color: Theme.red } }
    }

    // updates
    KitIcon { visible: root.kind === "update"; name: "download"; size: 12; tint: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
    Rectangle {
      visible: root.kind === "update"
      anchors.verticalCenter: parent.verticalCenter
      width: 60; height: 3; radius: 2; color: Theme.background3
      Rectangle { width: parent.width * 0.47; height: parent.height; radius: 2; color: Theme.blue }
    }
    KitText { visible: root.kind === "update"; text: "47%"; color: Theme.blue; font.pixelSize: Theme.fontSize - 1 }

    // backup
    KitText { visible: root.kind === "backup"; text: "BKP"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
    Rectangle {
      visible: root.kind === "backup"
      anchors.verticalCenter: parent.verticalCenter
      width: 70; height: 3; radius: 2; color: Theme.background3
      Rectangle { width: parent.width * 0.46; height: parent.height; radius: 2; color: Theme.green }
    }
    KitText { visible: root.kind === "backup"; text: "1.2G"; color: Theme.foreground2; font.pixelSize: Theme.fontSize - 1 }

    // vpn
    KitText { visible: root.kind === "vpn"; text: "VPN"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
    KitText { visible: root.kind === "vpn"; text: "Finland"; font.pixelSize: Theme.fontSize - 1; width: 64 }
    KitText { visible: root.kind === "vpn"; text: "483"; color: Theme.foreground2; font.pixelSize: Theme.fontSize - 1 }

    // music, and a new track: the cover, the name, the sound
    Rectangle { visible: root.kind === "music" || root.kind === "track"; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: Theme.pill(width); color: Theme.background3
      KitIcon { anchors.centerIn: parent; name: "music"; size: 9; tint: Theme.foreground2 } }
    KitText { visible: root.kind === "music" || root.kind === "track"; text: "Survivor"; font.pixelSize: Theme.fontSize - 1; width: 64; elide: Text.ElideRight }
    Row {
      visible: root.kind === "music" || root.kind === "track"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 2
      Repeater { model: [0.45, 1, 0.65, 0.85]; Rectangle { required property real modelData; anchors.verticalCenter: parent.verticalCenter; width: 2; height: 14 * modelData; radius: 1; color: Theme.green } }
    }

    // volume and brightness
    KitText { visible: root.kind === "volume"; text: "VOL"; font.pixelSize: Theme.fontSize - 3; font.letterSpacing: 1 }
    Row {
      visible: root.kind === "volume"
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3
      Repeater { model: 14; Rectangle { required property int index; width: 2; height: 14; radius: 1; color: index < 9 ? Theme.foreground1 : Theme.background3 } }
    }
    KitText { visible: root.kind === "volume"; text: "62"; font.pixelSize: Theme.fontSize - 1 }

    // microphone
    KitIcon { visible: root.kind === "mic"; name: "mic-off"; size: 13; tint: Theme.red; anchors.verticalCenter: parent.verticalCenter }
    KitText { visible: root.kind === "mic"; text: "Muted"; font.pixelSize: Theme.fontSize - 1 }

    // keyboard layout
    KitText { visible: root.kind === "layout"; text: "EN"; color: Theme.muted; font.pixelSize: Theme.fontSize - 1 }
    KitText { visible: root.kind === "layout"; text: "→"; color: Theme.dim; font.pixelSize: Theme.fontSize - 1 }
    KitText { visible: root.kind === "layout"; text: "RU"; font.pixelSize: Theme.fontSize - 1; font.weight: Font.Medium }

    // the cable
    KitIcon { visible: root.kind === "plugged"; name: "zap"; size: 12; tint: Theme.purple; anchors.verticalCenter: parent.verticalCenter }
    Rectangle {
      visible: root.kind === "plugged"
      anchors.verticalCenter: parent.verticalCenter
      width: 70; height: 3; radius: 2; color: Theme.background3
      Rectangle { width: parent.width * 0.52; height: parent.height; radius: 2; color: Theme.purple }
    }
    KitText { visible: root.kind === "plugged"; text: "52"; color: Theme.purple; font.pixelSize: Theme.fontSize - 1 }
  }
}
