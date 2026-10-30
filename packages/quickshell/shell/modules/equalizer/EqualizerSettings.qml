import QtQuick
import qs.config
import qs.kit

// Equalizer options in the Shell Manager: the bars' colour, a dot per choice
// like the notifications dot; the gradients run from the left bar to the right.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  // Appearance › Colours (APPLIES TO Bar modules) takes the bars: the dots stay, dimmed
  KitColourRow {
    label: "Colour"
    hint: Theme.accentOn("modules") ? "Set by Colours › Bar modules" : "Sea and sunset: gradients"
    dimmed: Theme.accentOn("modules")
    enabled: !Theme.accentOn("modules")
    names: Theme.colourSet.concat(["sea", "sunset"])
    picked: ModuleSettings.get("equalizer", "colour", "theme")
    colours: name => Theme.equalizerColours(name)
    onChosen: value => ModuleSettings.set("equalizer", "colour", value)
  }

  KitLinkRow {
    visible: Theme.accentOn("modules")
    label: "Accent"
    hint: "In Appearance › Colours › Bar modules"
    target: "appearance:accent"
  }

  KitToggleRow {
    module: "equalizer"; key: "showPaused"; fallback: true
    label: "Show when paused"; hint: "Off: shown only while it plays"
  }

  KitGrouper {}
}
