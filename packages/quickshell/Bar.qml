import QtQuick
import Quickshell

// One top bar per screen (background: Theme.background0, height 34).
// Left / center / right — same module order and spacing (2px) as waybar's
// 00-global.jsonc, so the bar is a true 1:1 mirror.

PanelWindow {
  id: root

  // Variants injects `modelData` via QQmlComponent::createWithInitialProperties,
  // so it must be a required property (set at creation time).
  required property var modelData
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
    Media {}
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

    Brightness {}
    Separator {}
    Audio {}
    Separator {}
    Wifi { bar: root }
    Separator {}
    Mihomo { bar: root }
    Separator {}
    Battery {}
    Separator {}
    Language {}
  }
}