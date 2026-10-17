import QtQuick
import qs.bar
import qs.config
import qs.kit
import Quickshell
import Quickshell.Widgets

// Appearance › THEME: a live preview (the bar and a specimen window over the
// wallpaper, in the previewed theme's colours) beside the theme list; Apply switches.
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

  // preview on the left, the theme list on the right
  Row {
    width: parent.width
    spacing: Theme.gapGroup

    // ---- preview ----

    ThemePreview {
      width: parent.width - themeList.width - Theme.gapGroup
      height: themeList.height
      page: root.page
    }

    // ---- theme ----
    Column {
      id: themeList
      width: Theme.sideWidth
      height: 268                // the preview matches it; buttons meet its bottom
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

                // the theme in its own colours: its surface and frame, "Aa" in its
                // text, its hues as dots (light or dark, contrast, palette at a glance)
                Rectangle {
                  id: swatches
                  anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                  width: sample.implicitWidth + dots.implicitWidth + 3 * Theme.gapHair + 2
                  height: 20
                  radius: Theme.radiusControl
                  color: item.colors.background0 ?? Theme.clear
                  border.width: 1                     // the theme's own frame: a dark surface shows on the list
                  border.color: item.colors.background3 ?? Theme.clear

                  KitText {
                    id: sample
                    anchors { left: parent.left; leftMargin: Theme.gapHair + 1; verticalCenter: parent.verticalCenter }
                    text: "Aa"
                    color: item.colors.foreground0 ?? Theme.foreground0
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.ExtraBold
                  }

                  Row {
                    id: dots
                    anchors { right: parent.right; rightMargin: Theme.gapHair + 1; verticalCenter: parent.verticalCenter }
                    spacing: 2

                    Repeater {
                      model: ["red", "green", "blue", "purple"]

                      Rectangle {
                        required property string modelData
                        width: 5
                        height: 5
                        radius: Theme.pill(height)
                        color: item.colors[modelData] ?? Theme.clear
                      }
                    }
                  }
                }

                KitText {
                  anchors {
                    left: swatches.right; leftMargin: Theme.gapMedium
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
