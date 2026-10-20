import QtQuick
import Quickshell.Widgets
import qs.config
import qs.kit
import qs.modules.mpd

// The playing track: cover, title, artist and album, its like, the timeline and
// the transport. Stacked (the default: the cover on top, the timeline and the
// transport under it) or `side` (the full mode: the cover on the left, the text,
// the timeline and the transport on its right). The bar popup's; the caller decides
// when it shows.
Item {
  id: root

  property int coverSize: YandexService.coverSize
  property bool side: false
  readonly property var player: MpdService.player
  // the timeline's right end: the total, or the time left (Apps › Music)
  readonly property bool showRemaining: ModuleSettings.get("music", "showRemaining", false)
  readonly property int gap: Theme.gapWide

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  width: parent ? parent.width : 0
  // stacked: the cover, then the timeline and the transport; side: the taller of the cover and the right column
  height: side ? Math.max(coverSize, info.height + gap + timeline.height + gap + transport.height)
               : rowHeight + gap + timeline.height + gap + transport.height
  // stacked: the row of the cover and the text is as tall as the taller of the two
  readonly property real rowHeight: Math.max(coverSize, info.height)

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
      source: YandexService.cover
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize { width: root.coverSize * 2; height: root.coverSize * 2 }
    }

    KitIcon {
      anchors.centerIn: parent
      visible: YandexService.cover === ""
      name: "music"
      tint: Theme.gray
      size: Theme.iconLarge
    }
  }

  // ---- title, artist, album and the like ----
  Item {
    id: info

    x: cover.width + root.gap
    y: 0
    width: root.width - x
    height: Math.max(textColumn.implicitHeight, like.height)

    Column {
      id: textColumn
      anchors {
        left: parent.left
        right: like.left; rightMargin: Theme.gapMedium
        top: parent.top
      }
      spacing: Theme.gapHair

      KitText {
        width: parent.width
        text: root.player.title || root.player.file || ""
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
        font.pixelSize: root.coverSize > 64 ? Theme.fontSize + 2 : Theme.fontSize
      }

      KitText {
        width: parent.width
        text: root.player.artist || "—"
        elide: Text.ElideRight
        color: Theme.foreground2
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        width: parent.width
        text: [root.player.album, root.player.year].filter(s => s).join(" · ")
        elide: Text.ElideRight
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }

    KitButton {
      id: like
      anchors { right: parent.right; top: parent.top }
      visible: YandexService.trackId !== ""
      icon: YandexService.isLiked ? "heart-filled" : "heart"
      iconTint: YandexService.isLiked ? Theme.red : Theme.foreground0
      onClicked: YandexService.toggleLike()
    }
  }

  // ---- timeline ----
  Column {
    id: timeline

    x: root.side ? cover.width + root.gap : 0
    y: root.side ? info.height + root.gap : root.rowHeight + root.gap
    width: root.side ? root.width - x : root.width
    spacing: Theme.gapTight

    KitSlider {
      id: slider
      width: parent.width
      value: MpdService.duration > 0 ? MpdService.elapsed / MpdService.duration : 0
      onReleased: value => MpdService.seek(value)
    }

    Item {
      width: parent.width
      height: elapsed.implicitHeight

      KitText {
        id: elapsed
        text: root.clock(slider.pressed ? slider.dragValue * MpdService.duration : MpdService.elapsed)
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }

      KitText {
        anchors.right: parent.right
        text: root.showRemaining
          ? "-" + root.clock(MpdService.duration - (slider.pressed ? slider.dragValue * MpdService.duration : MpdService.elapsed))
          : root.clock(MpdService.duration)
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
      icon: "shuffle"
      selected: !!root.player.random
      iconTint: !!root.player.random ? Theme.foreground0 : Theme.gray
      onClicked: MpdService.toggleRandom()
    }

    Row {
      anchors.centerIn: parent
      spacing: Theme.gapMedium

      KitButton { icon: "skip-back"; onClicked: MpdService.prev() }

      KitButton {
        width: 52
        icon: MpdService.playing ? "pause" : "play"
        selected: true
        onClicked: MpdService.toggle()
      }

      KitButton { icon: "skip-forward"; onClicked: MpdService.next() }
    }

    KitButton {
      anchors.right: parent.right
      icon: root.player.repeat === "one" ? "repeat-1" : "repeat"
      selected: root.player.repeat !== "off"
      iconTint: root.player.repeat !== "off" ? Theme.foreground0 : Theme.gray
      onClicked: MpdService.cycleRepeat()
    }
  }
}
