import QtQuick
import qs.config
import qs.kit

// Appearance › THEME: a live preview (the bar and a popup over the wallpaper,
// in the previewed theme's colours) beside the theme list; Apply switches.
Column {
  id: root

  required property Item page               // AppearancePage: the previewed theme

  property string themeQuery: ""
  readonly property var themeMatches: ThemeService.themes.filter(t => t.toLowerCase().includes(themeQuery.trim().toLowerCase()))

  // arrows step through the matches, previewing each
  function stepTheme(delta) {
    const list = themeMatches;
    if (list.length === 0) return;
    const i = list.indexOf(page.selected);
    page.selected = list[Math.max(0, Math.min(list.length - 1, (i < 0 ? 0 : i + delta)))];
  }

  spacing: 14

  KitLabel {
    id: themesGroup
    text: "THEME"
    value: (ThemeService.current || "—").toUpperCase() + " · " + ThemeService.themes.length + " IN ALL"
  }

  // preview on the left, the theme list on the right
  Row {
    width: parent.width
    spacing: 14

    // ---- preview ----
    // the bar and a popup over the wallpaper, in the selected theme's colours
    Rectangle {
      width: parent.width - themeList.width - 14
      height: themeList.height
      color: page.wallpaper
      border.width: Theme.frameWidth
      border.color: page.p("gray")

      Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.normal } }

      // the previewed theme's picture, when it has one
      Image {
        anchors { fill: parent; margins: Theme.frameWidth }
        visible: page.previewImage !== ""
        source: visible ? "file://" + WallpaperService.dir + "/" + page.previewImage : ""
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      Rectangle {
        id: previewBar
        x: Theme.frameWidth
        y: Theme.frameWidth
        width: parent.width - 2 * Theme.frameWidth
        height: 26
        color: page.p("background0")

        Row {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 6

          Repeater {
            model: 4
            Rectangle {
              required property int index
              width: 8
              height: 8
              color: index === 0 ? page.p("foreground0") : page.p("muted")
            }
          }
        }

        KitText {
          anchors.centerIn: parent
          text: "14:32"
          color: page.p("foreground0")
          font.pixelSize: Theme.fontSize - 2
          font.weight: Font.ExtraBold
        }

        Row {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 8

          // each module in an active state, tinted the way the bar tints it
          Repeater {
            model: [["sun", "orange"], ["volume-x", "red"], ["wifi", "green"], ["shield", "green"],
                    ["battery-full", "green"], ["bell", "gray"]]

            KitIcon {
              required property var modelData
              name: modelData[0]
              tint: page.p(modelData[1])
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
        color: page.p("background0")
        border.width: Theme.frameWidth
        border.color: page.p("frame")

        Column {
          x: 10
          y: 10
          width: parent.width - 20
          spacing: 7

          Rectangle { width: parent.width * 0.5; height: 4; color: page.p("foreground0") }
          Rectangle { width: parent.width * 0.7; height: 3; color: page.p("muted") }
          Rectangle { width: parent.width; height: 1; color: page.p("background3") }
          Rectangle {
            width: parent.width
            height: 3
            color: page.p("background3")
            Rectangle { width: parent.width * 0.65; height: parent.height; color: page.p("green") }
          }
        }
      }
    }

    // ---- theme ----
    Column {
      id: themeList
      width: 190
      height: 240                 // the preview matches it; buttons meet its bottom
      spacing: 8

      KitInput {
        width: parent.width
        placeholder: "search"
        text: root.themeQuery
        // typing previews the first match, arrows move, Enter applies
        onTextEdited: {
          root.themeQuery = text;
          if (root.themeMatches.length > 0 && !root.themeMatches.includes(page.selected))
            page.selected = root.themeMatches[0];
        }
        onAccepted: if (page.selected !== ThemeService.current) ThemeService.apply(page.selected)
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

        WheelGuard { flick: themeFlick; z: 1 }

        // scrolls inside the frame when the themes outgrow it
        Flickable {
          id: themeFlick
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

                readonly property bool active: modelData === page.selected
                readonly property var colors: ThemeService.colors[modelData] ?? ({})

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
                    tint: Theme.green
                    size: 14
                  }
                }

                MouseArea {
                  id: itemArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: item.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                  onClicked: page.selected = item.modelData
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
          disabled: page.selected === ThemeService.current || ThemeService.busy
          onClicked: page.selected = ThemeService.current
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "check"
          text: "Apply"
          busy: ThemeService.busy
          disabled: page.selected === ThemeService.current
          onClicked: ThemeService.apply(page.selected)
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
}
