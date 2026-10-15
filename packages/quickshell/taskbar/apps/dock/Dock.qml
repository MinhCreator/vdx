import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.kit
import qs.plugins.windows

// The floating mode's dock at the bottom of the focused monitor, like the
// Windows taskbar: minimized windows (Super+N or the title bar's button;
// they wait on special:minimized), a click brings one back. Close and
// maximize are on the windows' title bars (hyprbars, windowmode.lua). Shown only when there is something in it;
// Shell Manager › Windows › Dock turns it off.
PanelWindow {
  id: root

  readonly property var ws: WindowsService
  readonly property bool floating: ws.mode === "floating"
  readonly property var minimized: Hyprland.toplevels.values.filter(t => t.workspace?.name === "special:minimized")

  function addr(t) { return t.address.startsWith("0x") ? t.address : "0x" + t.address; }
  function classOf(t) { return t.lastIpcObject?.class ?? ""; }
  function iconOf(t) {
    const e = DesktopEntries.heuristicLookup(classOf(t));
    return Quickshell.iconPath(e?.icon ?? classOf(t).toLowerCase(), true);   // "" when the theme has none
  }

  screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
  visible: ws.opts.dock && floating && minimized.length > 0
  anchors.bottom: true
  margins.bottom: 8
  implicitWidth: frame.width
  implicitHeight: frame.height
  exclusiveZone: implicitHeight + 8
  color: "transparent"
  WlrLayershell.namespace: "dock"
  WlrLayershell.layer: WlrLayer.Top

  // the class shows only after a refresh of the toplevels' IPC objects
  onMinimizedChanged: Hyprland.refreshToplevels()

  Rectangle {
    id: frame
    width: row.implicitWidth + 16
    height: 44
    color: Theme.background0
    border.width: Theme.windowFrameWidth
    border.color: Theme.frame

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 6

      // minimized windows: the app's icon, its title on hover
      Repeater {
        model: root.minimized

        Rectangle {
          id: app
          required property var modelData

          anchors.verticalCenter: parent.verticalCenter
          width: 32
          height: 32
          color: area.containsMouse ? Theme.background3 : "transparent"
          border.width: area.containsMouse ? 1 : 0
          border.color: Theme.gray

          IconImage {
            id: appIcon
            anchors.centerIn: parent
            implicitSize: 22
            source: root.iconOf(app.modelData)
            visible: source != ""
          }

          KitIcon {
            anchors.centerIn: parent
            visible: !appIcon.visible
            name: "app-window"
            size: 20
          }

          MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.ws.restore(root.addr(app.modelData))
          }

          // the title above the dock while hovered
          PopupWindow {
            visible: area.containsMouse
            anchor.item: app
            anchor.edges: Edges.Top
            anchor.gravity: Edges.Top
            anchor.rect.y: -10
            implicitWidth: tip.implicitWidth + 16
            implicitHeight: tip.implicitHeight + 10
            color: Theme.background0

            Rectangle {
              anchors.fill: parent
              color: "transparent"
              border.width: 1
              border.color: Theme.gray
            }

            KitText {
              id: tip
              anchors.centerIn: parent
              text: app.modelData.title
            }
          }
        }
      }
    }
  }
}
