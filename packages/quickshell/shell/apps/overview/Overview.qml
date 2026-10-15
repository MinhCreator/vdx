import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.kit

// Every workspace at once, like Niri's overview (Super+Tab): the screen dims,
// each workspace of the focused monitor is a small copy of it with its
// windows where they stand. A click on a window focuses it, on a workspace
// goes there; a window dragged onto another workspace moves there. Escape,
// Super+Tab again or a click on the dimmed screen closes.
PanelWindow {
  id: root

  property bool open: false
  readonly property var monitor: Hyprland.focusedMonitor
  readonly property real mw: (monitor?.width ?? 1920) / (monitor?.scale ?? 1)
  readonly property real mh: (monitor?.height ?? 1080) / (monitor?.scale ?? 1)
  // the monitor's workspaces, and an empty one after the last
  readonly property var spaces: {
    const ids = Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === root.monitor).map(w => w.id).sort((a, b) => a - b);
    const next = ids.length > 0 ? ids[ids.length - 1] + 1 : 1;
    return ids.concat([next]);
  }
  readonly property int cols: Math.min(spaces.length, 3)
  readonly property real scale: Math.min(0.26, (width - 160 - (cols - 1) * 24) / cols / mw)

  function addr(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address; }
  function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", lua]); }
  function goTo(id) { open = false; hypr("hl.dispatch(hl.dsp.focus({ workspace = " + id + " }))"); }
  function focus(t) { open = false; hypr("hl.dispatch(hl.dsp.focus({ window = \"address:" + addr(t) + "\" }))"); }
  function moveTo(t, id) { hypr("hl.dispatch(hl.dsp.window.move({ workspace = " + id + ", window = \"address:" + addr(t) + "\", follow = false }))"); }

  onOpenChanged: if (open) { Hyprland.refreshToplevels(); grid.forceActiveFocus(); }

  screen: Quickshell.screens.find(s => s.name === monitor?.name) ?? Quickshell.screens[0]
  visible: open
  anchors { top: true; bottom: true; left: true; right: true }
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "overview"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  IpcHandler {
    target: "overview"
    function toggle(): void { root.open = !root.open; }
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.background0.r, Theme.background0.g, Theme.background0.b, 0.8)

    MouseArea { anchors.fill: parent; onClicked: root.open = false }

    Grid {
      id: grid
      anchors.centerIn: parent
      columns: root.cols
      spacing: 24
      focus: true
      Keys.onEscapePressed: root.open = false

      Repeater {
        model: root.spaces

        Column {
          id: space
          required property int modelData
          readonly property bool current: root.monitor?.activeWorkspace?.id === modelData
          spacing: 6

          KitText {
            text: space.modelData + (space.current ? " · ACTIVE" : "")
            color: space.current ? Theme.foreground0 : Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }

          // the workspace: a small copy of the monitor
          Rectangle {
            id: frame
            width: root.mw * root.scale
            height: root.mh * root.scale
            color: Theme.background1
            border.width: Theme.windowFrameWidth
            border.color: space.current || drop.containsDrag ? Theme.frame : Theme.gray
            clip: true

            MouseArea { anchors.fill: parent; onClicked: root.goTo(space.modelData) }

            DropArea {
              id: drop
              anchors.fill: parent
              onDropped: drag => root.moveTo(drag.source.toplevel, space.modelData)
            }

            Repeater {
              model: Hyprland.toplevels.values.filter(t => t.workspace?.id === space.modelData)

              Rectangle {
                id: win
                required property var modelData
                readonly property var toplevel: modelData
                readonly property var ipc: modelData.lastIpcObject ?? {}
                readonly property real wx: ((ipc.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * root.scale
                readonly property real wy: ((ipc.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * root.scale

                x: wx
                y: wy
                width: (ipc.size?.[0] ?? 0) * root.scale
                height: (ipc.size?.[1] ?? 0) * root.scale
                color: Theme.background2
                border.width: 1
                border.color: hover.containsMouse ? Theme.foreground0 : Theme.gray
                Drag.active: hover.drag.active
                Drag.source: win
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                ScreencopyView {
                  anchors.fill: parent
                  anchors.margins: 1
                  captureSource: root.open ? win.modelData.wayland : null
                  live: false
                }

                MouseArea {
                  id: hover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                  drag.target: win
                  onClicked: root.focus(win.toplevel)
                  onReleased: {
                    if (!drag.active) return;
                    win.Drag.drop();
                    win.x = Qt.binding(() => win.wx);
                    win.y = Qt.binding(() => win.wy);
                  }
                }
              }
            }
          }
        }
      }
    }

    KitText {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 40
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: "click go · drag a window to move it · esc close"
    }
  }
}
