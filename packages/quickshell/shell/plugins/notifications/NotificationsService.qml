pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Notification history on top of mako (scripts/notifications.sh). mako keeps
// only a short, untimed history, so this service records every notification it
// sees, with the time, in the shell's state dir. "Unseen" = arrived after the
// popup was last opened.
Singleton {
  id: root

  readonly property var items: state.items     // newest first: [{key, app, summary, body, urgency, time}]
  readonly property int unseen: items.filter(n => n.time > state.seenAt).length

  property real openedSeenAt: 0                // seenAt before the popup opened: marks fresh rows

  function popupShown() {
    openedSeenAt = state.seenAt;
    state.seenAt = Date.now();
  }

  function clear() {
    state.items = [];
    state.seenAt = Date.now();
  }

  function isFresh(item) { return item.time > openedSeenAt; }

  // Adds mako's notifications newer than the last one taken (mako ids grow;
  // a lower top id means mako restarted and numbering began again), so a
  // cleared history stays clear. The first run after a fresh state only
  // records what is there, without counting it as unseen.
  function ingest(list) {
    const top = list.reduce((m, n) => Math.max(m, n.id), 0);
    if (!state.tracked) {                      // state from before id tracking
      state.lastId = top;
      state.tracked = true;
      state.initialized = true;
      return;
    }
    if (top < state.lastId) state.lastId = 0;
    const known = new Set(state.items.map(n => n.key));
    const now = Date.now();
    const fresh = list
      .filter(n => n.id > state.lastId)
      .map(n => ({ key: n.id + "|" + n.summary + "|" + n.body, app: n.app, summary: n.summary,
                   body: n.body, urgency: n.urgency, time: now }))
      .filter(n => !known.has(n.key));
    state.lastId = Math.max(state.lastId, top);
    if (fresh.length > 0)
      state.items = fresh.concat(state.items).slice(0, Theme.notificationsMax);
    if (!state.initialized) {
      state.seenAt = now;
      state.initialized = true;
    }
  }

  function refresh() {
    if (!listProc.running) listProc.running = true;
  }

  // mako registers a notification a moment after the Notify call.
  Timer {
    id: refreshDelay
    interval: 300
    onTriggered: root.refresh()
  }

  Timer {
    id: saveDelay
    interval: 500
    onTriggered: stateFile.writeAdapter()
  }

  Process {
    id: listProc
    command: ["bash", Theme.notificationsScript, "--list"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.ingest(JSON.parse(text)); } catch (e) {}
      }
    }
  }

  // Every Notify call on the session bus, whoever shows it.
  Process {
    id: monitorProc
    command: ["dbus-monitor", "--session", "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"]
    running: true
    stdout: SplitParser {
      onRead: line => { if (line.startsWith("method call")) refreshDelay.restart(); }
    }
    onExited: monitorRestart.start()
  }

  Timer {
    id: monitorRestart
    interval: 2000
    onTriggered: monitorProc.running = true
  }

  FileView {
    id: stateFile
    path: Quickshell.statePath("notifications.json")
    printErrors: false
    onAdapterUpdated: saveDelay.restart()
    onLoaded: root.refresh()
    onLoadFailed: {
      writeAdapter();
      root.refresh();
    }

    JsonAdapter {
      id: state
      property var items: []
      property real seenAt: 0
      property bool initialized: false
      property int lastId: 0
      property bool tracked: false
    }
  }
}
