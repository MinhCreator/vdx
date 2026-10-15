import QtQuick
import qs.config
import qs.kit

// Cleaner options in the Shell Manager (PluginSettings "cleaner"): cleaning,
// then the AI mode.
Column {
  spacing: 14

  KitLabel { text: "CLEANING" }

  KitToggleRow { plugin: "cleaner"; key: "confirm"; label: "Ask before cleaning"; hint: "the button asks “Sure?” once" }

  KitLine {}

  KitLabel { text: "AI" }

  KitToggleRow { plugin: "cleaner"; key: "ai"; label: "AI mode"; hint: "Claude suggests what in ~ could go" }

  KitOptionRow {
    plugin: "cleaner"; key: "model"; fallback: "haiku"
    label: "Model"; hint: "haiku is quick, sonnet looks closer"
    model: [{ label: "Haiku", value: "haiku" }, { label: "Sonnet", value: "sonnet" }]
  }
}
