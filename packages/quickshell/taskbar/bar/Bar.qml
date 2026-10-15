import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.kit
import qs.plugins.ai
import qs.plugins.audio
import qs.plugins.battery
import qs.plugins.brightness
import qs.plugins.capture
import qs.plugins.clipboard
import qs.plugins.clock
import qs.plugins.folder
import qs.plugins.language
import qs.plugins.mihomo
import qs.plugins.music
import qs.plugins.notifications
import qs.plugins.sysmon
import qs.plugins.radio
import qs.plugins.wifi
import qs.plugins.workspaces

// Top bar for one screen. Plugins come from BarLayout (three zones, order,
// switched-off ones); separators sit between neighbours of a zone only. The
// Shell button opens the Shell Manager.
PanelWindow {
  id: root

  required property var modelData   // the screen, injected by Variants

  readonly property var modules: ({
    workspaces: workspaces, music: music, radio: radio, clock: clock,
    brightness: brightness, audio: audio, wifi: wifi, mihomo: mihomo,
    battery: battery, language: language, ai: ai, notifications: notifications,
    shell: shell, capture: capture, clipboard: clipboard, sysmon: sysmon, folder: folder
  })

  component Zone: Row {
    id: zone

    property string name
    property var modules: ({})

    spacing: Theme.moduleSpacing

    Repeater {
      model: BarLayout.visibleIn(zone.name, root.modelData.name)

      Row {
        required property string modelData
        required property int index

        spacing: Theme.moduleSpacing

        Separator {
          anchors.verticalCenter: parent.verticalCenter
          visible: index > 0
        }

        Loader {
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: zone.modules[modelData] ?? null
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
  implicitHeight: Theme.barHeight
  exclusiveZone: Theme.barHeight
  color: Theme.background0

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
    id: rightZone
    name: "right"
    modules: root.modules
    anchors { right: parent.right; rightMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
  }

  Component { id: workspaces; Workspaces {} }
  Component { id: music; Music { bar: root } }
  Component { id: radio; Radio { bar: root } }
  Component { id: clock; Clock {} }
  Component { id: brightness; Brightness { bar: root } }
  Component { id: audio; Audio { bar: root } }
  Component { id: wifi; Wifi { bar: root } }
  Component { id: mihomo; Mihomo { bar: root } }
  Component { id: battery; Battery { bar: root } }
  Component { id: language; Language {} }
  Component { id: ai; Ai { bar: root } }
  Component { id: notifications; Notifications { bar: root } }
  Component { id: capture; Capture { bar: root } }
  Component { id: clipboard; Clipboard { bar: root } }
  Component { id: sysmon; Sysmon { bar: root } }
  Component { id: folder; Folder { bar: root; modules: root.modules } }

  // The Shell Manager's button; a plugin of its own so it can move between zones.
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
