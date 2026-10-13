import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.plugins.mpd

// Internet radio. Idle: grey "RADIO". Click opens the stations, middle click
// starts / stops the radio.
Item {
  id: root

  required property PanelWindow bar

  // "Station - track on air" while playing, cut like the music label.
  readonly property string text: RadioService.active
    ? [MpdService.player.station, MpdService.player.title].filter(s => s).join(" - ")
    : "Radio"

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    // The icon marks the idle label only; while playing the station speaks for itself.
    text: (RadioService.active ? "" : Theme.iconRadio + " ") + (root.text.length > Theme.musicMaxLength
      ? root.text.slice(0, Theme.musicMaxLength - 1) + Theme.ellipsis : root.text)
    color: RadioService.active ? Theme.foreground0 : Theme.gray
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
    alignLeft: true
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
