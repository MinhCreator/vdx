import QtQuick
import qs.config

// A miniature desktop drawn only in a theme's own colours (`colors`, roles
// from ThemeService): the bar with workspaces and status icons, a terminal
// with a few lines of code, and a popup with a level bar, a selected row and
// a button.
Rectangle {
  id: root

  property var colors: ({})

  function c(role) { return colors[role] ?? "#000000"; }

  color: c("background1")
  clip: true

  // ---- bar -------------------------------------------------------------------
  Rectangle {
    id: bar
    width: parent.width
    height: 12
    color: root.c("background0")

    Row {
      anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
      spacing: 3
      Rectangle { width: 5; height: 5; color: root.c("foreground0") }
      Rectangle { width: 5; height: 5; color: root.c("muted") }
      Rectangle { width: 5; height: 5; color: root.c("muted") }
    }

    Row {
      anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
      spacing: 3
      Rectangle { width: 9; height: 3; color: root.c("foreground0") }
      Rectangle { width: 9; height: 3; color: root.c("green") }
      Rectangle { width: 9; height: 3; color: root.c("green") }
      Rectangle { width: 5; height: 5; color: root.c("foreground0") }
    }
  }

  // ---- terminal window (focused) ---------------------------------------------
  Rectangle {
    x: 5
    y: bar.height + 5
    width: parent.width * 0.5
    height: parent.height - y - 5
    color: root.c("background0")
    border.width: Theme.frameWidth
    border.color: root.c("foreground2")

    Column {
      x: 5
      y: 5
      spacing: 3

      Repeater {
        // prompt, code and output lines: [colour role, width]
        model: [["yellow", 10], ["foreground0", 34], ["blue", 22], ["foreground0", 28],
                ["green", 18], ["red", 14], ["muted", 30]]

        Rectangle {
          required property var modelData
          width: modelData[1]
          height: 2
          color: root.c(modelData[0])
        }
      }
    }
  }

  // ---- popup -------------------------------------------------------------------
  Rectangle {
    anchors { right: parent.right; rightMargin: 5 }
    y: bar.height + 2
    width: parent.width * 0.4
    height: parent.height - y - 9
    color: root.c("background0")
    border.width: Theme.frameWidth
    border.color: root.c("frame")

    Column {
      x: 4
      y: 5
      width: parent.width - 8
      spacing: 4

      Rectangle { width: parent.width * 0.6; height: 3; color: root.c("foreground0") }
      Rectangle { width: parent.width * 0.4; height: 2; color: root.c("muted") }

      // level bar
      Rectangle {
        width: parent.width
        height: 2
        color: root.c("background3")
        Rectangle { width: parent.width * 0.65; height: parent.height; color: root.c("green") }
      }

      // selected row
      Rectangle {
        width: parent.width
        height: 7
        color: root.c("background3")
        Rectangle { x: 3; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.5; height: 2; color: root.c("foreground0") }
      }

      // button
      Rectangle {
        width: parent.width * 0.55
        height: 7
        color: "transparent"
        border.width: Theme.frameWidth
        border.color: root.c("gray")
      }
    }
  }
}
