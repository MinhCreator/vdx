import QtQuick
import QtQuick.Effects
import qs.apps.backup
import qs.apps.capture
import qs.config
import qs.kit
import qs.modules.battery
import qs.modules.bluetooth
import qs.modules.mihomo
import qs.modules.equalizer

// One face of the pill's live slot (IslandLive): what the activity `kind` shows.
Row {
  id: face

  property string kind: ""
  property int coverSize: 18
  property bool full: false                    // the whole activity, not just its mark

  anchors.verticalCenter: parent.verticalCenter
  spacing: 8
  visible: kind !== ""

  // recording
  Rectangle {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    width: 8
    height: 8
    radius: 4
    color: Theme.red
  }
  KitText {
    visible: face.kind === "recording" && face.full
    text: "Recording"
    color: Theme.foreground2
  }
  KitText {
    visible: face.kind === "recording"
    text: CaptureService.elapsedText
    color: Theme.foreground1
  }

  // update
  KitIcon { visible: face.kind === "update"; name: "download"; tint: Theme.blue; size: 14; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "update"; text: face.full ? "Updating packages" : "Updating"; color: Theme.blue }

  // backup: BKP and its progress
  KitText { visible: face.kind === "backup"; text: "BKP"; color: Theme.foreground1; font.letterSpacing: 1 }
  Rectangle {
    visible: face.kind === "backup"
    anchors.verticalCenter: parent.verticalCenter
    width: 70
    height: 4
    radius: 2
    color: Theme.background3
    Rectangle {
      width: parent.width * Math.max(0, BackupService.progress) / 100
      height: parent.height
      radius: 2
      color: Theme.green
    }
  }

  KitText {
    visible: face.kind === "backup" && face.full
    text: Math.max(0, Math.round(BackupService.progress)) + "%"
    color: Theme.foreground2
  }

  // low battery: the level in red, in full the time left
  KitIcon { visible: face.kind === "battery"; name: BatteryService.levelIcon; size: 16; tint: Theme.red; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "battery"; text: "Battery"; color: Theme.foreground1 }
  KitText { visible: face.kind === "battery"; text: BatteryService.capacity + "%"; color: Theme.red }
  KitText {
    visible: face.kind === "battery" && face.full && BatteryService.minutesLeft > 0
    text: "· " + (BatteryService.minutesLeft >= 60 ? Math.floor(BatteryService.minutesLeft / 60) + " h " : "") + BatteryService.minutesLeft % 60 + " min left"
    color: Theme.muted
  }

  // a device that connected: its name, in full the charge
  KitIcon { visible: face.kind === "bluetooth"; name: "bluetooth"; size: 16; tint: Theme.blue; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "bluetooth"; text: BluetoothService.mainDevice?.name ?? ""; color: Theme.foreground1 }
  KitText {
    visible: face.kind === "bluetooth" && BluetoothService.mainDevice?.battery != null
    text: BluetoothService.mainDevice?.battery + "%"
    color: Theme.blue
  }

  // vpn: the server and the ping
  KitText { visible: face.kind === "vpn"; text: "VPN"; color: Theme.foreground1; font.letterSpacing: 1 }
  KitText { visible: face.kind === "vpn"; text: MihomoService.current; color: Theme.foreground2; width: Math.min(implicitWidth, 110); elide: Text.ElideRight }
  KitText { visible: face.kind === "vpn" && MihomoService.currentDelay > 0; text: String(MihomoService.currentDelay); color: Theme.muted }

  // flashes: the mic, the layout, a new track, the cable
  KitIcon { visible: face.kind === "mic"; name: IslandService.micMuted ? "mic-off" : "mic"; size: 14; tint: IslandService.micMuted ? Theme.red : Theme.green; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "mic"; text: IslandService.micMuted ? "Muted" : "Mic on"; color: Theme.foreground1 }
  KitText { visible: face.kind === "layout"; text: Format.layout(IslandService.layoutFrom) || IslandService.layoutFrom; color: Theme.muted }
  KitText { visible: face.kind === "layout"; text: "→"; color: Theme.dim }
  KitText { visible: face.kind === "layout"; text: Format.layout(IslandService.layoutNow) || IslandService.layoutNow; color: Theme.foreground1; font.weight: Font.Medium }
  KitIcon { visible: face.kind === "plugged"; name: "zap"; size: 14; tint: Theme.purple; anchors.verticalCenter: parent.verticalCenter }
  Rectangle {
    visible: face.kind === "plugged"
    anchors.verticalCenter: parent.verticalCenter
    width: 70; height: 4; radius: 2
    color: Theme.background3
    Rectangle { width: parent.width * BatteryService.capacity / 100; height: parent.height; radius: 2; color: Theme.purple }
  }
  KitText { visible: face.kind === "plugged"; text: String(BatteryService.capacity); color: Theme.purple }

  // music: the cover, in full the track too, and the sound
  Item {
    visible: face.kind === "music" || face.kind === "track"
    anchors.verticalCenter: parent.verticalCenter
    width: face.coverSize
    height: face.coverSize

    Image {
      id: cover
      anchors.fill: parent
      visible: false
      source: IslandService.cover
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
    Item {
      id: round
      anchors.fill: parent
      visible: false
      layer.enabled: true
      Rectangle { anchors.fill: parent; radius: Theme.pill(width) }
    }
    // a circle: the cover's corners cut by the mask
    MultiEffect {
      anchors.fill: parent
      source: cover
      maskEnabled: true
      maskSource: round
    }
    Rectangle { anchors.fill: parent; radius: Theme.pill(width); color: Theme.background3; z: -1 }
  }
  KitText {
    visible: (face.kind === "music" || face.kind === "track") && face.full
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, 260)
    elide: Text.ElideRight
    text: IslandService.title + (IslandService.artist !== "" ? " · " + IslandService.artist : "")
    color: Theme.foreground1
  }
  EqualizerBars {
    visible: face.kind === "music" || face.kind === "track"
    anchors.verticalCenter: parent.verticalCenter
    barCount: 4
    tone: Theme.green
    height: 14
  }
}
