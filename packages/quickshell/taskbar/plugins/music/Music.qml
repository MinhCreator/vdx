import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.plugins.mpd

// Liked tracks player. Idle: grey "MUSIC". Click opens the player, middle click
// toggles playback, right click opens ncmpcpp, the wheel skips tracks.
Item {
  id: root

  required property PanelWindow bar

  readonly property string title: [MpdService.player.artist, MpdService.player.title].filter(s => s).join(" - ")
  readonly property string text: MusicService.active && title !== "" ? title : "Music"

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    // The icon marks the idle label only; while playing the track speaks for itself.
    text: (MusicService.active ? "" : Theme.iconMusic + " ") + (root.text.length > Theme.musicMaxLength
      ? root.text.slice(0, Theme.musicMaxLength - 1) + Theme.ellipsis : root.text)
    color: MusicService.active ? Theme.foreground0 : Theme.gray
  }

  // Wheel events reach a layer-shell surface only through a MouseArea.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        if (MpdService.source === "likes") MpdService.toggle();
        else MusicService.setActive(true);
      }
      else if (mouse.button === Qt.RightButton) Quickshell.execDetached(["kitty", "--class", "ncmpcpp", "-e", "ncmpcpp"]);
      else popup.toggle();
    }
    onWheel: wheel => {
      if (!MusicService.active) return;
      if (wheel.angleDelta.y > 0) MpdService.prev();
      else if (wheel.angleDelta.y < 0) MpdService.next();
    }
  }


  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "music"
    alignLeft: true
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: MusicService.popupShown()
    onHidden: MusicService.popupHidden()

    MusicPopup {
      id: content
      anchors.fill: parent
    }
  }
}
