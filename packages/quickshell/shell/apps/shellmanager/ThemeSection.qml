import QtQuick
import qs.bar
import qs.config
import qs.kit
import Quickshell.Widgets

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

  spacing: Theme.gapGroup

  KitLabel {
    id: themesGroup
    text: "THEME"
    value: (ThemeService.current || "—").toUpperCase() + " · " + ThemeService.themes.length + " IN ALL"
  }

  // the bar's modules as the shell draws them (size, rules), in the previewed colours
  component BarIcons: Row {
    id: icons
    property var ids: []
    // a rule (custom or automatic) between two modules when the bar draws them
    readonly property var shown: {
      if (!ShellSettings.barSeparators) return ids;
      const out = [];
      ids.forEach((id, i) => {
        if (i > 0 && !BarLayout.isSeparator(id) && !BarLayout.isSeparator(ids[i - 1])) out.push("sep-");
        out.push(id);
      });
      return out;
    }

    spacing: Theme.gapLoose

    Repeater {
      model: icons.shown

      Item {
        id: slot
        required property string modelData
        readonly property bool rule: BarLayout.isSeparator(modelData)

        anchors.verticalCenter: parent.verticalCenter
        width: rule ? 2 + 2 * Theme.separatorMargin : Theme.iconSmall + ShellSettings.barIconGrow
        height: Theme.iconSmall + ShellSettings.barIconGrow

        Rectangle {
          visible: slot.rule
          anchors.centerIn: parent
          width: 2
          height: parent.height
          radius: Theme.pill(width)
          color: page.p("foreground2")
        }

        KitIcon {
          visible: !slot.rule
          anchors.centerIn: parent
          name: BarLayout.icon(slot.modelData)
          tint: page.p("foreground2")
          size: Theme.iconSmall + ShellSettings.barIconGrow
        }
      }
    }
  }

  // preview on the left, the theme list on the right
  Row {
    width: parent.width
    spacing: Theme.gapGroup

    // ---- preview ----

    // the bar and a popup over the wallpaper, in the selected theme's colours
    ClippingRectangle {
      radius: Theme.radiusCard
      width: parent.width - themeList.width - 14
      height: themeList.height
      color: page.wallpaper
      // a screen in a frame either way: its bar shares the page's colour
      border.width: Theme.windowFrameWidth
      border.color: page.p(Theme.material ? "background2" : "gray")

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

      // the bar as the shell draws it (BarPreview): a strip on the top edge, or in
      // island style a pill floating over the wallpaper; its surface follows the design
      Rectangle {
        id: previewBar
        readonly property bool island: Theme.island
        x: island ? 10 : Theme.frameWidth
        y: island ? 8 : Theme.frameWidth
        width: parent.width - (island ? 20 : 2 * Theme.frameWidth)
        height: 26
        radius: island ? Math.min(height / 2, Theme.islandRadius) : 0
        color: page.p(Theme.material ? "background0" : "background1")

        BarIcons {
          anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          ids: Theme.island ? BarLayout.islandIn("start", BarLayout.mainScreen()) : BarLayout.visibleIn("left", BarLayout.mainScreen())
        }

        KitText {
          anchors.centerIn: parent
          text: "14:32"
          color: page.p("foreground0")
          font.pixelSize: Theme.fontSize - 2
          font.weight: Font.ExtraBold
        }

        BarIcons {
          anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          ids: Theme.island ? BarLayout.islandIn("end", BarLayout.mainScreen()) : BarLayout.visibleIn("right", BarLayout.mainScreen())
        }
      }

      // a popup hanging under the bar, in the kit style
      Rectangle {
        radius: Theme.radiusSurface
        anchors { right: parent.right; rightMargin: 40 }
        y: previewBar.y + previewBar.height + 6
        width: 150
        height: 62
        color: page.p("background0")
        border.width: Theme.windowFrameWidth      // a popup's frame, as the shell draws it
        border.color: page.p(Theme.material ? "background2" : "frame")

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
      width: Theme.sideWidth
      height: 240                 // the preview matches it; buttons meet its bottom
      spacing: Theme.gapMedium

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
        radius: Theme.radiusControl
        width: parent.width
        height: themeList.height - y - themeButtons.height - themeList.spacing
        color: Theme.controlFill
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
                radius: Theme.radiusControl
                id: item

                required property string modelData

                readonly property bool active: modelData === page.selected
                readonly property var colors: ThemeService.colors[modelData] ?? ({})

                width: options.width
                height: 32
                color: active ? Theme.background3 : itemArea.containsMouse ? Theme.controlHover : Theme.clear
                Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

                // the theme's own surface, text and accents
                Row {
                  id: swatches
                  anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                  spacing: 0

                  Repeater {
                    model: ["background0", "foreground0", "frame", "green", "blue"]

                    Rectangle {
                      radius: Theme.pill(width)
                      required property string modelData
                      width: 7
                      height: 14
                      color: item.colors[modelData] ?? "transparent"
                    }
                  }
                }

                KitText {
                  anchors {
                    left: swatches.right; leftMargin: Theme.gapLoose
                    right: mark.left; rightMargin: Theme.gapSmall
                    verticalCenter: parent.verticalCenter
                  }
                  text: item.modelData
                  elide: Text.ElideRight
                  color: item.active || itemArea.containsMouse ? Theme.foreground0 : Theme.foreground2
                  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
                  font.weight: item.active ? Font.ExtraBold : Font.DemiBold
                }

                Item {
                  id: mark
                  anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
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
                    size: Theme.iconSmall
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
        spacing: Theme.gapSmall

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
