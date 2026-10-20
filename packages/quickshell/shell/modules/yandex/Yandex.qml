import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit
import qs.modules.mpd

// Liked tracks player. Idle: grey "Music". Click opens the player, middle click
// toggles playback.
Item {
  id: root

  // title length in the bar, from Modules › Music (-1: full, 0 legacy: the icon alone)
  readonly property int maxLength: ModuleSettings.get("yandex", "titleLength", 60)

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  // what the bar names: icon, both, the title or the artist (Modules › Music)
  readonly property string show: ModuleSettings.get("yandex", "show", "both")
  readonly property string textMode: ModuleSettings.get("yandex", "text", "content")
  readonly property bool iconOnly: textMode === "icon" || (textMode === "content" && (show === "icon" || maxLength === 0))
  readonly property string title: (show === "title" ? [MpdService.player.title]
                                 : show === "artist" ? [MpdService.player.artist]
                                 : [MpdService.player.artist, MpdService.player.title]).filter(s => s).join(" - ")
  readonly property string text: BarLayout.faceText("yandex", YandexService.active && title !== "" ? title : "Music")

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    // The icon marks the idle label only; while playing the track speaks for itself.
    icon: YandexService.active && !root.iconOnly ? "" : "music"
    text: root.iconOnly ? "" : root.maxLength > 0 && root.text.length > root.maxLength
      ? root.text.slice(0, root.maxLength - 1) + Theme.ellipsis : root.text
    tint: YandexService.active ? Theme.accentFor("modules", Theme.foreground0) : Theme.gray
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        if (MpdService.source === "likes") MpdService.toggle();
        else YandexService.setActive(true);
      }
      else popup.toggle();
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "yandex"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: YandexService.popupShown()
    onHidden: YandexService.popupHidden()

    YandexPopup {
      id: content
      anchors.fill: parent
    }
  }
}
