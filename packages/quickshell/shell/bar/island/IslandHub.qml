import QtQuick
import Quickshell
import qs.bar
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

  readonly property real preferredWidth: ModuleSettings.get("hub", "width", 400)
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

  implicitHeight: column.implicitHeight + 2 * Theme.gapGroup

  Timer {
    interval: 30000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Column {
    id: column
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapGroup }
    spacing: Theme.sectionGap

    // ---- header ----
    Item {
      width: parent.width
      height: 38
      ClippingRectangle {
        id: avatar
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 34; height: 34
        radius: Theme.radiusFor(height)
        color: Theme.pickFill
        Image {
          id: avatarImage
          anchors.fill: parent
          source: root.avatarPath ? "file://" + root.avatarPath : ""
          fillMode: Image.PreserveAspectCrop
          sourceSize: Qt.size(68, 68)
          visible: status === Image.Ready
        }
        KitText {
          anchors.centerIn: parent
          visible: !avatarImage.visible
          text: root.userName.slice(0, 1).toUpperCase()
          font.weight: Font.Medium
        }
      }
      Column {
        anchors { left: avatar.right; leftMargin: Theme.gapMedium; right: settingsButton.left; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight
        KitText { width: parent.width; text: root.userName; font.weight: Font.Medium; elide: Text.ElideRight }
        KitText {
          width: parent.width
          text: root.uptime(SysmonService.uptime) + " · " + Qt.formatDateTime(root.now, "d MMM")
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
          elide: Text.ElideRight
        }
      }

      IslandButton {
        id: settingsButton
        anchors { right: powerButton.left; rightMargin: Theme.gapSmall }
        icon: "settings"
        iconSize: 16
        onClicked: root.manager()
      }

      IslandButton {
        id: powerButton
        anchors.right: parent.right
        icon: "power"
        iconSize: 16
        onClicked: root.power()
      }
    }

    KitLine { visible: root.hasPlayer || root.hasSliders || root.ids.length > 0 }

    // ---- track ----
    Rectangle {
      width: parent.width
      height: 52
      visible: root.hasPlayer
      radius: Theme.radiusCard
      color: Theme.controlFill
      border.width: Theme.frameWidth
      border.color: Theme.controlLine

      IslandCover {
        id: cover
        anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
        size: 36
        radius: Theme.radiusControl
      }

      Column {
        anchors { left: cover.right; leftMargin: Theme.gapLoose; right: controls.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }

        KitText {
          width: parent.width
          text: IslandService.title || "Nothing playing"
          textFormat: Text.PlainText
          font.weight: Font.Bold
          elide: Text.ElideRight
        }
        KitText {
          width: parent.width
          visible: text !== ""
          text: IslandService.artist
          textFormat: Text.PlainText
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
          elide: Text.ElideRight
        }
      }

      // one hover disc for the group: it slides to the button under the
      // pointer, so two discs never show at once
      // it jumps to the button it moves to and fades in or out on the group
      // leaving: the last button stays put while it fades
      Rectangle {
        id: disc
        readonly property Item target: controls.hoverTarget
        property Item last: null
        onTargetChanged: if (target) last = target
        x: last ? controls.x + last.x : 0
        y: last ? controls.y + last.y : 0
        width: last ? last.width : 0
        height: last ? last.height : 0
        radius: Theme.pill(height)
        color: Theme.background2
        opacity: target ? 1 : 0

        Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
      }

      Row {
        id: controls
        anchors { right: parent.right; rightMargin: Theme.gapHair; verticalCenter: parent.verticalCenter }
        property Item hoverTarget: null

        EqualizerBars {
          anchors.verticalCenter: parent.verticalCenter
          height: 14
          rightPadding: Theme.gapMedium
        }
        IslandButton { group: controls; icon: "skip-back"; iconSize: 16; onClicked: IslandService.prev() }
        IslandButton { group: controls; icon: IslandService.playing ? "pause" : "play"; iconSize: 18; onClicked: IslandService.togglePlay() }
        IslandButton { group: controls; icon: "skip-forward"; iconSize: 16; onClicked: IslandService.next() }
      }
    }

    KitLine { visible: root.hasPlayer && root.hasSliders }

    // ---- optional quick sliders, independent of the bar's module placement ----
    Column {
      width: parent.width
      spacing: Theme.gapSmall
      visible: root.hasSliders

      AudioVolumeRow {
        visible: root.quickSlider("volume")
        node: AudioService.sink
        accessibleName: "Output volume"
      }
      AudioVolumeRow {
        visible: root.quickSlider("microphone")
        node: AudioService.source
        iconOn: "mic"; iconOff: "mic-off"
        accessibleName: "Microphone volume"
      }
      KitSliderRow {
        visible: root.quickSlider("brightness")
        enabled: BrightnessService.available
        icon: "sun"
        accessibleName: "Brightness"
        value: BrightnessService.brightness / 100
        text: BrightnessService.available ? BrightnessService.brightness + "%" : "—"
        onMoved: value => BrightnessService.setBrightness(value * 100)
      }
      KitSliderRow {
        visible: root.quickSlider("dimming")
        icon: "moon"
        accessibleName: "Screen dimming"
        value: (BrightnessService.gamma - BrightnessService.gammaMin) / (100 - BrightnessService.gammaMin)
        text: BrightnessService.gamma + "%"
        onMoved: value => BrightnessService.setGamma(BrightnessService.gammaMin + value * (100 - BrightnessService.gammaMin))
      }
    }

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
