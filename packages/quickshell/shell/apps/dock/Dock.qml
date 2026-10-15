import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.kit
import qs.plugins.windows

// The floating mode's taskbar along the bottom of the focused monitor, like
// Windows: the system menu's button, then every window of the active
// workspace — open ones and those minimized from it (Super+N, Super+↓ or the
// title bar's button; they wait on special:minimized, tagged min<workspace>
// by windowmode.lua). A click on the active window minimizes it, on another
// one brings it forward. Shell Manager › Windows › Taskbar turns it off.
PanelWindow {
  id: root

  readonly property var ws: WindowsService
  readonly property int wsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
  readonly property var active: Hyprland.activeToplevel
  readonly property var windows: Hyprland.toplevels.values.filter(t =>
    t.workspace?.id === wsId || (t.workspace?.name === "special:minimized" && root.tagsOf(t).includes("min" + wsId)))

  function addr(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address; }
  function classOf(t) { return t.lastIpcObject?.class ?? ""; }
  function tagsOf(t) { return (t.lastIpcObject?.tags ?? []).map(s => s.replace(/\*$/, "")); }
  function minimized(t) { return t.workspace?.name === "special:minimized"; }
  function iconOf(t) {
    const e = DesktopEntries.heuristicLookup(classOf(t));
    return Quickshell.iconPath(e?.icon ?? classOf(t).toLowerCase(), true);   // "" when the theme has none
  }
  function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }
  function clicked(t) {
    if (minimized(t)) ws.restore(addr(t));
    else if (t === active) ws.minimize(addr(t));
    else hypr("hl.dispatch(hl.dsp.focus({ window = \"address:" + addr(t) + "\" }))");
  }

  screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
  visible: ws.opts.dock && ws.mode === "floating"
  anchors { bottom: true; left: true; right: true }
  implicitHeight: Theme.barHeight + 4
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

  // a hairline above, like the frame of the bar's popups
  Rectangle { width: parent.width; height: 1; color: Theme.gray }

  Row {
    x: 8
    y: 4
    height: parent.height - 6
    spacing: 4

    // the system menu, like Start
    Rectangle {
      width: height
      height: parent.height
      color: start.containsMouse ? Theme.background3 : "transparent"

      KitIcon { anchors.centerIn: parent; name: "grid"; size: 18 }

      MouseArea {
        id: start
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "launcher", "toggle"])
      }
    }

    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 18; color: Theme.gray }

    Repeater {
      model: root.windows

      // a window: its app's icon and title; the active one filled and bold,
      // a minimized one dim
      Rectangle {
        id: item
        required property var modelData
        readonly property bool current: modelData === root.active && !root.minimized(modelData)
        readonly property bool down: root.minimized(modelData)

        width: Math.min(220, 40 + label.implicitWidth)
        height: parent.height
        color: current ? Theme.background3 : area.containsMouse ? Theme.background1 : "transparent"

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
          source: root.iconOf(item.modelData)
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
          text: item.modelData.title || root.classOf(item.modelData)
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
          onClicked: mouse => mouse.button === Qt.MiddleButton ? root.ws.close(root.addr(item.modelData)) : root.clicked(item.modelData)
        }
      }
    }
  }
}
