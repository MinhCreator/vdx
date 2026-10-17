import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.apps.shellmanager
import qs.components
import qs.config

// An extra bar (Shell Manager › Bar › BARS) on one screen: a strip along the
// top or bottom edge, or a pill floating there (start, centre or end), with
// its own modules in order. Its popups open away from its edge.
PanelWindow {
  id: root

  required property var modelData                // { screen, config }: config is a BarLayout.bars entry

  readonly property var config: modelData.config
  readonly property bool atBottom: config.edge === "bottom"
  readonly property bool pill: config.shape === "pill"
  readonly property var ids: BarLayout.barModules(config.id)
  readonly property int gap: pill ? Theme.islandTop : 0
  readonly property int band: pill ? Theme.islandHeight : Theme.barHeight

  // for BarPopup: where its popups attach, and its open module's underline
  readonly property int popupEdge: atBottom ? body.y : body.y + body.height
  readonly property int underlineY: atBottom ? body.y : body.y + body.height - 2

  readonly property var modules: faces.map
  ModuleFaces { id: faces; bar: root }

  // a module's options in the Shell Manager (a right click on it), as on the main bar
  function openSettings(id) {
    const app = ShellAppsService.entries.find(a => a.module === id) ?? null;
    const has = app ? !!app.moduleSettings : !!BarLayout.modules.find(p => p.id === id)?.settings;
    if (has) Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "shell", "open",
                                      (app ? "apps" : "modules") + ":" + id]);
  }

  screen: modelData.screen
  anchors { top: !atBottom; bottom: atBottom; left: true; right: true }
  implicitHeight: band + gap
  exclusiveZone: band + gap
  WlrLayershell.namespace: "quickshell-extra-bar"
  WlrLayershell.keyboardFocus: PopupManager.current ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  color: pill ? "transparent" : Theme.background0
  mask: pill ? pillMask : null

  Region { id: pillMask; item: body }

  Component.onCompleted: if (atBottom) PopupManager.setBottomBar(modelData.screen.name, band + gap)
  Component.onDestruction: if (atBottom) PopupManager.setBottomBar(modelData.screen.name, 0)

  // the strip's line on the screen side, the pill's frame
  Rectangle {
    id: body
    readonly property int inset: root.pill ? Theme.gapGroup : Theme.edgeMargin
    x: !root.pill ? 0
       : root.config.align === "start" ? Theme.islandTop * 2
       : root.config.align === "end" ? root.width - width - Theme.islandTop * 2
       : (root.width - width) / 2
    y: root.atBottom ? 0 : root.gap
    width: root.pill ? row.width + 2 * inset : root.width
    height: root.band
    radius: root.pill ? Math.min(height / 2, Theme.islandRadius) : 0
    color: Theme.background0
    border.width: root.pill ? Theme.islandFrameWidth : 0
    border.color: Theme.background2

    Row {
      id: row
      anchors.verticalCenter: parent.verticalCenter
      x: root.pill || root.config.align === "start" ? body.inset
         : root.config.align === "end" ? body.width - width - body.inset
         : (body.width - width) / 2
      spacing: Theme.moduleSpacing

      Repeater {
        model: root.ids

        Row {
          required property string modelData
          required property int index

          spacing: Theme.moduleSpacing

          Separator {
            anchors.verticalCenter: parent.verticalCenter
            visible: index > 0
          }

          Item {
            anchors.verticalCenter: parent.verticalCenter
            width: slot.width
            height: slot.height

            Loader {
              id: slot
              sourceComponent: root.modules[modelData] ?? null
            }

            TapHandler {
              acceptedButtons: Qt.RightButton
              enabled: ShellSettings.barRightSettings
              onTapped: root.openSettings(modelData)
            }
          }
        }
      }
    }
  }
}
