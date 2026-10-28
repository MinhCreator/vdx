import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit
import Quickshell.Widgets
import qs.modules.sysmon
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
  // the player card is also the way into the Music popup, so it shows with nothing playing too
  readonly property bool hasPlayer: ShellSettings.hubPlayer
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

  // the Music module is on no bar; it lives here for its popup (the player card opens it)
  Loader {
    id: musicHost
    visible: false
    sourceComponent: root.modules["music"] ?? null
  }

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
      id: track
      width: parent.width
      height: 60
      visible: root.hasPlayer
      radius: Theme.radiusCard
      color: Theme.controlFill
      border.width: Theme.frameWidth
      border.color: Theme.controlLine

      function clock(s) { s = Math.max(0, Math.round(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

      // a click on the card (not its buttons) opens the Music popup, as the module's did
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: musicHost.item?.openPopup()
      }

      IslandCover {
        id: cover
        anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
        size: track.height - 2 * Theme.gapMedium
        radius: Theme.radiusFor(size * 1.4)
      }

      Column {
        anchors { left: cover.right; leftMargin: Theme.gapWide; right: controls.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight

        KitText {
          width: parent.width
          text: IslandService.title || "Nothing playing"
          textFormat: Text.PlainText
          font.weight: Font.Bold
          elide: Text.ElideRight
        }
        KitText {
          width: parent.width
          visible: IslandService.hasMedia
          text: (IslandService.artist !== "" ? IslandService.artist + " · " : "") + track.clock(IslandService.position) + " / " + track.clock(IslandService.length)
          textFormat: Text.PlainText
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
          elide: Text.ElideRight
        }
      }

      // back, the one filled button, forward
      Row {
        id: controls
        anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapSmall

        IslandButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "skip-back"
          iconSize: 14
          onClicked: IslandService.prev()
        }
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 40
          height: 40
          radius: Theme.pill(height)
          color: playArea.containsMouse ? Theme.foreground0 : Theme.foreground1

          KitIcon { anchors.centerIn: parent; name: IslandService.playing ? "pause" : "play"; size: 16; solid: true; tint: Theme.background0 }
          MouseArea {
            id: playArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: IslandService.togglePlay()
          }
        }
        IslandButton {
          anchors.verticalCenter: parent.verticalCenter
          icon: "skip-forward"
          iconSize: 14
          onClicked: IslandService.next()
        }
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
