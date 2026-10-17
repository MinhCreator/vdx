import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit
import qs.modules.mpd

// Internet radio. Idle: grey "RADIO". Click opens the stations, middle click
// starts / stops the radio.
Item {
  id: root

  // title length in the bar, from Modules › Radio (-1: full, 0 legacy: the icon alone)
  readonly property int maxLength: ModuleSettings.get("radio", "titleLength", 60)

  // what the bar names: the icon alone or the station and track (Modules › Radio)
  readonly property string show: ModuleSettings.get("radio", "show", "title")
  readonly property bool named: ModuleSettings.get("radio", "text", "content") === "name"
  readonly property bool iconOnly: !named && (show === "icon" || maxLength === 0)

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  // on / off changes the module's width: the open popup moves under it
  Connections {
    target: RadioService
    function onActiveChanged() { Qt.callLater(popup.reanchor); }
  }

  // "Station - track on air" while playing, cut like the music label.
  readonly property string text: BarLayout.faceText("radio", RadioService.active
    ? [MpdService.player.station, MpdService.player.title].filter(s => s).join(" - ")
    : "Radio")

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    // The icon marks the idle label only; while playing the station speaks for itself.
    icon: RadioService.active && !root.iconOnly ? "" : "radio"
    text: root.iconOnly ? "" : root.maxLength > 0 && root.text.length > root.maxLength
      ? root.text.slice(0, root.maxLength - 1) + Theme.ellipsis : root.text
    tint: RadioService.active ? Theme.foreground0 : Theme.gray
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) RadioService.setActive(!RadioService.active);
      else popup.toggle();
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "radio"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: RadioService.popupShown()

    RadioPopup {
      id: content
      anchors.fill: parent
    }
  }
}
