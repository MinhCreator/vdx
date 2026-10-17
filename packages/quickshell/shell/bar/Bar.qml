import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.apps.shellmanager
import qs.bar.island
import qs.components
import qs.config
import qs.kit
import qs.modules.ai
import qs.modules.audio
import qs.modules.battery
import qs.modules.brightness
import qs.modules.capture
import qs.modules.chat
import qs.modules.cleaner
import qs.modules.clipboard
import qs.modules.packages
import qs.modules.display
import qs.modules.equalizer
import qs.modules.virustotal
import qs.modules.clock
import qs.modules.folder
import qs.modules.language
import qs.modules.mihomo
import qs.modules.music
import qs.modules.notifications
import qs.modules.sysmon
import qs.modules.taskmanager
import qs.modules.themes
import qs.modules.radio
import qs.modules.wifi
import qs.modules.windows
import qs.modules.workspaces

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

  readonly property var modules: ({
    workspaces: workspaces, music: music, equalizer: equalizer, themes: themes, radio: radio, clock: clock,
    brightness: brightness, audio: audio, wifi: wifi, mihomo: mihomo,
    battery: battery, language: language, ai: ai, notifications: notifications,
    shell: shell, capture: capture, clipboard: clipboard, sysmon: sysmon, taskmanager: taskmanager, cleaner: cleaner, virustotal: virustotal, packages: packages, display: display, windows: windows, chat: chat, folder: folder
  })

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

  Component { id: workspaces; Workspaces {} }
  Component { id: music; Music { bar: root } }
  Component { id: radio; Radio { bar: root } }
  Component { id: clock; Clock {} }
  Component { id: equalizer; Equalizer { bar: root } }
  Component { id: themes; Themes { bar: root } }
  Component { id: brightness; Brightness { bar: root } }
  Component { id: audio; Audio { bar: root } }
  Component { id: wifi; Wifi { bar: root } }
  Component { id: mihomo; Mihomo { bar: root } }
  Component { id: battery; Battery { bar: root } }
  Component { id: language; Language {} }
  Component { id: ai; Ai { bar: root } }
  Component { id: notifications; Notifications { bar: root } }
  Component { id: capture; Capture { bar: root } }
  Component { id: clipboard; ClipboardBar { bar: root } }
  Component { id: sysmon; Sysmon { bar: root } }
  Component { id: taskmanager; TaskManagerBar { bar: root } }
  Component { id: cleaner; CleanerBar { bar: root } }
  Component { id: virustotal; VirusTotalBar { bar: root } }
  Component { id: packages; PackagesBar { bar: root } }
  Component { id: display; DisplayBar { bar: root } }
  Component { id: windows; Windows { bar: root } }
  Component { id: chat; Chat { bar: root } }
  Component { id: folder; Folder { bar: root; modules: root.modules } }

  // The Shell Manager's button; a module of its own so it can move between zones.
  Component {
    id: shell

    KitBarItem {
      id: shellButton
      icon: "sliders"

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellSettings.managerOpen = !ShellSettings.managerOpen
      }
    }
  }
}
