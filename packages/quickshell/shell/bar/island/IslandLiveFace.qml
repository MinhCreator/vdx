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
  property int coverSize: 18                   // a badge (cover, avatar): the chip's height less its inset on both sides
  property int badgeRadius: 4                  // concentric with the chip
  // an activity that starts with a badge sits it the same inset from the chip's left, top and bottom
  readonly property bool badged: kind === "music" || kind === "notice"

  anchors.verticalCenter: parent.verticalCenter
  spacing: 8
  visible: kind !== ""

  // recording: the dot, the time, the sound, the file's size, pause and stop
  Rectangle {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    width: 8
    height: 8
    radius: 4
    color: Theme.red
    opacity: CaptureService.paused ? 0.4 : 1
  }
  KitText {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    text: CaptureService.elapsedText
    color: Theme.foreground1
    font.weight: Font.Medium
  }
  EqualizerBars {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    barCount: 7
    tone: Theme.red
    height: 16
    active: !CaptureService.paused
  }
  KitText {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    text: CaptureService.sizeText
    color: Theme.muted
  }
  // round buttons, the chip's height less its inset: pause (dim) and stop (red)
  Repeater {
    model: face.kind === "recording" ? [{ stop: false }, { stop: true }] : []
    Rectangle {
      id: btn
      required property var modelData
      readonly property bool stop: modelData.stop
      anchors.verticalCenter: parent.verticalCenter
      width: face.coverSize
      height: face.coverSize
      radius: Theme.pill(height)
      color: stop ? Theme.red : Theme.background3
      opacity: area.containsMouse ? 0.85 : 1
      Accessible.role: Accessible.Button
      Accessible.name: stop ? "Stop recording" : CaptureService.paused ? "Resume recording" : "Pause recording"

      KitIcon {
        anchors.centerIn: parent
        name: btn.stop ? "square" : CaptureService.paused ? "play" : "pause"
        size: 12
        tint: btn.stop ? Theme.background0 : Theme.foreground1
      }
      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.stop ? CaptureService.stopRecording() : CaptureService.togglePause()
      }
    }
  }

  // update
  KitIcon { visible: face.kind === "update"; name: "download"; tint: Theme.blue; size: 14; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "update"; text: "Updating packages"; color: Theme.blue }

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
    visible: face.kind === "backup"
    text: Math.max(0, Math.round(BackupService.progress)) + "%"
    color: Theme.foreground2
  }

  // a notification, as a line: the app's initial, "app: summary"
  Rectangle {
    visible: face.kind === "notice"
    anchors.verticalCenter: parent.verticalCenter
    width: face.coverSize
    height: face.coverSize
    radius: face.badgeRadius
    readonly property color tone: IslandService.noticeItem?.urgency === "critical" ? Theme.red : Theme.appColour(IslandService.noticeItem?.app)
    color: Theme.mix(Theme.background0, tone, 0.22)
    KitText { anchors.centerIn: parent; text: (IslandService.noticeItem?.app ?? "").slice(0, 1).toUpperCase(); color: parent.tone; font.pixelSize: Theme.fontSize - 2; font.weight: Font.Medium }
  }
  KitText {
    visible: face.kind === "notice"
    width: Math.min(implicitWidth, 300)
    elide: Text.ElideRight
    textFormat: Text.PlainText
    text: {
      const n = IslandService.noticeItem;
      if (!n) return "";
      const head = n.summary !== "" ? n.summary : n.app;
      return n.body !== "" ? head + ": " + n.body : head;
    }
    color: IslandService.noticeItem?.urgency === "critical" ? Theme.red : Theme.foreground1
  }

  // low battery: the level in red, the time left
  KitIcon { visible: face.kind === "battery"; name: BatteryService.levelIcon; size: 16; tint: Theme.red; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "battery"; text: "Battery"; color: Theme.foreground1 }
  KitText { visible: face.kind === "battery"; text: BatteryService.capacity + "%"; color: Theme.red }
  KitText {
    visible: face.kind === "battery" && BatteryService.minutesLeft > 0
    text: "· " + (BatteryService.minutesLeft >= 60 ? Math.floor(BatteryService.minutesLeft / 60) + " h " : "") + BatteryService.minutesLeft % 60 + " min left"
    color: Theme.muted
  }

  // a device that connected: its name, the charge
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

  // volume and brightness: the level as a ruler while it changes
  KitIcon { visible: face.kind === "volume"; name: IslandService.osdIcon; size: 14; tint: IslandService.osdMuted ? Theme.red : Theme.foreground2; anchors.verticalCenter: parent.verticalCenter }
  Row {
    visible: face.kind === "volume"
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3
    Repeater {
      model: 14
      Rectangle {
        required property int index
        width: 2; height: 14; radius: 1
        color: index < Math.round(Math.min(1, IslandService.osdLevel) * 14) ? Theme.foreground1 : Theme.background3
      }
    }
  }
  KitText { visible: face.kind === "volume"; text: Math.round(IslandService.osdLevel * 100); color: Theme.foreground1 }

  // flashes: the mic, the layout, the cable
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

  // music: the cover, the track and the sound
  Item {
    visible: face.kind === "music"
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
      Rectangle { anchors.fill: parent; radius: face.badgeRadius }
    }
    // a circle: the cover's corners cut by the mask
    MultiEffect {
      anchors.fill: parent
      source: cover
      maskEnabled: true
      maskSource: round
    }
    Rectangle { anchors.fill: parent; radius: face.badgeRadius; color: Theme.background3; z: -1 }
  }
  KitText {
    visible: face.kind === "music"
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, 260)
    elide: Text.ElideRight
    text: IslandService.title + (IslandService.artist !== "" ? " · " + IslandService.artist : "")
    color: Theme.foreground1
  }
  EqualizerBars {
    visible: face.kind === "music"
    anchors.verticalCenter: parent.verticalCenter
    barCount: 4
    tone: Theme.green
    height: 14
  }
}
