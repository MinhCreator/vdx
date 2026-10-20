import QtQuick
import Quickshell.Widgets
import qs.config
import qs.kit
import qs.modules.mpd
import qs.modules.player
import qs.modules.yandex

// The track that plays, of any source (PlayerService): the cover, the title, artist
// and album, the like (a Yandex track only), the timeline and the transport. Several
// players running: a choice of them on top. Nothing playing says so.
Column {
  id: root

  readonly property int coverSize: YandexService.coverSize
  readonly property int gap: Theme.gapWide
  // the timeline's right end: the total, or the time left (Modules › Music)
  readonly property bool showRemaining: ModuleSettings.get("music", "showRemaining", false)
  // the like belongs to a Yandex track only
  readonly property bool yandexTrack: PlayerService.mpd && MpdService.source === "likes" && YandexService.trackId !== ""
  readonly property string detail: PlayerService.mpd
    ? [MpdService.player.album, MpdService.player.year].filter(s => s).join(" · ") : ""

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  width: parent ? parent.width : 0
  spacing: gap


  KitText {
    visible: !PlayerService.hasMedia
    width: parent.width
    wrapMode: Text.WordWrap
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
    text: "Nothing is playing. Pick something in Library."
  }

  Item {
    id: now
    visible: PlayerService.hasMedia
    width: parent.width
    // the row of the cover and the text, the timeline, the transport
    height: Math.max(root.coverSize, info.height) + root.gap + timeline.height + root.gap + transport.height

    // ---- cover ----
    ClippingRectangle {
      id: cover
      x: 0
      y: 0
      radius: Theme.radiusCard
      width: root.coverSize
      height: width
      color: Theme.background1
      border.width: Theme.frameWidth
      border.color: Theme.background3

      Image {
        anchors { fill: parent; margins: 1 }
        source: PlayerService.cover
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize { width: root.coverSize * 2; height: root.coverSize * 2 }
      }

      KitIcon {
        anchors.centerIn: parent
        visible: PlayerService.cover === ""
        name: PlayerService.radio ? "radio" : "music"
        tint: Theme.gray
        size: Theme.iconLarge
      }
    }

    // ---- title, artist, album, and the like / raise ----
    Item {
      id: info

      x: cover.width + root.gap
      y: 0
      width: now.width - x
      height: Math.max(textColumn.implicitHeight, like.height)

      Column {
        id: textColumn
        anchors {
          left: parent.left
          right: raise.left; rightMargin: Theme.gapMedium
          top: parent.top
        }
        spacing: Theme.gapHair

        KitText {
          width: parent.width
          text: PlayerService.title || "—"
          textFormat: Text.PlainText
          elide: Text.ElideRight
          font.weight: Font.ExtraBold
          font.pixelSize: root.coverSize > 64 ? Theme.fontSize + 2 : Theme.fontSize
        }

        KitText {
          width: parent.width
          text: PlayerService.artist || "—"
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          width: parent.width
          visible: text !== ""
          text: root.detail
          textFormat: Text.PlainText
          elide: Text.ElideRight
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }

      KitButton {
        id: raise
        anchors { right: like.left; rightMargin: Theme.gapTight; top: parent.top }
        visible: PlayerService.canRaise
        icon: "external"
        onClicked: PlayerService.raise()
      }

      KitButton {
        id: like
        anchors { right: parent.right; top: parent.top }
        visible: root.yandexTrack
        icon: YandexService.isLiked ? "heart-filled" : "heart"
        iconTint: YandexService.isLiked ? Theme.red : Theme.foreground0
        onClicked: YandexService.toggleLike()
      }
    }

    // ---- timeline ----
    Column {
      id: timeline

      y: Math.max(root.coverSize, info.height) + root.gap
      width: parent.width
      spacing: Theme.gapTight

      KitSlider {
        id: slider
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
          text: root.clock(slider.pressed ? slider.dragValue * PlayerService.length : PlayerService.position)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        KitText {
          anchors.right: parent.right
          visible: PlayerService.length > 0
          text: root.showRemaining
            ? "-" + root.clock(PlayerService.length - (slider.pressed ? slider.dragValue * PlayerService.length : PlayerService.position))
            : root.clock(PlayerService.length)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }

    // ---- transport ----
    Item {
      id: transport

      x: timeline.x
      y: timeline.y + timeline.height + root.gap
      width: timeline.width
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

  // several players: the one to show, as a list (any number fits), the popup's width at the foot
  KitSelect {
    visible: PlayerService.sources.length > 1
    width: parent.width
    boxWidth: width
    model: PlayerService.sources.map(s => ({ label: s.name, value: s.key, note: s.playing ? "playing" : "" }))
    current: PlayerService.current?.key ?? ""
    onPicked: value => PlayerService.picked = value
  }
}
