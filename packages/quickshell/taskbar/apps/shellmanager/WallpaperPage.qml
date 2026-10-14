import QtQuick
import qs.config
import qs.kit

// Wallpaper: a solid colour — the theme's own (background1) or a custom one,
// picked from swatches or typed as hex. The preview shows it under a bar.
Column {
  id: root

  readonly property bool custom: ShellSettings.wallpaperMode === "custom"
  readonly property color current: custom ? ShellSettings.wallpaperColor : Theme.background1
  property string draft: ShellSettings.wallpaperColor
  readonly property bool draftValid: /^#?[0-9a-fA-F]{6}$/.test(draft.trim())

  function setColor(value) {
    const hex = value.trim().replace(/^#?/, "#").toLowerCase();
    ShellSettings.set("wallpaperColor", hex);
    ShellSettings.set("wallpaperMode", "custom");
    draft = hex;
  }

  spacing: 14

  KitHeader {
    icon: "monitor"
    title: "Wallpaper"
    subtitle: "SOLID · " + String(root.current).toUpperCase() + (root.custom ? " · CUSTOM" : " · FROM THEME")
  }

  KitLine {}

  // ---- preview ---------------------------------------------------------------
  Rectangle {
    width: parent.width
    height: Math.round(width * 0.36)
    color: root.current
    border.width: Theme.frameWidth
    border.color: Theme.gray

    Behavior on color { ColorAnimation { duration: 200 } }

    // a strip of bar over it, for context
    Rectangle {
      x: Theme.frameWidth
      y: Theme.frameWidth
      width: parent.width - 2 * Theme.frameWidth
      height: 14
      color: Theme.background0

      Row {
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 4
        Repeater { model: 3; Rectangle { width: 6; height: 6; color: index === 0 ? Theme.foreground0 : Theme.muted } }
      }
    }
  }

  // ---- source ----------------------------------------------------------------
  KitLabel { text: "SOURCE" }

  KitChoices {
    model: [
      { label: "Theme colour", value: "theme",  icon: "sun" },
      { label: "Custom",       value: "custom", icon: "sliders" }
    ]
    current: ShellSettings.wallpaperMode
    onPicked: value => ShellSettings.set("wallpaperMode", value)
  }

  // ---- custom colour -----------------------------------------------------------
  Column {
    width: parent.width
    visible: root.custom
    spacing: 10

    KitLabel { text: "COLOUR" }

    // the active palette's surfaces and neutrals, then a few deep tints
    Flow {
      width: parent.width
      spacing: 6

      Repeater {
        model: [Theme.background0, Theme.background1, Theme.background2, Theme.background3, Theme.dim, Theme.gray,
                "#000000", "#111111", "#1d2021", "#282828", "#1e2a2f", "#1f2a1f", "#2a1f1f", "#2a2433", "#30261c"]

        Rectangle {
          id: swatch

          required property color modelData

          readonly property bool active: String(modelData) === String(ShellSettings.wallpaperColor)

          width: 30
          height: 30
          color: modelData
          border.width: active || swatchArea.containsMouse ? 2 : 1
          border.color: active || swatchArea.containsMouse ? Theme.foreground2 : Theme.background3

          MouseArea {
            id: swatchArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setColor(String(swatch.modelData))
          }
        }
      }
    }

    KitRow {
      label: "Hex"
      hint: root.draftValid ? "press Enter to apply" : "six hex digits, like #32302f"

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        color: root.draftValid ? root.draft.trim().replace(/^#?/, "#") : "transparent"
        border.width: 1
        border.color: Theme.gray
      }

      KitInput {
        width: 150
        placeholder: "#32302f"
        text: root.draft
        onTextEdited: root.draft = text
        onAccepted: if (root.draftValid) root.setColor(root.draft)
      }
    }
  }
}
