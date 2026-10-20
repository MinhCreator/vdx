import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.kit

// The player: the source it shows (a choice when several run), the track with
// cover, timeline and controls, and the player's own shuffle, repeat and raise.
// Controls only where the player supports them.
KitFrame {
  id: root

  signal openWindow()

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  // ---- header ----
  KitHeader {
    icon: "play"
    iconColor: PlayerService.hasMedia ? Theme.foreground0 : Theme.muted
    title: "Player"
    subtitle: !PlayerService.hasMedia ? "NOTHING RUNNING"
      : PlayerService.name.toUpperCase() + " · " + (PlayerService.playing ? "PLAYING" : "PAUSED")

    // the Music window: the player large, the queue and the libraries
    KitButton {
      anchors.verticalCenter: parent.verticalCenter
      icon: "external"
      onClicked: {
        root.openWindow();
        Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "music", "open"]);
      }
    }
  }

  KitChoices {
    visible: PlayerService.sources.length > 1
    width: parent.width
    stretch: true
    model: PlayerService.sources.map(s => ({ label: s.name, value: s.key }))
    current: PlayerService.current?.key ?? ""
    onPicked: value => PlayerService.picked = value
  }

  KitLine {}

  KitText {
    visible: !PlayerService.hasMedia
    width: parent.width
    wrapMode: Text.WordWrap
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
    text: "No player is running. Start something in Spotify, a browser or mpv: it shows here."
  }

  // ---- now playing: the cover at left, the track and the controls at right ----
  Row {
    width: parent.width
    visible: PlayerService.hasMedia
    spacing: Theme.gapWide

    ClippingRectangle {
      id: cover
      radius: Theme.radiusCard
      width: 96
      height: width
      color: Theme.background1
      border.width: Theme.frameWidth
      border.color: Theme.background3

      Image {
        anchors { fill: parent; margins: 1 }
        source: PlayerService.cover
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize { width: 192; height: 192 }
      }

      KitIcon {
        anchors.centerIn: parent
        visible: PlayerService.cover === ""
        name: "music"
        tint: Theme.gray
        size: Theme.iconLarge
      }
    }

    Column {
      width: parent.width - cover.width - Theme.gapWide
      spacing: Theme.gapTight

      Item {
        width: parent.width
        height: titleCol.implicitHeight

        Column {
          id: titleCol
          anchors { left: parent.left; right: raise.left; rightMargin: Theme.gapMedium }
          spacing: Theme.gapHair

          KitText {
            width: parent.width
            text: PlayerService.title || "—"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.weight: Font.ExtraBold
          }

          KitText {
            width: parent.width
            visible: text !== ""
            text: PlayerService.artist
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.foreground2
            font.pixelSize: Theme.fontSize - 1
          }
        }

        KitButton {
          id: raise
          anchors { right: parent.right; top: parent.top }
          visible: PlayerService.canRaise
          icon: "external"
          onClicked: PlayerService.raise()
        }
      }

      // ---- timeline ----
      KitSlider {
        id: timeline
        width: parent.width
        enabled: PlayerService.canSeek
        value: PlayerService.length > 0 ? PlayerService.position / PlayerService.length : 0
        onReleased: value => PlayerService.seek(value)
      }

      Item {
        width: parent.width
        height: elapsed.implicitHeight

        KitText {
          id: elapsed
          text: root.clock(timeline.pressed ? timeline.dragValue * PlayerService.length : PlayerService.position)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        KitText {
          anchors.right: parent.right
          visible: PlayerService.length > 0
          text: root.clock(PlayerService.length)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }

      // ---- controls ----
      Item {
        width: parent.width
        height: 30

        KitButton {
          anchors.left: parent.left
          visible: PlayerService.canShuffle
          icon: "shuffle"
          selected: PlayerService.shuffleOn
          iconTint: PlayerService.shuffleOn ? Theme.foreground0 : Theme.gray
          onClicked: PlayerService.toggleShuffle()
        }

        Row {
          anchors.centerIn: parent
          spacing: Theme.gapMedium

          KitButton { icon: "skip-back"; disabled: !PlayerService.canPrevious; onClicked: PlayerService.prev() }

          KitButton {
            width: 52
            icon: PlayerService.playing ? "pause" : "play"
            selected: true
            onClicked: PlayerService.togglePlay()
          }

          KitButton { icon: "skip-forward"; disabled: !PlayerService.canNext; onClicked: PlayerService.next() }
        }

        KitButton {
          anchors.right: parent.right
          visible: PlayerService.canLoop
          icon: PlayerService.loop === "one" ? "repeat-1" : "repeat"
          selected: PlayerService.loop !== "off"
          iconTint: PlayerService.loop !== "off" ? Theme.foreground0 : Theme.gray
          onClicked: PlayerService.cycleLoop()
        }
      }
    }
  }
}
