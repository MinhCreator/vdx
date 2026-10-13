import QtQuick
import qs.components
import qs.config
import qs.plugins.mpd

PopupFrame {
  id: root

  readonly property var player: MpdService.player

  function clock(seconds) {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: Theme.iconMusic
    title: "MUSIC"
    subtitle: !MusicService.active ? "OFF"
      : (MpdService.playing ? "PLAYING" : "PAUSED") + " · " + root.player.pos + "/" + root.player.length
    subtitleColor: !MusicService.active ? Theme.muted : MpdService.playing ? Theme.green : Theme.foreground2

    PopupButton {
      anchors.verticalCenter: parent.verticalCenter
      glyph: Theme.iconRefresh
      glyphSize: Theme.headerButtonSize
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      busy: MusicService.updating
      status: MusicService.updateStatus
      onClicked: MusicService.runUpdate()
    }

    PopupSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: MusicService.active
      disabled: MpdService.busy === "likes"
      onToggled: MusicService.setActive(!MusicService.active)
    }
  }

  PopupSeparator { width: parent.width }

  ThemeText {
    visible: !MusicService.active
    text: MpdService.busy === "likes" ? "LOADING LIKES…" : "LIKES ARE NOT PLAYING"
    color: Theme.muted
    font.letterSpacing: 1
  }

  // ---- now playing -----------------------------------------------------------
  Column {
    width: parent.width
    visible: MusicService.active
    spacing: 8

    Item {
      width: parent.width
      height: Theme.musicCoverSize

      Rectangle {
        id: coverBox
        width: Theme.musicCoverSize
        height: width
        color: Theme.background2

        Image {
          anchors.fill: parent
          source: MusicService.cover
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          sourceSize { width: Theme.musicCoverSize * 2; height: Theme.musicCoverSize * 2 }
        }

        ThemeText {
          anchors.centerIn: parent
          visible: MusicService.cover === ""
          text: Theme.iconMusic
          color: Theme.dim
          font.pixelSize: Theme.fontSize + 10
        }
      }

      Column {
        anchors {
          left: coverBox.right; leftMargin: 10
          right: like.left; rightMargin: 6
          verticalCenter: parent.verticalCenter
        }
        spacing: 3

        ThemeText {
          width: parent.width
          text: root.player.title || root.player.file || ""
          elide: Text.ElideRight
        }

        ThemeText {
          width: parent.width
          text: root.player.artist || "—"
          elide: Text.ElideRight
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }

        ThemeText {
          width: parent.width
          text: [root.player.album, root.player.year].filter(s => s).join(" · ")
          elide: Text.ElideRight
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
        }
      }

      PopupButton {
        id: like
        anchors { right: parent.right; top: parent.top }
        visible: MusicService.trackId !== ""
        glyph: MusicService.isLiked ? Theme.iconHeart : Theme.iconHeartOutline
        glyphSize: Theme.headerButtonSize
        tint: MusicService.isLiked ? Theme.red : Theme.foreground0
        frameless: true
        hoverBackground: false
        onClicked: MusicService.toggleLike()
      }
    }

    // ---- progress ------------------------------------------------------------
    Column {
      width: parent.width
      spacing: 2

      PopupSlider {
        id: timeline
        width: parent.width
        value: MpdService.duration > 0 ? MpdService.elapsed / MpdService.duration : 0
        onReleased: value => MpdService.seek(value)
      }

      Item {
        width: parent.width
        height: elapsedText.implicitHeight

        ThemeText {
          id: elapsedText
          text: root.clock(timeline.pressed ? timeline.dragValue * MpdService.duration : MpdService.elapsed)
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
        }

        ThemeText {
          anchors.right: parent.right
          text: root.clock(MpdService.duration)
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }

    // ---- controls ------------------------------------------------------------
    Item {
      width: parent.width
      height: playButton.implicitHeight

      PopupButton {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        glyph: root.player.random ? Theme.iconRandom : Theme.iconRandomOff
        glyphSize: Theme.headerButtonSize
        tint: root.player.random ? Theme.green : Theme.foreground0
        frameless: true
        hoverBackground: false
        onClicked: MpdService.toggleRandom()
      }

      Row {
        anchors.centerIn: parent
        spacing: 12

        PopupButton {
          anchors.verticalCenter: parent.verticalCenter
          glyph: Theme.iconPrev
          glyphSize: Theme.headerButtonSize
          tint: Theme.foreground0
          frameless: true
          hoverBackground: false
          onClicked: MpdService.prev()
        }

        PopupButton {
          id: playButton
          anchors.verticalCenter: parent.verticalCenter
          glyph: MpdService.playing ? Theme.iconPause : Theme.iconPlay
          glyphSize: Theme.fontSize + 10
          tint: Theme.foreground0
          frameless: true
          hoverBackground: false
          onClicked: MpdService.toggle()
        }

        PopupButton {
          anchors.verticalCenter: parent.verticalCenter
          glyph: Theme.iconNext
          glyphSize: Theme.headerButtonSize
          tint: Theme.foreground0
          frameless: true
          hoverBackground: false
          onClicked: MpdService.next()
        }
      }

      PopupButton {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        glyph: root.player.repeat === "one" ? Theme.iconRepeatOnce
             : root.player.repeat === "all" ? Theme.iconRepeat
             : Theme.iconRepeatOff
        glyphSize: Theme.headerButtonSize
        tint: root.player.repeat !== "off" ? Theme.green : Theme.foreground0
        frameless: true
        hoverBackground: false
        onClicked: MpdService.cycleRepeat()
      }
    }
  }

  PopupSeparator {
    width: parent.width
    visible: MusicService.active
  }

  MusicQueue {
    width: parent.width
    visible: MusicService.active
  }

  PopupError { text: MpdService.error }
}
