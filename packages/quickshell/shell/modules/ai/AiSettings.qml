import QtQuick
import qs.bar
import qs.config
import qs.kit

// AI module options in the Shell Manager: which plan limit (Claude's or Codex's) its bar item shows.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "ai" }

  // four choices: a select, segments would cut the labels
  KitSelect {
    width: parent.width
    visible: ModuleSettings.get("ai", "text", "content") === "content"
    label: "Limit"
    hint: "Its percent is shown in the bar"
    model: [
      { label: "Claude · 5 h", value: "session" },
      { label: "Claude · week", value: "weekly_all" },
      { label: "Codex · 5 h", value: "codex_session" },
      { label: "Codex · week", value: "codex_weekly_all" }
    ]
    current: ModuleSettings.get("ai", "limit", "session")
    onPicked: value => ModuleSettings.set("ai", "limit", value)
  }

  KitToggleRow {
    module: "ai"; key: "tint"; fallback: true
    label: "Colour the icon"; hint: "Green, yellow, orange or red with the limit"
  }

  KitToggleRow {
    module: "ai"; key: "compact"; fallback: false
    label: "Compact popup"; hint: "Hides today's tokens and the sessions: the limits only"
  }

  KitGrouper {}
}
