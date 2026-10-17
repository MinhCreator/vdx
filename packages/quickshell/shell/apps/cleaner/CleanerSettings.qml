import QtQuick
import qs.config
import qs.kit

// Cleaner options in the Shell Manager (ModuleSettings "cleaner"): cleaning,
// then the AI mode.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "CLEANING" }

  KitToggleRow { module: "cleaner"; key: "confirm"; label: "Ask before cleaning"; hint: "The button asks “Sure?” once" }

  KitLine {}

  KitLabel { text: "AI" }

  KitToggleRow { module: "cleaner"; key: "ai"; label: "AI mode"; hint: "Claude suggests what in ~ could go" }

  KitOptionRow {
    module: "cleaner"; key: "model"; fallback: "haiku"
    label: "Model"; hint: "Haiku: quick. Sonnet: careful"
    model: [{ label: "Haiku", value: "haiku" }, { label: "Sonnet", value: "sonnet" }]
  }
}
