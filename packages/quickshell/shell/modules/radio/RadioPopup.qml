import QtQuick
import qs.config
import qs.kit
import qs.modules.mpd

// Radio: a dial of the stations, the one on air and what it plays. Tune by
// dragging the dial; the button pauses or starts it.
KitFrame {
  id: root

  readonly property var stations: RadioService.stations
  readonly property string key: RadioService.active ? RadioService.stationKey : RadioService.lastKey
  readonly property int index: Math.max(0, stations.findIndex(s => s.key === key))
  readonly property var station: stations[index] ?? null
  readonly property color tone: Theme.accentFor("modules", Theme.green)
  readonly property bool onAir: RadioService.active

  signal closeRequested()                      // Modules › Radio › Close after stop

  implicitWidth: 340

  // ---- header ----
  KitHeader {
    icon: "radio"
    iconColor: root.onAir ? root.tone : Theme.foreground0
    title: root.station?.name ?? "Radio"
    subtitle: !root.onAir ? "OFF" : (MpdService.playing ? "ON AIR" : "PAUSED") + (root.station?.genre ? " · " + root.station.genre.toUpperCase() : "")

    KitText {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.stations.length > 0
      text: String(Math.round(dial.tuning) + 1).padStart(2, "0")
      color: root.onAir ? root.tone : Theme.muted
      font.pixelSize: Theme.fontSize + 12
    }
  }

  KitLine {}

  KitText {
    visible: root.stations.length === 0
    width: parent.width
    text: "No stations"
    color: Theme.muted
  }

  RadioDial {
    id: dial
    visible: root.stations.length > 0
    width: parent.width
    count: root.stations.length
    current: root.index
    tint: root.tone
    onTuned: index => RadioService.play(root.stations[index].key)
  }

  // ---- what plays ----
  Row {
    visible: root.stations.length > 0
    width: parent.width
    spacing: Theme.gapMedium

    KitText {
      id: track
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - button.width - (root.onAir ? button.width + parent.spacing : 0) - parent.spacing
      elide: Text.ElideRight
      textFormat: Text.PlainText
      text: !root.onAir ? (root.station?.about ?? "") : (MpdService.player.title || root.station?.about || "")
      color: Theme.muted
    }
    KitButton {
      visible: root.onAir
      icon: "square"
      onClicked: {
        MpdService.stop();
        if (ModuleSettings.get("tuner", "closeAfterStop", false)) root.closeRequested();
      }
    }
    KitButton {
      id: button
      icon: root.onAir && MpdService.playing ? "pause" : "play"
      iconTint: root.tone
      onClicked: root.onAir ? MpdService.toggle() : RadioService.setActive(true)
    }
  }
}
