import QtQuick
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks — a live preview
// beside the theme list (pick one to preview it, Apply to switch),
// wallpaper (the theme's colour or a custom one); the bar's icon style is
// shown here but set on the Bar page.
Column {
  id: root

  // the theme shown in the preview; Apply makes it the active one
  property string selected: ThemeService.current
  property string themeQuery: ""
  readonly property var themeMatches: ThemeService.themes.filter(t => t.toLowerCase().includes(themeQuery.trim().toLowerCase()))

  // arrows step through the matches, previewing each
  function stepTheme(delta) {
    const list = themeMatches;
    if (list.length === 0) return;
    const i = list.indexOf(selected);
    selected = list[Math.max(0, Math.min(list.length - 1, (i < 0 ? 0 : i + delta)))];
  }
  readonly property var palette: ThemeService.palettes[selected] ?? ({})
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : p("background1")
  property string draft: ShellSettings.wallpaperColor
  readonly property bool draftValid: /^#?[0-9a-fA-F]{6}$/.test(draft.trim())

  function p(role) { return palette[role] ?? Theme[role]; }

  function setWallpaper(value) {
    const hex = value.trim().replace(/^#?/, "#").toLowerCase();
    ShellSettings.set("wallpaperColor", hex);
    ShellSettings.set("wallpaperMode", "custom");
    draft = hex;
  }

  spacing: 14

  KitHeader {
    icon: "sun"
    title: "Appearance"
    subtitle: (ThemeService.current || "—").toUpperCase()
      + (root.customWallpaper ? " · CUSTOM WALLPAPER" : " · THEME WALLPAPER")
      + (ShellSettings.solidIcons ? " · SOLID ICONS" : " · OUTLINE ICONS")
  }

  KitLine {}

  // preview on the left, the theme list on the right
  Row {
    width: parent.width
    spacing: 14

    // ---- preview -----------------------------------------------------------------
    // the bar and a popup over the wallpaper, in the selected theme's colours
    Rectangle {
      width: parent.width - themeList.width - 14
      height: themeList.height
      color: root.wallpaper
      border.width: Theme.frameWidth
      border.color: root.p("gray")

      Behavior on color { ColorAnimation { duration: 200 } }

      Rectangle {
        id: previewBar
        x: Theme.frameWidth
        y: Theme.frameWidth
        width: parent.width - 2 * Theme.frameWidth
        height: 26
        color: root.p("background0")

        Row {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 6

          Repeater {
            model: 4
            Rectangle {
              required property int index
              width: 8
              height: 8
              color: index === 0 ? root.p("foreground0") : root.p("muted")
            }
          }
        }

        KitText {
          anchors.centerIn: parent
          text: "14:32"
          color: root.p("foreground0")
          font.pixelSize: Theme.fontSize - 2
          font.weight: Font.ExtraBold
        }

        Row {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 8

          // each module in an active state, tinted the way the bar tints it
          Repeater {
            model: [["sun", "orange"], ["volume-x", "red"], ["wifi", "green"], ["shield", "green"],
                    ["battery", "green"], ["bell", "gray"]]

            KitIcon {
              required property var modelData
              name: modelData[0]
              tint: root.p(modelData[1])
              solid: ShellSettings.solidIcons
              size: 14
            }
          }
        }
      }

      // a popup hanging under the bar, in the kit style
      Rectangle {
        anchors { right: parent.right; rightMargin: 40 }
        y: previewBar.y + previewBar.height + 6
        width: 150
        height: 62
        color: root.p("background0")
        border.width: Theme.frameWidth
        border.color: root.p("frame")

        Column {
          x: 10
          y: 10
          width: parent.width - 20
          spacing: 7

          Rectangle { width: parent.width * 0.5; height: 4; color: root.p("foreground0") }
          Rectangle { width: parent.width * 0.7; height: 3; color: root.p("muted") }
          Rectangle { width: parent.width; height: 1; color: root.p("background3") }
          Rectangle {
            width: parent.width
            height: 3
            color: root.p("background3")
            Rectangle { width: parent.width * 0.65; height: parent.height; color: root.p("green") }
          }
        }
      }
    }

    // ---- theme -------------------------------------------------------------------
    Column {
      id: themeList
      width: 190
      height: 240                 // the preview matches it; buttons meet its bottom
      spacing: 8

      KitLabel {
        width: parent.width
        text: "THEME"
        value: String(ThemeService.themes.length)
      }

      KitInput {
        width: parent.width
        placeholder: "search"
        text: root.themeQuery
        // typing previews the first match, arrows move, Enter applies
        onTextEdited: {
          root.themeQuery = text;
          if (root.themeMatches.length > 0 && !root.themeMatches.includes(root.selected))
            root.selected = root.themeMatches[0];
        }
        onAccepted: if (root.selected !== ThemeService.current) ThemeService.apply(root.selected)
        Keys.onDownPressed: root.stepTheme(1)
        Keys.onUpPressed: root.stepTheme(-1)
      }

      // the theme list, framed like an open select
      Rectangle {
        width: parent.width
        height: themeList.height - y - themeButtons.height - themeList.spacing
        color: "transparent"
        border.width: Theme.frameWidth
        border.color: Theme.gray

        // scrolls inside the frame when the themes outgrow it
        Flickable {
          anchors { fill: parent; margins: Theme.frameWidth }
          contentHeight: options.implicitHeight
          interactive: contentHeight > height
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: options
            width: parent.width

            Repeater {
              model: root.themeMatches

              Rectangle {
                id: item

                required property string modelData

                readonly property bool active: modelData === root.selected
                readonly property var colors: ThemeService.palettes[modelData] ?? ({})

                width: options.width
                height: 32
                color: active ? Theme.background3 : itemArea.containsMouse ? Theme.background1 : "transparent"

                // the theme's own surface, text and accents
                Row {
                  id: swatches
                  anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                  spacing: 0

                  Repeater {
                    model: ["background0", "foreground0", "frame", "green", "blue"]

                    Rectangle {
                      required property string modelData
                      width: 7
                      height: 14
                      color: item.colors[modelData] ?? "transparent"
                    }
                  }
                }

                KitText {
                  anchors {
                    left: swatches.right; leftMargin: 10
                    right: mark.left; rightMargin: 6
                    verticalCenter: parent.verticalCenter
                  }
                  text: item.modelData
                  elide: Text.ElideRight
                  color: item.active || itemArea.containsMouse ? Theme.foreground0 : Theme.foreground2
                  font.weight: item.active ? Font.ExtraBold : Font.DemiBold
                }

                Item {
                  id: mark
                  anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                  width: 14
                  height: 14

                  KitSpinner {
                    anchors.centerIn: parent
                    visible: ThemeService.applying === item.modelData
                  }

                  KitIcon {
                    anchors.centerIn: parent
                    visible: item.modelData === ThemeService.current && ThemeService.applying !== item.modelData
                    name: "check"
                    size: 14
                  }
                }

                MouseArea {
                  id: itemArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: item.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                  onClicked: root.selected = item.modelData
                }
              }
            }
          }
        }
      }
    
      // Apply / Cancel always under the list; live only while previewing
      Row {
        id: themeButtons
        width: parent.width
        spacing: 6

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "x"
          text: "Cancel"
          disabled: root.selected === ThemeService.current || ThemeService.busy
          onClicked: root.selected = ThemeService.current
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "check"
          text: "Apply"
          busy: ThemeService.busy
          disabled: root.selected === ThemeService.current
          onClicked: ThemeService.apply(root.selected)
        }
      }
    }
  }

  KitText {
    width: parent.width
    visible: ThemeService.error !== ""
    text: ThemeService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  KitLine {}

  // ---- wallpaper -------------------------------------------------------------------
  KitLabel {
    text: "WALLPAPER"
    value: String(root.wallpaper).toUpperCase()
  }

  // the first swatch follows the theme; the rest are fixed colours
  Flow {
    width: parent.width
    spacing: 6

    Rectangle {
      readonly property bool active: !root.customWallpaper

      width: themeSwatchText.implicitWidth + 44
      height: 30
      color: Theme.background1
      border.width: active || themeSwatchArea.containsMouse ? 2 : 1
      border.color: active || themeSwatchArea.containsMouse ? Theme.foreground2 : Theme.background3

      KitIcon {
        id: themeSwatchIcon
        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
        name: parent.active ? "check" : "sun"
        size: 13
      }

      KitText {
        id: themeSwatchText
        anchors { left: themeSwatchIcon.right; leftMargin: 7; verticalCenter: parent.verticalCenter }
        text: "Theme"
        font.weight: parent.active ? Font.ExtraBold : Font.DemiBold
        font.pixelSize: Theme.fontSize - 1
      }

      MouseArea {
        id: themeSwatchArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellSettings.set("wallpaperMode", "theme")
      }
    }

    Repeater {
      model: ["#000000", "#111111", "#1d2021", "#282828", "#1e2a2f", "#1f2a1f", "#2a1f1f", "#2a2433", "#30261c"]

      Rectangle {
        id: swatch

        required property color modelData

        readonly property bool active: root.customWallpaper && String(modelData) === String(ShellSettings.wallpaperColor)

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
          onClicked: root.setWallpaper(String(swatch.modelData))
        }
      }
    }
  }

  KitRow {
    label: "Custom colour"
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
      onAccepted: if (root.draftValid) root.setWallpaper(root.draft)
    }
  }
}
