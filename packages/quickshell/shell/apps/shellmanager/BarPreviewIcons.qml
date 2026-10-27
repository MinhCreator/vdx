import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit
import qs.modules.audio
import qs.modules.battery
import qs.modules.brightness
import qs.modules.language
import qs.modules.music
import qs.modules.player

// Representative faces only: previewing never activates system controls.
Row {
  id: root
  property var ids: []
  property int more: 0
  property bool detailed: false
  spacing: detailed ? Theme.gapSmall : Theme.gapLoose

  SystemClock { id: tick; precision: SystemClock.Minutes }

  // the faces' own text, from the same services as the bar's
  function sample(id) {
    if (!detailed) return "";
    const live = ({
      clock: Qt.formatTime(tick.date, "HH:mm"),
      music: PlayerService.playing && PlayerService.title !== "" ? PlayerService.title : "Music",
      battery: String(BatteryService.capacity),
      language: Format.layout(LanguageService.layout) || LanguageService.layout,
      audio: AudioService.muted || !AudioService.sink ? "--" : String(Math.min(AudioService.maxPercent, AudioService.volume)),
      brightness: BrightnessService.available ? String(BrightnessService.brightness) : "--"
    })[id];
    if (live === undefined) return "";
    const text = BarLayout.faceText(id, live);
    return text.length > 22 ? text.slice(0, 21) + "…" : text;
  }
  function faceWidth(id) {
    if (BarLayout.isSeparator(id)) return 2;
    if (detailed && id === "workspaces") return 72;
    if (detailed && id === "equalizer") return 36;
    const text = sample(id);
    return text ? (id === "clock" ? 62 : Theme.iconSmall + 22 + text.length * 8) : Theme.iconSmall + (detailed ? 16 : 0);
  }

  Repeater {
    model: root.ids
    Item {
      id: slot
      required property string modelData
      anchors.verticalCenter: parent.verticalCenter
      width: root.faceWidth(modelData)
      height: root.detailed ? 30 : 20
      readonly property bool workspaces: root.detailed && modelData === "workspaces"
      readonly property bool equalizer: root.detailed && modelData === "equalizer"

      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: Theme.background2
        visible: false   // modules of a real bar have no plate
      }
      KitLine {
        vertical: true
        visible: BarLayout.isSeparator(slot.modelData)
        anchors.centerIn: parent
        width: Theme.dividerThickness; height: Theme.iconSmall
      }
      Row {
        visible: slot.workspaces
        anchors.centerIn: parent
        spacing: 5
        Repeater {
          model: 3
          Rectangle {
            required property int index
            width: 16; height: 20
            radius: Theme.radiusControl
            color: index === 0 ? Theme.foreground0 : Theme.clear
            KitText {
              anchors.centerIn: parent
              text: parent.index + 1
              color: parent.index === 0 ? Theme.background0 : Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }
          }
        }
      }
      Row {
        visible: slot.equalizer
        anchors.centerIn: parent
        spacing: 2
        Repeater {
          model: [6, 13, 18, 10, 15, 7]
          Rectangle {
            required property int modelData
            anchors.verticalCenter: parent.verticalCenter
            width: 2; height: modelData
            radius: 1; color: Theme.foreground2
          }
        }
      }
      Row {
        visible: !slot.workspaces && !slot.equalizer && !BarLayout.isSeparator(slot.modelData)
        anchors.centerIn: parent
        spacing: 6
        KitIcon {
          visible: !(root.detailed && slot.modelData === "clock")
          anchors.verticalCenter: parent.verticalCenter
          name: BarLayout.icon(slot.modelData)
          tint: Theme.foreground2
          size: Theme.iconSmall
        }
        KitText {
          visible: text !== ""
          anchors.verticalCenter: parent.verticalCenter
          text: root.sample(slot.modelData)
          font.pixelSize: Theme.fontSize
          color: Theme.foreground0
        }
      }
    }
  }
  KitText {
    anchors.verticalCenter: parent.verticalCenter
    visible: root.more > 0
    text: "+" + root.more
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }
}
