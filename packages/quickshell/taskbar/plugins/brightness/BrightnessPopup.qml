import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  implicitWidth: Theme.popupWidthCompact

  readonly property real temperatureSpan: Theme.nightTemperatureMax - Theme.nightTemperatureMin

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: Theme.iconBrightness
    glyphColor: BrightnessService.nightActive ? Theme.orange : Theme.foreground0
    title: "DISPLAY"
    subtitle: "BRIGHTNESS · " + BrightnessService.brightness + "%"
      + (BrightnessService.nightActive ? " · NIGHT LIGHT" : "")
  }

  PopupSeparator { width: parent.width }

  // ---- backlight / dimming -------------------------------------------------
  Column {
    width: parent.width
    spacing: 6

    PopupSliderRow {
      width: parent.width
      label: "BRIGHTNESS"
      value: BrightnessService.brightness / 100
      text: BrightnessService.brightness + "%"
      onMoved: value => BrightnessService.setBrightness(value * 100)
    }

    PopupSliderRow {
      width: parent.width
      label: "DIMMING"
      value: (BrightnessService.gamma - Theme.dimGammaMin) / (100 - Theme.dimGammaMin)
      text: BrightnessService.gamma + "%"
      onMoved: value => BrightnessService.setGamma(Theme.dimGammaMin + value * (100 - Theme.dimGammaMin))
    }
  }

  PopupSeparator { width: parent.width }

  // ---- night light -----------------------------------------------------------
  Column {
    width: parent.width
    spacing: 6

    PopupSectionTitle {
      width: parent.width
      text: "NIGHT LIGHT"

      PopupSwitch {
        checked: BrightnessService.nightActive
        onToggled: BrightnessService.setNight(!BrightnessService.nightActive)
      }
    }

    PopupSliderRow {
      width: parent.width
      visible: BrightnessService.nightActive
      label: "TEMPERATURE"
      value: (BrightnessService.temperature - Theme.nightTemperatureMin) / root.temperatureSpan
      text: BrightnessService.temperature + "K"
      onMoved: value => BrightnessService.setTemperature(Theme.nightTemperatureMin + value * root.temperatureSpan)
    }

    PopupChoices {
      width: parent.width
      visible: BrightnessService.nightActive && BrightnessService.presets.length > 0
      model: BrightnessService.presets.map(p => ({ label: p.label, value: p.temperature }))
      current: BrightnessService.temperature
      onPicked: value => BrightnessService.setTemperature(value)
    }
  }
}
