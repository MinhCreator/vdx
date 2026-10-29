import QtQuick
import qs.config
import qs.kit

// A plan's limits in the AI popup: a bar per window with its reset, then when
// the numbers are from. Claude's and Codex's tabs each show one.
Column {
  id: root

  property var limits: []
  property real fetchedAt: 0      // ms, 0 before any
  property string error: ""
  property string stamp: "Updated "

  readonly property var labels: ({
    session: "Session · 5h",
    weekly_all: "Week",
    weekly_opus: "Week · Opus",
    weekly_sonnet: "Week · Sonnet"
  })

  function resetsIn(iso) {
    if (!iso) return "";
    const ms = new Date(iso) - Date.now();
    if (ms <= 0) return "resets now";
    const h = Math.floor(ms / 3600000);
    const m = Math.floor(ms % 3600000 / 60000);
    if (h < 24) return "resets in " + (h > 0 ? h + "h " : "") + m + "m";
    return "resets " + Qt.formatDateTime(new Date(iso), "ddd HH:mm");
  }

  width: parent.width
  spacing: Theme.gapWide

  KitLabel { text: "PLAN LIMITS" }

  Repeater {
    model: root.limits

    Column {
      required property var modelData

      readonly property color tint: ClaudeService.limitColor(modelData.percent)

      width: parent.width
      spacing: 5

      KitInfo {
        label: root.labels[modelData.kind] ?? modelData.kind.replace(/_/g, " ")
        value: modelData.percent + "%"
        valueColor: parent.tint
      }

      KitBar {
        value: modelData.percent / 100
        tint: parent.tint
      }

      KitText {
        text: root.resetsIn(modelData.resets_at)
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }
  }

  KitText {
    visible: root.limits.length === 0 && root.error === ""
    text: "Loading…"
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  // when the limits are from; a failed refresh keeps them and says so
  KitText {
    width: parent.width
    visible: root.fetchedAt > 0 || root.error !== ""
    text: root.fetchedAt > 0
      ? (root.error !== "" ? "Couldn't refresh (" + root.error + ") · data from " : root.stamp)
        + Qt.formatDateTime(new Date(root.fetchedAt),
                            new Date(root.fetchedAt).toDateString() === new Date().toDateString() ? "HH:mm" : "dd MMM HH:mm")
      : root.error
    color: root.error !== "" && root.fetchedAt === 0 ? Theme.red : Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 2
  }
}
