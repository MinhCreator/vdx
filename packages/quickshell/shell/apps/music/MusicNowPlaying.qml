import QtQuick
import Quickshell.Widgets
import qs.config
import qs.kit
import qs.modules.mpd
import qs.modules.player
import qs.modules.yandex

// Now playing: the cover large, the player to show (a choice when several run), the
// track, its like, the timeline and the transport; MPD's queue beside it while the
// Yandex likes play (UP NEXT). Nothing running: what can start (the likes, the radio).
Item {
  id: root

  property bool yandexOn: false
  property bool radioOn: false

  readonly property bool queueShown: yandexOn && PlayerService.mpd && MpdService.source === "likes"
  readonly property bool yandexTrack: queueShown && YandexService.trackId !== ""
  readonly property int leftW: queueShown ? Math.min(340, Math.round(width * 0.42)) : Math.min(380, width)
  readonly property bool showRemaining: ModuleSettings.get("music", "showRemaining", false)
  readonly property real at: timeline.pressed ? timeline.dragValue * PlayerService.length : PlayerService.position

  signal goTo(string page)
  signal queueMenu(var entry, int index, var anchor)

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  // ---- nothing running ----
  Column {
    anchors.centerIn: parent
    visible: !PlayerService.hasMedia
    width: Math.min(parent.width, 360)
    spacing: Theme.gapWide

    KitIcon {
      anchors.horizontalCenter: parent.horizontalCenter
      name: "headphones"
      size: 48
      tint: Theme.gray
    }

    KitText {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: "Nothing is playing"
      font.pixelSize: Theme.fontSize + 2
      font.weight: Font.ExtraBold
    }

    KitText {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      text: "Start something in any player (Spotify, a browser, mpv): it shows here"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Theme.gapMedium
      visible: root.yandexOn || root.radioOn

      KitButton {
        visible: root.yandexOn
        icon: "heart"
        text: "Play likes"
        busy: MpdService.busy === "likes"
        onClicked: YandexService.setActive(true)
      }
      KitButton {
        visible: root.radioOn
        icon: "radio"
        text: "Radio"
        onClicked: root.goTo("radio")
      }
    }
  }

  // ---- the player ----
  Column {
    id: player
    visible: PlayerService.hasMedia
    x: root.queueShown ? 0 : Math.round((root.width - width) / 2)
    width: root.leftW
    spacing: Theme.gapWide

    ClippingRectangle {
      id: cover
      width: Math.min(parent.width, root.height - details.height - parent.spacing)
      height: width
      anchors.horizontalCenter: parent.horizontalCenter
      radius: Theme.radiusCard
      color: Theme.background1

      Image {
        anchors.fill: parent
        source: PlayerService.cover
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize { width: 680; height: 680 }
      }

      KitIcon {
        anchors.centerIn: parent
        visible: PlayerService.cover === ""
        name: PlayerService.radio ? "radio" : "music"
        tint: Theme.gray
        size: 48
      }
    }

    Column {
      id: details
      width: parent.width
      spacing: Theme.gapMedium

      // several players: the one to show and drive
      KitChoices {
        visible: PlayerService.sources.length > 1
        width: parent.width
        stretch: true
        model: PlayerService.sources.map(s => ({ label: s.name, value: s.key }))
        current: PlayerService.current?.key ?? ""
        onPicked: value => PlayerService.picked = value
      }

      Item {
        width: parent.width
        height: Math.max(info.implicitHeight, actions.height)

        Column {
          id: info
          anchors { left: parent.left; right: actions.left; rightMargin: Theme.gapMedium }
          spacing: Theme.gapHair

          KitText {
            width: parent.width
            text: PlayerService.title || "—"
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.ExtraBold
          }

          KitText {
            width: parent.width
            visible: text !== ""
            text: PlayerService.artist
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.foreground2
          }

          KitText {
            width: parent.width
            visible: text !== ""
            text: PlayerService.mpd && !PlayerService.radio
              ? [MpdService.player.album, MpdService.player.year].filter(s => s).join(" · ") : PlayerService.name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
        }

        Row {
          id: actions
          anchors { right: parent.right; top: parent.top }
          spacing: Theme.gapSmall

          KitButton {
            visible: root.yandexTrack
            icon: YandexService.isLiked ? "heart-filled" : "heart"
            iconTint: YandexService.isLiked ? Theme.red : Theme.foreground0
            onClicked: YandexService.toggleLike()
          }
          KitButton {
            visible: PlayerService.canRaise
            icon: "external"
            onClicked: PlayerService.raise()
          }
        }
      }

      // ---- timeline ----
      Column {
        width: parent.width
        visible: PlayerService.length > 0
        spacing: Theme.gapTight

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
            text: root.clock(root.at)
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
          KitText {
            anchors.right: parent.right
            text: root.showRemaining ? "-" + root.clock(PlayerService.length - root.at) : root.clock(PlayerService.length)
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
        }
      }

      // ---- transport ----
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

  // ---- up next: MPD's queue of the likes ----
  Item {
    visible: PlayerService.hasMedia && root.queueShown
    anchors { left: player.right; leftMargin: Theme.gapGroup + Theme.gapWide; right: parent.right; top: parent.top; bottom: parent.bottom }

    KitLabel {
      id: upNext
      text: "UP NEXT"
      value: MpdService.player.pos + " OF " + MpdService.player.length
    }

    MusicTracks {
      anchors { left: parent.left; right: parent.right; top: upNext.bottom; topMargin: Theme.gapMedium; bottom: parent.bottom }
      kind: "queue"
      tracks: root.queueShown ? YandexService.queue : []
      empty: "The queue is empty"
      onActivated: entry => MpdService.play(entry.pos)
      onMenu: (entry, index, anchor) => root.queueMenu(entry, index, anchor)
    }
  }
}
