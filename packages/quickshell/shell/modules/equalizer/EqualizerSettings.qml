import QtQuick
import qs.config
import qs.kit

// Equalizer options in the Shell Manager: the bars' colour, a dot per choice
// like the notifications dot; the gradients run from the left bar to the right.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow {
    module: "equalizer"; key: "accent"; fallback: false
    label: "Follow accent"
    hint: ShellSettings.accent ? "Off: its own colour" : "The accent is off"
  }

  KitRow {
    visible: !ModuleSettings.get("equalizer", "accent", false)
    label: "Colour"
    hint: "Sea and sunset: gradients"

    KitSwatches {
      model: ["sunset", "sea", "blue", "green", "yellow", "red", "theme"]
      picked: ModuleSettings.get("equalizer", "colour", "theme")
      colours: name => Theme.equalizerColours(name)
      onChosen: name => ModuleSettings.set("equalizer", "colour", name)
    }
  }

  KitToggleRow {
    module: "equalizer"; key: "showPaused"; fallback: true
    label: "Show when paused"; hint: "Off: shown only while it plays"
  }
}
