import QtQuick
import qs.components
import qs.config
import qs.plugins.mpd

PopupFrame {
  id: root

  implicitWidth: Theme.popupWidthCompact

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: Theme.iconRadio
    title: "RADIO"
    subtitle: RadioService.active ? "ON AIR · " + MpdService.player.station.toUpperCase() : "OFF"
    subtitleColor: RadioService.active ? Theme.green : Theme.muted

    PopupSwitch {
      checked: RadioService.active
      disabled: RadioService.stations.length === 0
      onToggled: RadioService.setActive(!RadioService.active)
    }
  }

  PopupSeparator { width: parent.width }

  // ---- now playing -----------------------------------------------------------
  Column {
    width: parent.width
    visible: RadioService.active
    spacing: 2

    ThemeText {
      text: "NOW PLAYING"
      color: Theme.dim
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }

    ThemeText {
      width: parent.width
      text: MpdService.player.title || "—"
      elide: Text.ElideRight
    }
  }

  PopupSeparator {
    width: parent.width
    visible: RadioService.active
  }

  // ---- station -------------------------------------------------------------
  PopupSelect {
    width: parent.width
    label: "STATION"
    model: RadioService.stations.map(s => ({ label: s.name.toUpperCase(), value: s.key }))
    current: RadioService.active ? RadioService.stationKey : null
    busyValue: MpdService.busy
    onPicked: value => RadioService.play(value)
  }

  PopupError { text: MpdService.error }
}
