import QtQuick
import qs.config
import qs.kit

// Equalizer options in the Shell Manager: the bars' colour, a dot per choice
// like the notifications dot; the gradients run from the left bar to the right.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  // Appearance › Accent (APPLIES TO Bar modules) takes the bars: the dots stay, dimmed
  KitRow {
    label: "Colour"
    hint: Theme.accentOn("modules") ? "Set by Accent › Bar modules" : "Sea and sunset: gradients"

    KitSwatches {
      disabled: Theme.accentOn("modules")
      model: ["sunset", "sea", "blue", "green", "yellow", "red", "theme"]
      picked: ModuleSettings.get("equalizer", "colour", "theme")
      colours: name => Theme.equalizerColours(name)
      onChosen: name => ModuleSettings.set("equalizer", "colour", name)
    }
  }

  KitLinkRow {
    visible: Theme.accentOn("modules")
    label: "Accent"
    hint: "In Appearance › Accent › Bar modules"
    target: "appearance:accent"
  }

  KitToggleRow {
    module: "equalizer"; key: "showPaused"; fallback: true
    label: "Show when paused"; hint: "Off: shown only while it plays"
  }

  KitGrouper {}
}
