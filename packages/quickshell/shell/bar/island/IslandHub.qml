import QtQuick
import Quickshell
import qs.bar
import qs.bar.island.hub
import qs.config
import qs.kit
import Quickshell.Widgets
import qs.modules.sysmon
import qs.modules.equalizer
import qs.modules.audio
import qs.modules.brightness

// The hub: profile and uptime, media, quick sliders and module chips.
// A chip is the module's own face: its click opens the module's popup in the
// island, a right click its options.
Item {
  id: root

  required property PanelWindow bar
  property var modules: ({})

  signal power()
  signal manager()                          // the gear: Shell Manager
  signal settings(string id)

  // Shell Manager › Bar › HUB (island style)
  readonly property var ids: BarLayout.islandIn("hub", bar.screen?.name ?? "")

  readonly property int panelPad: 22           // the board's panel padding
  readonly property real preferredWidth: ModuleSettings.get("hub", "width", 440)
  function quickSlider(key) { return ModuleSettings.get("hub", key, key === "volume" || key === "brightness"); }
  readonly property bool hasPlayer: IslandService.hasMedia && ShellSettings.hubPlayer
  readonly property bool hasSliders: ["volume", "microphone", "brightness", "dimming"].some(k => quickSlider(k))
  readonly property string userName: Quickshell.env("USER") || "User"
  readonly property string avatarPath: ModuleSettings.get("hub", "avatar", "")
  function uptime(seconds) {
    if (seconds <= 0) return "Uptime —";
    const days = Math.floor(seconds / 86400), hours = Math.floor(seconds % 86400 / 3600), minutes = Math.floor(seconds % 3600 / 60);
    return "Up " + (days ? days + "d " : "") + (hours || days ? hours + "h " : "") + minutes + "m";
  }
  property date now: new Date()

  implicitHeight: column.implicitHeight + 2 * panelPad

  Timer {
    interval: 30000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.panelPad }
    spacing: 14

    // ---- header ----
    HubHeader {
      width: parent.width
      now: root.now
      onManager: root.manager()
      onPower: root.power()
    }

    // ---- the week ----
    HubWeek {
      width: parent.width
      now: root.now
    }

    // ---- tiles ----
    HubTiles {
      width: parent.width
      onOpen: module => ShellIpc.call(module, "toggle")
    }

    // ---- sliders ----
    Column {
      width: parent.width
      spacing: 8
      visible: root.hasSliders

      HubSlider {
        width: parent.width
        visible: root.quickSlider("volume")
        icon: AudioService.muted || AudioService.volume === 0 ? "volume-x" : "volume"
        label: "Sound"
        value: Math.min(1, AudioService.volume / 100)
        text: AudioService.volume + "%"
        onMoved: v => { if (AudioService.sink?.audio) AudioService.sink.audio.volume = v; }
      }
      HubSlider {
        width: parent.width
        visible: root.quickSlider("microphone")
        icon: "mic"
        label: "Microphone"
        value: Math.min(1, AudioService.source?.audio?.volume ?? 0)
        text: Math.round((AudioService.source?.audio?.volume ?? 0) * 100) + "%"
        onMoved: v => { if (AudioService.source?.audio) AudioService.source.audio.volume = v; }
      }
      HubSlider {
        width: parent.width
        visible: root.quickSlider("brightness")
        enabled: BrightnessService.available
        icon: "sun"
        label: "Brightness"
        value: BrightnessService.brightness / 100
        text: BrightnessService.available ? BrightnessService.brightness + "%" : "—"
        onMoved: v => BrightnessService.setBrightness(v * 100)
      }
      HubSlider {
        width: parent.width
        visible: root.quickSlider("dimming")
        icon: "moon"
        label: "Dimming"
        value: (BrightnessService.gamma - BrightnessService.gammaMin) / (100 - BrightnessService.gammaMin)
        text: BrightnessService.gamma + "%"
        onMoved: v => BrightnessService.setGamma(BrightnessService.gammaMin + v * (100 - BrightnessService.gammaMin))
      }
    }

    // ---- track ----
    HubMusic {
      width: parent.width
      visible: root.hasPlayer
    }

    // ---- notifications ----
    HubNotes { width: parent.width }

    KitLine { visible: root.ids.length > 0 && (root.hasPlayer || root.hasSliders) }

    // ---- modules ----
    Flow {
      width: parent.width
      spacing: Theme.gapSmall

      Repeater {
        model: root.ids

        Rectangle {
          id: chip
          required property string modelData

          width: slot.width + 2 * Theme.gapWide
          height: 32
          radius: Theme.radiusCard
          color: hover.hovered ? Theme.controlHover : Theme.controlFill
          border.width: Theme.frameWidth
          border.color: hover.hovered ? Theme.controlLineHover : Theme.controlLine
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          HoverHandler { id: hover }

          Loader {
            id: slot
            anchors.centerIn: parent
            sourceComponent: root.modules[chip.modelData] ?? null
          }

          TapHandler {
            acceptedButtons: Qt.RightButton
            enabled: ShellSettings.barRightSettings
            onTapped: root.settings(chip.modelData)
          }
        }
      }
    }
  }
}
