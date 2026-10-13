import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  readonly property var labels: ({
    session: "SESSION · 5H",
    weekly_all: "WEEK",
    weekly_opus: "WEEK · OPUS",
    weekly_sonnet: "WEEK · SONNET"
  })
  readonly property real columnWidth: (width - 2 * inset - 16) / 2

  function resetsIn(iso) {
    if (!iso) return "";
    const ms = new Date(iso) - Date.now();
    if (ms <= 0) return "resets now";
    const h = Math.floor(ms / 3600000);
    const m = Math.floor(ms % 3600000 / 60000);
    if (h < 24) return "resets in " + (h > 0 ? h + "h " : "") + m + "m";
    return "resets " + Qt.formatDateTime(new Date(iso), "ddd HH:mm");
  }

  function shortPath(path) {
    return path.replace(/^\/home\/[^/]+/, "~");
  }

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: Theme.iconRobot
    title: "CLAUDE CODE"
    subtitle: [ClaudeService.plan.toUpperCase(),
               ClaudeService.sessions.length > 0
                 ? (ClaudeService.busy > 0 ? ClaudeService.busy + " WORKING" : ClaudeService.sessions.length + " IDLE")
                 : "NO SESSIONS"].filter(s => s).join(" · ")
    subtitleColor: ClaudeService.busy > 0 ? Theme.green : Theme.foreground2

    PopupButton {
      anchors.verticalCenter: parent.verticalCenter
      glyph: Theme.iconRefresh
      glyphSize: Theme.headerButtonSize
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      busy: ClaudeService.refreshing
      onClicked: ClaudeService.refresh()
    }
  }

  PopupSeparator { width: parent.width }

  // ---- limits ----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 10

    Repeater {
      model: ClaudeService.limits

      PopupMeter {
        required property var modelData

        width: parent.width
        label: root.labels[modelData.kind] ?? modelData.kind.replace(/_/g, " ").toUpperCase()
        text: modelData.percent + "%"
        value: modelData.percent / 100
        tint: Theme.qualityColor(modelData.percent, Theme.claudeWarning - 25, Theme.claudeWarning)
        note: root.resetsIn(modelData.resets_at)
      }
    }

    ThemeText {
      visible: ClaudeService.limits.length === 0 && ClaudeService.error === ""
      text: "LOADING…"
      color: Theme.muted
      font.letterSpacing: 1
    }

    PopupError { text: ClaudeService.error }
  }

  PopupSeparator { width: parent.width }

  // ---- today -----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 6

    PopupSectionTitle {
      width: parent.width
      text: "TODAY"
    }

    Row {
      width: parent.width
      spacing: 16

      PopupInfoList {
        width: root.columnWidth
        model: [
          { label: "OUTPUT",     value: Theme.humanCount(ClaudeService.today.output ?? 0) },
          { label: "INPUT",      value: Theme.humanCount(ClaudeService.today.input ?? 0) },
          { label: "MESSAGES",   value: String(ClaudeService.today.messages ?? 0) }
        ]
      }

      PopupInfoList {
        width: root.columnWidth
        model: [
          { label: "CACHE READ",  value: Theme.humanCount(ClaudeService.today.cache_read ?? 0) },
          { label: "CACHE WRITE", value: Theme.humanCount(ClaudeService.today.cache_write ?? 0) }
        ]
      }
    }
  }

  PopupSeparator { width: parent.width }

  // ---- sessions --------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 6

    PopupSectionTitle {
      width: parent.width
      text: "SESSIONS"
    }

    Repeater {
      model: ClaudeService.sessions

      Column {
        id: session

        required property var modelData

        width: parent.width
        spacing: 1

        Item {
          width: parent.width
          height: name.implicitHeight

          ThemeText {
            id: name
            anchors { left: parent.left; right: statusText.left; rightMargin: 8 }
            text: session.modelData.name || "—"
            elide: Text.ElideRight
          }

          ThemeText {
            id: statusText
            anchors.right: parent.right
            text: session.modelData.status.toUpperCase()
            color: session.modelData.status === "busy" ? Theme.green : Theme.dim
            font.pixelSize: Theme.fontSize - 2
            font.letterSpacing: 1
          }
        }

        ThemeText {
          width: parent.width
          text: root.shortPath(session.modelData.cwd) + " · v" + session.modelData.version
          elide: Text.ElideMiddle
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }

    ThemeText {
      visible: ClaudeService.sessions.length === 0
      text: "NO RUNNING SESSIONS"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }
  }
}
