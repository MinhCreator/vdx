import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// The media player of any app (MPRIS: Spotify, a browser, mpv) and the Yandex
// Music / radio of MPD, through PlayerService. Idle: grey "Player". Click opens
// the player, middle click plays or pauses it.
Item {
  id: root

  // title length in the bar, from Modules › Player (-1: full, 0: the icon alone)
  readonly property int maxLength: ModuleSettings.get("player", "titleLength", 60)

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  // what the bar names: icon, both, the title or the artist (Modules › Player)
  readonly property string show: ModuleSettings.get("player", "show", "both")
  readonly property string textMode: ModuleSettings.get("player", "text", "content")
  readonly property bool iconOnly: textMode === "icon" || (textMode === "content" && (show === "icon" || maxLength === 0))
  readonly property string title: (show === "title" ? [PlayerService.title]
                                 : show === "artist" ? [PlayerService.artist]
                                 : [PlayerService.artist, PlayerService.title]).filter(s => s).join(" - ")
  readonly property string text: BarLayout.faceText("player", PlayerService.playing && title !== "" ? title : "Player")

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    // the icon marks the idle label only; while playing the track speaks for itself
    icon: PlayerService.playing && !root.iconOnly ? "" : "play"
    text: root.iconOnly ? "" : root.maxLength > 0 && root.text.length > root.maxLength
      ? root.text.slice(0, root.maxLength - 1) + Theme.ellipsis : root.text
    tint: PlayerService.playing ? Theme.accentFor("modules", Theme.foreground0) : Theme.gray
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) PlayerService.togglePlay();
      else popup.toggle();
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "player"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    PlayerPopup {
      id: content
      anchors.fill: parent
      onOpenWindow: popup.visible = false
    }
  }
}
