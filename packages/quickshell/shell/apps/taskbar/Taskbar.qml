import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.kit
import qs.modules.windows

// The floating mode's taskbar along the bottom of the focused monitor, like
// Windows: every window of the active workspace — open ones and those
// minimized from it (Super+J, or a click here; they wait on special:minimized,
// tagged min<workspace> by windowmode.lua). A click minimizes an open window
// and brings a minimized one back; the pointer stays where it is. Shell
// Manager › Windows › Floating › Taskbar turns it off.
PanelWindow {
  id: root

  readonly property var ws: WindowsService
  readonly property int wsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
  readonly property var active: Hyprland.activeToplevel

  // what each window's workspace was, kept by address: a minimized window's
  // tag comes with the IPC refresh, a moment late, and while it lacks the tag
  // the window dropped out of the row and came back at its end. seq keeps the
  // order the windows came in. A plain object: writing it notifies nothing.
  readonly property var cache: ({ origin: {}, seq: {}, count: 0 })

  readonly property var windows: {
    const origin = {}, seq = {};
    const out = [];
    for (const t of Hyprland.toplevels.values) {
      const a = Hypr.addr(t);
      const tag = Hypr.tagsOf(t).find(s => /^min\d+$/.test(s));
      const from = Hypr.minimized(t) ? (root.cache.origin[a] ?? (tag ? +tag.slice(3) : undefined)) : t.workspace?.id;
      origin[a] = from;
      seq[a] = root.cache.seq[a] ?? ++root.cache.count;
      if (from === root.wsId) out.push(t);
    }
    root.cache.origin = origin;
    root.cache.seq = seq;
    return out.sort((x, y) => seq[Hypr.addr(x)] - seq[Hypr.addr(y)]);
  }

  function clicked(t) {
    if (Hypr.minimized(t)) ws.restore(Hypr.addr(t));
    else ws.minimize(Hypr.addr(t));
  }

  screen: Hypr.focusedScreen
  visible: ws.opts.taskbar && ws.mode === "floating"
  anchors { bottom: true; left: true; right: true }
  implicitHeight: Theme.barHeight
  exclusiveZone: implicitHeight
  color: Theme.background0
  WlrLayershell.namespace: "taskbar"
  WlrLayershell.layer: WlrLayer.Top

  // the class and the tags come with the toplevels' IPC objects: refreshed
  // after Hyprland's events, at most every 150 ms
  Connections {
    target: Hyprland
    function onRawEvent() { if (root.visible && !refresh.running) refresh.start(); }
  }
  Timer { id: refresh; interval: 150; onTriggered: Hyprland.refreshToplevels() }

  // keyed by address: a refresh keeps each window's item instead of rebuilding
  // the row (a new array rebuilt them all, and they flickered)
  ScriptModel {
    id: windowModel
    values: root.windows
    objectProp: "address"
  }

  Row {
    x: 8
    height: parent.height
    spacing: Theme.gapHair

    Repeater {
      model: windowModel

      // a window: its app's icon and title; the active one filled and bold,
      // a minimized one dim
      Rectangle {
        radius: Theme.radiusControl
        id: item
        required property var modelData
        readonly property bool current: modelData === root.active && !Hypr.minimized(modelData)
        readonly property bool down: Hypr.minimized(modelData)

        width: Math.min(220, 40 + label.implicitWidth)
        height: parent.height
        color: current ? Theme.background3 : area.containsMouse ? Theme.background1 : Theme.clear
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        // the active one's mark along the bottom, as under an open bar module
        Rectangle {
          visible: item.current
          anchors.bottom: parent.bottom
          width: parent.width
          height: 2
          color: Theme.foreground0
        }

        IconImage {
          id: appIcon
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          implicitSize: 18
          source: Hypr.iconOf(item.modelData)
          visible: source != ""
          opacity: item.down ? 0.5 : 1
        }

        KitIcon {
          x: 8
          anchors.verticalCenter: parent.verticalCenter
          visible: !appIcon.visible
          name: "app-window"
          size: 18
          tint: item.down ? Theme.muted : Theme.foreground0
        }

        KitText {
          id: label
          x: 32
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, 220 - 40)
          elide: Text.ElideRight
          text: item.modelData.title || Hypr.classOf(item.modelData)
          color: item.down ? Theme.muted : Theme.foreground0
          font.weight: item.current ? Font.ExtraBold : Theme.fontWeight
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton
          // middle click closes, as in a browser's tabs
          onClicked: mouse => mouse.button === Qt.MiddleButton ? root.ws.close(Hypr.addr(item.modelData)) : root.clicked(item.modelData)
        }
      }
    }
  }
}
