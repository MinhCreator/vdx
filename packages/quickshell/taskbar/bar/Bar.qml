import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.plugins.audio
import qs.plugins.battery
import qs.plugins.brightness
import qs.plugins.clock
import qs.plugins.language
import qs.plugins.music
import qs.plugins.notifications
import qs.plugins.radio
import qs.plugins.mihomo
import qs.plugins.wifi
import qs.plugins.workspaces

// Top bar for one screen: workspaces, music and radio on the left, clock in the
// center, status modules on the right.
PanelWindow {
  id: root

  required property var modelData   // the screen, injected by Variants

  screen: modelData

  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: Theme.barHeight
  exclusiveZone: Theme.barHeight
  color: Theme.background0

  Row {
    id: left
    anchors {
      left: parent.left
      verticalCenter: parent.verticalCenter
    }
    spacing: Theme.moduleSpacing

    Workspaces {}
    Separator {}
    Music { bar: root }
    Separator {}
    Radio { bar: root }
  }

  Clock {
    anchors.centerIn: parent
  }

  Row {
    id: right
    anchors {
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    spacing: Theme.moduleSpacing

    Brightness { bar: root }
    Separator {}
    Audio { bar: root }
    Separator {}
    Wifi { bar: root }
    Separator {}
    Mihomo { bar: root }
    Separator {}
    Battery { bar: root }
    Separator {}
    Language {}
    Separator {}
    Notifications { bar: root }
  }
}