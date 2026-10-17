import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.apps.shellmanager
import qs.bar.island
import qs.components
import qs.config
import qs.kit

// Top bar for one screen. Modules come from BarLayout (three zones, order,
// switched-off ones); separators sit between neighbours of a zone only. The
// Shell button opens the Shell Manager.
//
// Bar › Style island: no strip and no zones — the Island (bar/island) is the
// whole bar and every module opens out of it. The window is clear and as tall
// as the open island; its input mask is the island alone.
PanelWindow {
  id: root

  required property var modelData   // the screen, injected by Variants

  // id -> the module's Component, made for this bar
  readonly property var modules: faces.map

  ModuleFaces { id: faces; bar: root }

  // a module's options in the Shell Manager (a right click on it): an app's
  // bar module on the app's tab, the others on their page under Modules
  function openSettings(id) {
    const app = ShellAppsService.entries.find(a => a.module === id) ?? null;
    const has = app ? !!app.moduleSettings : !!BarLayout.modules.find(p => p.id === id)?.settings;
    if (has) Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "shell", "open",
                                      (app ? "apps" : "modules") + ":" + id]);
  }

  component Zone: Row {
    id: zone

    property string name
    property var modules: ({})

    spacing: Theme.moduleSpacing

    Repeater {
      model: Theme.island ? [] : BarLayout.visibleIn(zone.name, root.modelData.name)

      Row {
        required property string modelData
        required property int index

        spacing: Theme.moduleSpacing

        Separator {
          anchors.verticalCenter: parent.verticalCenter
          visible: index > 0
        }

        // the module; a right click on it opens its options. A pointer handler,
        // not an overlay: hover, the cursor and the wheel stay with the module
        Item {
          anchors.verticalCenter: parent.verticalCenter
          width: slot.width
          height: slot.height

          Loader {
            id: slot
            sourceComponent: zone.modules[modelData] ?? null
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

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  // island style: tall enough for a module's popup opened in the island
  implicitHeight: Theme.island ? Math.round(modelData.height * 0.92) : Theme.barHeight
  // a hidden island (no clock, nothing beside it) leaves the edge to windows
  exclusiveZone: islandItem?.hidden ? 0 : Theme.barEdge
  // while a popup is open, a click into it (a text field) takes the keyboard;
  // otherwise the bar never does
  WlrLayershell.keyboardFocus: PopupManager.current || (islandItem?.grabbing ?? false)
    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  color: Theme.island ? "transparent" : Theme.background0

  mask: Theme.island ? islandMask : null

  Region {
    id: islandMask
    item: root.islandItem && !root.islandItem.hidden ? root.islandItem.shape : null

    Region { item: root.islandItem?.bubble ?? null }
  }

  Zone {
    name: "left"
    modules: root.modules
    anchors { left: parent.left; leftMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
  }

  Zone {
    name: "center"
    modules: root.modules
    anchors.centerIn: parent
  }

  Zone {
    name: "right"
    modules: root.modules
    anchors { right: parent.right; rightMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
  }

  // for BarPopup: popups open under the bar's edge
  readonly property int popupEdge: Theme.barEdge
  readonly property bool atBottom: false

  // island style: the Island; BarPopup opens a module's popup in it
  readonly property Item islandItem: islandLoader.item

  Loader {
    id: islandLoader
    active: Theme.island
    anchors.horizontalCenter: parent.horizontalCenter
    y: Theme.islandTop

    sourceComponent: Island {
      bar: root
      modules: root.modules
      onSettings: id => root.openSettings(id)
    }
  }
}
