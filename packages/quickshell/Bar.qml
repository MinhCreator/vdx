import QtQuick
import Quickshell

// One top bar per screen (background: #202020, height 34).
// Left / center / right — same module order as waybar's 00-global.jsonc.

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

  Row {
    id: center
    anchors.centerIn: parent
    spacing: Theme.moduleSpacing

    Clock {}
  }

  Row {
    id: right
    anchors {
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    spacing: Theme.moduleSpacing + Theme.rightGroupSpacingExtra

    Brightness {}
    Separator {}
    Audio {}
    Separator {}
    Network {}
    Separator {}
    Mihomo { bar: root }
    Separator {}
    Battery {}
    Separator {}
    Language {}
  }
}
