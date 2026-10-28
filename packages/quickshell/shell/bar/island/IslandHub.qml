import QtQuick
import Quickshell
import qs.bar
import qs.bar.island.hub
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
  readonly property var allIds: BarLayout.islandIn("hub", bar.screen?.name ?? "")
  // the hub row: modules that can be a tile are drawn as tiles, the rest stay chips
  readonly property var tileIds: allIds.filter(id => BarLayout.isTile(id))
  readonly property var ids: allIds.filter(id => !BarLayout.isTile(id))

  readonly property real preferredWidth: ModuleSettings.get("hub", "width", 400)
  // the player card is also the way into the Music popup, so it shows with nothing playing too
  readonly property bool hasPlayer: ShellSettings.hubPlayer
  readonly property string userName: Quickshell.env("USER") || "User"
  readonly property string avatarPath: ModuleSettings.get("hub", "avatar", "")
  function uptime(seconds) {
    if (seconds <= 0) return "Uptime —";
    const days = Math.floor(seconds / 86400), hours = Math.floor(seconds % 86400 / 3600), minutes = Math.floor(seconds % 3600 / 60);
    return "Up " + (days ? days + "d " : "") + (hours || days ? hours + "h " : "") + minutes + "m";
  }
  property date now: new Date()

  // a block is there when it has something to show
  function wants(id) {
    return id === "tiles" ? tileIds.length > 0 : id === "player" ? hasPlayer : id === "night" ? !ModuleSettings.get("hub", "nightAuto", true) || BrightnessService.nightActive
         : id === "modules" ? ids.length > 0 : true;
  }
  function blockOf(id) {
    return ({ tiles: tilesBlock, week: weekBlock, player: playerBlock, volume: volumeBlock, microphone: microphoneBlock, brightness: brightnessBlock, night: nightBlock, dimming: dimmingBlock, modules: modulesBlock })[id] ?? null;
  }

  // the month is a page of the hub: the island grows to it and back
  property bool calendarOpen: false
  onVisibleChanged: if (!visible) calendarOpen = false
  implicitHeight: (calendarOpen ? calendarPage.implicitHeight : column.implicitHeight) + 2 * Theme.gapGroup

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

  HubCalendar {
    id: calendarPage
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapGroup }
    visible: root.calendarOpen
    now: root.now
    onBack: root.calendarOpen = false
  }

  Column {
    id: column
    visible: !root.calendarOpen
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

    // ---- the blocks, in the order and the visibility of Bar › Hub ----
    Repeater {
      model: HubBlocks.order

      Loader {
        required property string modelData
        width: parent.width
        active: HubBlocks.shown(modelData) && root.wants(modelData)
        visible: active
        sourceComponent: root.blockOf(modelData)
      }
    }
  }

  // the calendar: the week strip (a click opens the month as a page), or the month itself
  Component {
    id: weekBlock
    Loader {
      sourceComponent: ModuleSettings.get("hub", "calendarMode", "week") === "month" ? monthInline : weekStrip
    }
  }
  Component {
    id: weekStrip
    HubWeek {
      width: parent.width
      now: root.now
      onClicked: root.calendarOpen = true
    }
  }
  Component {
    id: monthInline
    HubCalendar {
      width: parent.width
      now: root.now
      embedded: true
    }
  }

  Component {
    id: tilesBlock
      HubTiles {
        width: parent.width
        ids: root.tileIds
        modules: root.modules
      }
  }

  Component {
    id: playerBlock
      Rectangle {
        id: track
        readonly property bool compact: ModuleSettings.get("hub", "playerSize", "card") === "compact"
        width: parent.width
        height: compact ? 44 : 60
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
            visible: IslandService.hasMedia && !track.compact
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
            visible: !track.compact
            icon: "skip-back"
            iconSize: 14
            onClicked: IslandService.prev()
          }
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: track.compact ? 30 : 40
            height: width
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
            visible: !track.compact
            icon: "skip-forward"
            iconSize: 14
            onClicked: IslandService.next()
          }
        }
      }
  }

  // the quick sliders: each a block of its own
  Component {
    id: volumeBlock
    AudioVolumeRow {
      node: AudioService.sink
      accessibleName: "Output volume"
    }
  }
  Component {
    id: microphoneBlock
    AudioVolumeRow {
      node: AudioService.source
      iconOn: "mic"; iconOff: "mic-off"
      accessibleName: "Microphone volume"
    }
  }
  Component {
    id: brightnessBlock
    KitSliderRow {
      enabled: BrightnessService.available
      icon: BrightnessService.nightActive ? "moon" : "sun"
      iconTint: BrightnessService.nightActive ? Theme.orange : Theme.foreground0
      clickable: true
      onIconClicked: BrightnessService.setNight(!BrightnessService.nightActive)
      accessibleName: "Brightness"
      value: BrightnessService.brightness / 100
      text: BrightnessService.available ? BrightnessService.brightness + "%" : "—"
      onMoved: value => BrightnessService.setBrightness(value * 100)
    }
  }
  Component {
    id: nightBlock
    KitSliderRow {
      icon: "thermometer"
      iconTint: Theme.orange
      accessibleName: "Night light warmth"
      value: (BrightnessService.temperature - BrightnessService.temperatureMin) / (BrightnessService.temperatureMax - BrightnessService.temperatureMin)
      text: BrightnessService.temperature + " K"
      onMoved: value => BrightnessService.setTemperature(BrightnessService.temperatureMin + value * (BrightnessService.temperatureMax - BrightnessService.temperatureMin))
    }
  }
  Component {
    id: dimmingBlock
    KitSliderRow {
      icon: "moon"
      accessibleName: "Screen dimming"
      value: (BrightnessService.gamma - BrightnessService.gammaMin) / (100 - BrightnessService.gammaMin)
      text: BrightnessService.gamma + "%"
      onMoved: value => BrightnessService.setGamma(BrightnessService.gammaMin + value * (100 - BrightnessService.gammaMin))
    }
  }

  Component {
    id: modulesBlock
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
