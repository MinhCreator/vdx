import QtQuick
import qs.config
import qs.kit
import qs.modules.mpd
import Quickshell.Widgets

// Music (Yandex likes over MPD): the track with cover, timeline and controls,
// then the queue.
KitFrame {
  id: root

  readonly property var player: MpdService.player

  property string tab: "playing"

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  // ---- header ----
  KitHeader {
    icon: "music"
    iconColor: MusicService.active ? Theme.foreground0 : Theme.muted
    title: "Music"
    subtitle: !MusicService.active ? (MpdService.busy === "likes" ? "LOADING LIKES…" : "OFF")
      : (MpdService.playing ? "PLAYING" : "PAUSED") + " · " + root.player.pos + " / " + root.player.length

    KitSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: MusicService.active
      disabled: MpdService.busy === "likes"
      onToggled: MusicService.setActive(!MusicService.active)
    }
  }

  KitChoices {
    visible: MusicService.active
    model: [
      { label: "Now playing", value: "playing", icon: "music" },
      { label: "Queue (" + MusicService.queue.length + ")", value: "queue", icon: "list" }
    ]
    current: root.tab
    onPicked: value => root.tab = value
  }

  KitLine {}

  KitText {
    visible: !MusicService.active
    text: "Likes are not playing. Switch them on to start."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- now playing ----
  Column {
    width: parent.width
    visible: MusicService.active && root.tab === "playing"
    spacing: Theme.gapWide

    Item {
      width: parent.width
      height: MusicService.coverSize

      ClippingRectangle {
        radius: Theme.radiusCard
        id: cover
        width: MusicService.coverSize
        height: width
        color: Theme.background1
        border.width: Theme.frameWidth
        border.color: Theme.background3

        Image {
          anchors { fill: parent; margins: 1 }
          source: MusicService.cover
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          sourceSize { width: MusicService.coverSize * 2; height: MusicService.coverSize * 2 }
        }

        KitIcon {
          anchors.centerIn: parent
          visible: MusicService.cover === ""
          name: "music"
          tint: Theme.gray
          size: Theme.iconLarge
        }
      }

      Column {
        anchors {
          left: cover.right; leftMargin: Theme.gapWide
          right: like.left; rightMargin: Theme.gapMedium
          verticalCenter: parent.verticalCenter
        }
        spacing: Theme.gapHair

        KitText {
          width: parent.width
          text: root.player.title || root.player.file || ""
          elide: Text.ElideRight
          font.weight: Font.ExtraBold
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
        visible: MusicService.trackId !== ""
        icon: MusicService.isLiked ? "heart-filled" : "heart"
        iconTint: MusicService.isLiked ? Theme.red : Theme.foreground0
        onClicked: MusicService.toggleLike()
      }
    }

    // ---- timeline ----
    Column {
      width: parent.width
      spacing: Theme.gapTight

      KitSlider {
        id: timeline
        width: parent.width
        value: MpdService.duration > 0 ? MpdService.elapsed / MpdService.duration : 0
        onReleased: value => MpdService.seek(value)
      }

      Item {
        width: parent.width
        height: elapsed.implicitHeight

        KitText {
          id: elapsed
          text: root.clock(timeline.pressed ? timeline.dragValue * MpdService.duration : MpdService.elapsed)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        KitText {
          anchors.right: parent.right
          text: root.clock(MpdService.duration)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }

    // ---- controls ----
    Item {
      width: parent.width
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

  MusicQueue {
    width: parent.width
    visible: MusicService.active && root.tab === "queue"
  }

  KitText {
    width: parent.width
    visible: MpdService.error !== ""
    text: MpdService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
