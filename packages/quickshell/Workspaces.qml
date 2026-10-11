import QtQuick
import Quickshell
import Quickshell.Hyprland

// hyprland/workspaces (mirrors waybar's module exactly):
//   format {name}      (gruvbox)  -> shows the workspace name
//   format {icon}      (dune)     -> shows a Nerd Font icon per state
//   disable-scroll, all-outputs, on-click activate, margin-left 20,
//   buttons padded 0 2px, color transition 0.5s ease.
//
// Class mapping (waybar -> Quickshell):
//   waybar .active  (focused workspace)      == modelData.focused
//   waybar .visible (active on any monitor)  == modelData.active
//   waybar .persistent/.empty/.urgent        (no styling in this config)
//
// Colors (workspaces.css): base gray · active/visible/persistent foreground1 ·
//   hover foreground0 · hover(visible/persistent) yellow.

Row {
  id: wsRow
  leftPadding: Theme.edgeMargin
  spacing: 0  // per-button padding (0 2px) lives inside the delegate

  Repeater {
    model: Hyprland.workspaces

    delegate: Item {
      id: wsDelegate
      required property var modelData

      // waybar hides `special` workspaces (show-special defaults to false).
      readonly property bool isSpecial: modelData.name.startsWith("special")
      // waybar strips a leading "name:" selector from named workspaces.
      readonly property string labelName: modelData.name.startsWith("name:")
          ? modelData.name.substring(5)
          : modelData.name

      // waybar classes that get a colour (workspaces.css):
      //   .active (focused)  == modelData.focused
      //   .visible (on any monitor) == modelData.active
      //   .persistent        -- not exposed by Quickshell's Hyprland service
      // A workspace that merely has windows but is neither active nor visible
      // stays gray in waybar, so it is not highlighted here either.
      readonly property bool highlighted: !isSpecial
          && (modelData.focused || modelData.active)

      property bool hovered: false

      visible: !isSpecial
      // GTK button: content width, floored at min-width 16px, then the CSS
      // `padding: 0 2px` adds 4px — matches waybar's ~20px buttons.
      Text {
        id: label
        anchors.centerIn: parent

        text: {
          if (Theme.workspaceFormat === "{icon}") {
            if (modelData.focused && Theme.workspaceIconActive !== "")
              return Theme.workspaceIconActive
            if (Theme.workspaceIconDefault !== "")
              return Theme.workspaceIconDefault
          }
          return wsDelegate.labelName
        }

        color: {
          if (wsDelegate.hovered)
            return wsDelegate.highlighted ? Theme.yellow : Theme.foreground0
          return wsDelegate.highlighted ? Theme.foreground1 : Theme.gray
        }

        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        verticalAlignment: Text.AlignVCenter

        Behavior on color {
          ColorAnimation { duration: 500; easing.type: Easing.OutSine } // transition: 0.5s ease
        }
      }

      // GTK button: content width, floored at min-width 16px, then the CSS
      // `padding: 0 2px` adds 4px — matches waybar's ~20px buttons.
      implicitWidth: Math.max(label.implicitWidth, Theme.workspaceMinWidth) + 4
      implicitHeight: label.implicitHeight

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
        onContainsMouseChanged: wsDelegate.hovered = containsMouse
        onClicked: modelData.activate() // waybar on-click "activate"
      }
    }
  }
}