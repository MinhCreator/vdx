import QtQuick
import qs.config
import qs.kit

// The task manager's content, in the kit style: a header with the search,
// the machine's CPU and memory, a table of programs (or processes) sorted by
// a click on a column title, and the selected row's End / Kill at the foot.
// Keys: ↑ ↓ select, Delete ends, Shift+Delete kills, Ctrl+F searches.
Rectangle {
  id: root

  color: Theme.background0

  readonly property var tm: TaskManagerService
  // a click on End / Kill asks once more (option `confirm`) — "" | end | kill
  property string armed: ""

  // bytes per second, short: 167B, 12K, 1.4M
  function rate(b) {
    return b < 1024 ? Math.round(b) + "B" : b < 1048576 ? Math.round(b / 1024) + "K" : (b / 1048576).toFixed(1) + "M";
  }

  function act(kind) {
    if (!tm.selectedRow) return;
    if (tm.confirm && armed !== kind) { armed = kind; disarm.restart(); return; }
    armed = "";
    tm.end(kind === "kill");
  }

  function step(delta) {
    const rows = tm.rows;
    if (rows.length === 0) return;
    const i = rows.findIndex(r => r.key === tm.selected);
    const next = Math.max(0, Math.min(rows.length - 1, i < 0 ? 0 : i + delta));
    tm.selected = rows[next].key;
    list.positionViewAtIndex(next, ListView.Contain);
  }

  function focusSearch() { search.input.forceActiveFocus(); }

  // a column title: a click sorts by `key` (none: not sortable)
  component Title: KitText {
    property string key: ""
    property string label: ""
    readonly property bool active: key !== "" && TaskManagerService.sortBy === key
    text: (active ? "▾ " : "") + label
    color: active ? Theme.foreground0 : Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.weight: active ? Font.ExtraBold : Font.DemiBold
    font.letterSpacing: 1

    MouseArea {
      anchors.fill: parent
      enabled: parent.key !== ""
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: TaskManagerService.setSort(parent.key)
    }
  }

  Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }

  // column widths; the name takes what is left
  readonly property int colUser: 110
  readonly property int colCount: 80
  readonly property int colCpu: 70
  readonly property int colMem: 90

  // ---- top: header, meters, column titles ----
  Column {
    id: head
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    spacing: Theme.gapGroup

    KitHeader {
      icon: "activity"
      title: "Task Manager"
      subtitle: root.tm.rows.length + (root.tm.group ? " PROGRAMS · " : " SHOWN · ") + root.tm.procs.length
        + " PROCESSES · EVERY " + root.tm.refreshMs / 1000 + "S"

      KitInput {
        id: search
        width: 240
        placeholder: "search"
        text: root.tm.query
        onTextEdited: root.tm.query = text
      }
    }

    KitLine {}

    // CPU, memory, GPU and network over the last two minutes: a sparkline each,
    // its own scale; the label shows now, or the hovered moment
    Row {
      width: parent.width
      spacing: 20

      Repeater {
        model: [
          { label: "CPU", values: root.tm.cpuHistory, ceiling: 100, fmt: v => Math.round(v) + "%", load: true },
          { label: "MEMORY", values: root.tm.memHistory, ceiling: 100, load: true,
            fmt: v => Theme.shortSize(v / 100 * root.tm.memTotal) },
          { label: "GPU · " + root.tm.gpuName, values: root.tm.gpuHistory, ceiling: 100, fmt: v => Math.round(v) + "%", load: true },
          { label: "NET /S", values: root.tm.rxHistory, values2: root.tm.txHistory, ceiling: 0, floor: 65536,
            fmt: (v, u) => "↓ " + root.rate(v) + "  ↑ " + root.rate(u ?? 0) }
        ]

        Column {
          id: tile

          required property var modelData
          readonly property int at: graph.hoverIndex >= 0 ? graph.hoverIndex : modelData.values.length - 1
          readonly property real now: modelData.values[at] ?? 0

          width: (parent.width - 3 * parent.spacing) / 4
          spacing: Theme.gapMedium

          KitLabel {
            width: parent.width
            text: tile.modelData.label
            value: tile.modelData.values.length === 0 ? "--"
                 : tile.modelData.fmt(tile.now, (tile.modelData.values2 ?? [])[tile.at])
                   + (graph.hoverIndex >= 0 ? " · " + Math.round((tile.modelData.values.length - 1 - graph.hoverIndex)
                                                               * root.tm.refreshMs / 1000) + "s ago" : "")
            valueColor: tile.modelData.load ? Theme.loadColor(tile.now) : Theme.foreground2
          }

          LoadGraph {
            id: graph
            width: parent.width
            height: 44
            values: tile.modelData.values
            values2: tile.modelData.values2 ?? []
            ceiling: tile.modelData.ceiling
            floor: tile.modelData.floor ?? 1
            slots: root.tm.historyLength
            tint: tile.modelData.load ? Theme.loadColor(tile.now) : Theme.foreground0
          }
        }
      }
    }

    KitLine {}

    // column titles: a click sorts by it (name A–Z, the rest largest first)
    Item {
      width: parent.width
      height: 18

      Title { x: 10; key: "name"; label: root.tm.group ? "PROGRAM" : "PROCESS" }
      Title { x: parent.width - root.colMem - root.colCpu - root.colCount - root.colUser; label: "USER" }
      Title {
        x: parent.width - root.colMem - root.colCpu - root.colCount
        width: root.colCount - 10
        horizontalAlignment: Text.AlignRight
        label: root.tm.group ? "PROCS" : "PID"
      }
      Title { x: parent.width - root.colMem - root.colCpu; width: root.colCpu - 10; horizontalAlignment: Text.AlignRight; key: "cpu"; label: "CPU" }
      Title { x: parent.width - root.colMem; width: root.colMem - 10; horizontalAlignment: Text.AlignRight; key: "mem"; label: "MEMORY" }
    }
  }

  // ---- table ----
  ListView {
    id: list
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top
              leftMargin: 24; rightMargin: 24; topMargin: 6; bottomMargin: 6 }
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    model: root.tm.rows

    delegate: Rectangle {
      id: row

      required property var modelData

      readonly property bool active: modelData.key === root.tm.selected

      width: list.width
      height: 30
      color: active ? Theme.background3 : rowArea.containsMouse ? Theme.background1 : "transparent"

      KitText {
        anchors { left: parent.left; leftMargin: 10; right: userText.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: row.modelData.name
        elide: Text.ElideRight
        font.weight: row.active ? Font.ExtraBold : Font.DemiBold
      }

      KitText {
        id: userText
        x: parent.width - root.colMem - root.colCpu - root.colCount - root.colUser
        width: root.colUser - 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.user
        elide: Text.ElideRight
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        x: parent.width - root.colMem - root.colCpu - root.colCount
        width: root.colCount - 10
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.tm.group ? String(row.modelData.count) : String(row.modelData.pids[0])
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        x: parent.width - root.colMem - root.colCpu
        width: root.colCpu - 10
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: row.modelData.cpu.toFixed(1) + "%"
        color: row.modelData.cpu >= 1 ? Theme.loadColor(row.modelData.cpu) : Theme.foreground2
      }

      KitText {
        x: parent.width - root.colMem
        width: root.colMem - 10
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: Theme.shortSize(row.modelData.mem)
        color: Theme.foreground2
      }

      MouseArea {
        id: rowArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: { root.tm.selected = row.modelData.key; root.armed = ""; root.forceActiveFocus(); }
      }
    }
  }

  KitText {
    anchors.centerIn: list
    visible: root.tm.rows.length === 0
    text: root.tm.procs.length === 0 ? "Reading processes…" : "Nothing matches."
    color: Theme.muted
  }

  // ---- foot: the selected row and its actions ----
  Column {
    id: foot
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.windowPadding; bottomMargin: Theme.windowPadding }
    spacing: 12

    KitLine {}

    Item {
      width: parent.width
      height: endButton.height

      Column {
        anchors { left: parent.left; right: buttons.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapTight

        KitText {
          width: parent.width
          elide: Text.ElideRight
          text: root.tm.selectedRow ? root.tm.selectedRow.name : "Nothing selected"
          color: root.tm.selectedRow ? Theme.foreground0 : Theme.muted
          font.weight: Font.ExtraBold
        }

        KitText {
          width: parent.width
          elide: Text.ElideRight
          visible: text !== ""
          text: root.tm.error !== "" && root.tm.status === "error" ? root.tm.error
              : root.tm.selectedRow ? (root.tm.selectedRow.count > 1 ? root.tm.selectedRow.count + " processes · " : "pid " + root.tm.selectedRow.pids[0] + " · ")
                                     + root.tm.selectedRow.threads + " threads · " + (root.tm.selectedRow.cmd || "kernel thread")
              : "↑ ↓ to select · Delete ends · Shift+Delete kills"
          color: root.tm.status === "error" ? Theme.red : Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }

      Row {
        id: buttons
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: Theme.gapSmall

        KitButton {
          id: endButton
          icon: root.armed === "end" ? "check" : "x"
          text: root.armed === "end" ? "Sure?" : "End"
          selected: root.armed === "end"
          busy: root.tm.busy
          disabled: !root.tm.selectedRow
          onClicked: root.act("end")
        }

        KitButton {
          icon: root.armed === "kill" ? "check" : "zap"
          iconTint: Theme.red
          text: root.armed === "kill" ? "Sure?" : "Kill"
          selected: root.armed === "kill"
          disabled: !root.tm.selectedRow || root.tm.busy
          onClicked: root.act("kill")
        }
      }
    }
  }

  // ---- keys ----
  Shortcut { sequences: ["Up"]; onActivated: root.step(-1) }
  Shortcut { sequences: ["Down"]; onActivated: root.step(1) }
  Shortcut { sequences: ["PgUp"]; onActivated: root.step(-10) }
  Shortcut { sequences: ["PgDown"]; onActivated: root.step(10) }
  Shortcut { sequences: ["Delete"]; onActivated: root.act("end") }
  Shortcut { sequences: ["Shift+Delete"]; onActivated: root.act("kill") }
  Shortcut { sequences: [StandardKey.Find, "/"]; onActivated: root.focusSearch() }
}
