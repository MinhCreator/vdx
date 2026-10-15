import QtQuick
import Qt.labs.folderlistmodel
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks — a live preview
// beside the theme list (pick one to preview it, Apply to switch),
// wallpaper (the theme's colour, a custom one or a picture per theme from
// ~/.dotfiles/wallpapers), the system font (the same
// preview-and-apply) and the cursor (applied on click); the bar's icon style
// is shown here but set on the Bar page.
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
  readonly property var themeColors: ThemeService.colors[selected] ?? ({})
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property bool imageWallpaper: ShellSettings.wallpaperMode === "image"
  // the picture of the active theme, and the one the previewed theme would show
  readonly property string currentImage: imageWallpaper ? WallpaperService.imageFor(ThemeService.current) : ""
  readonly property string previewImage: imageWallpaper ? WallpaperService.imageFor(selected) : ""
  property string imageDraft: ""
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : p("background1")
  property string draft: ShellSettings.wallpaperColor
  readonly property bool draftValid: /^#?[0-9a-fA-F]{6}$/.test(draft.trim())

  function p(role) { return themeColors[role] ?? Theme[role]; }

  // the font in the preview; Apply installs it if needed and makes it the system one
  property string fontSelected: FontService.current
  readonly property var fontRow: FontService.fonts.find(f => f.family === fontSelected) ?? null
  readonly property var fontRows: FontService.fonts.map(f => ({ key: f.family, label: f.family.replace(" Nerd Font", ""),
                                                               installed: f.installed, family: f.family }))
  readonly property var cursorRows: CursorService.cursors.map(c => ({ key: c.name, label: c.name, installed: c.installed }))

  function setWallpaper(value) {
    const hex = value.trim().replace(/^#?/, "#").toLowerCase();
    ShellSettings.set("wallpaperColor", hex);
    ShellSettings.set("wallpaperMode", "custom");
    draft = hex;
  }

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "themes",    label: "Themes",    y: themesGroup.y },
    { key: "wallpaper", label: "Wallpaper", y: wallpaperGroup.y },
    { key: "font",      label: "Font",      y: fontGroup.y },
    { key: "cursor",    label: "Cursor",    y: cursorGroup.y }
  ]

  spacing: 14

  KitHeader {
    icon: "sun"
    title: "Appearance"
    subtitle: (ThemeService.current || "—").toUpperCase()
      + (root.currentImage !== "" ? " · IMAGE WALLPAPER"
         : root.customWallpaper ? " · CUSTOM WALLPAPER" : " · THEME WALLPAPER")
      + (ShellSettings.solidIcons ? " · SOLID ICONS" : " · OUTLINE ICONS")
  }

  KitLine {}

  // preview on the left, the theme list on the right
  Row {
    id: themesGroup
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

      // the previewed theme's picture, when it has one
      Image {
        anchors { fill: parent; margins: Theme.frameWidth }
        visible: root.previewImage !== ""
        source: visible ? "file://" + WallpaperService.dir + "/" + root.previewImage : ""
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
        text: "THEMES"
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
    id: wallpaperGroup
    text: "WALLPAPER"
    value: root.currentImage !== "" ? root.currentImage.split("/").pop().toUpperCase()
                                    : String(root.wallpaper).toUpperCase()
  }

  // the first swatch follows the theme; the rest are fixed colours
  Flow {
    width: parent.width
    spacing: 6

    Rectangle {
      readonly property bool active: ShellSettings.wallpaperMode === "theme"
                                     || (root.imageWallpaper && root.currentImage === "")

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

  // pictures: the active theme's folder first, then the shared one
  Flow {
    width: parent.width
    spacing: 6

    Repeater {
      model: FolderListModel {
        folder: "file://" + WallpaperService.dir + "/" + ThemeService.current
        nameFilters: WallpaperService.extensions
        showDirs: false
      }

      WallpaperThumb {
        required property string fileName
        required property string filePath
        source: filePath
        active: root.currentImage === ThemeService.current + "/" + fileName
        onClicked: WallpaperService.choose(ThemeService.current, ThemeService.current + "/" + fileName)
      }
    }

    Repeater {
      model: FolderListModel {
        folder: "file://" + WallpaperService.dir + "/common"
        nameFilters: WallpaperService.extensions
        showDirs: false
      }

      WallpaperThumb {
        required property string fileName
        required property string filePath
        source: filePath
        active: root.currentImage === "common/" + fileName
        onClicked: WallpaperService.choose(ThemeService.current, "common/" + fileName)
      }
    }
  }

  Connections {
    target: WallpaperService
    function onAdded() { root.imageDraft = ""; }
  }

  KitRow {
    label: "Add image"
    hint: "copied into this theme's folder"

    KitInput {
      width: 220
      placeholder: "~/Pictures/wall.jpg"
      text: root.imageDraft
      onTextEdited: root.imageDraft = text
      onAccepted: WallpaperService.add(root.imageDraft, ThemeService.current)
    }

    KitButton {
      icon: "download"
      text: "Add"
      busy: WallpaperService.busy
      disabled: root.imageDraft.trim() === ""
      onClicked: WallpaperService.add(root.imageDraft, ThemeService.current)
    }
  }

  KitText {
    width: parent.width
    visible: WallpaperService.error !== ""
    text: WallpaperService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  KitLine {}

  // ---- font ------------------------------------------------------------------------
  KitLabel {
    id: fontGroup
    text: "FONT"
    value: FontService.current.replace(" Nerd Font", "").toUpperCase()
  }

  // a sample in the selected font beside the list
  Row {
    width: parent.width
    spacing: 14

    Rectangle {
      width: parent.width - fontList.width - 14
      height: fontList.height
      color: "transparent"
      border.width: Theme.frameWidth
      border.color: Theme.gray

      // a font installed after the shell started can't be drawn until it restarts
      readonly property bool drawable: root.fontRow !== null && root.fontRow.installed
                                       && Qt.fontFamilies().includes(root.fontRow.family)

      Column {
        x: 14
        y: 14
        width: parent.width - 28
        spacing: 10
        visible: parent.drawable

        KitText {
          text: "Appearance"
          font.family: root.fontSelected
          font.weight: Font.ExtraBold
          font.pixelSize: Theme.fontSize + 3
        }

        KitText {
          text: "CONNECTED · RULE · 82%"
          color: Theme.muted
          font.family: root.fontSelected
          font.pixelSize: Theme.fontSize - 2
        }

        KitText {
          width: parent.width
          text: "The quick brown fox jumps over the lazy dog."
          wrapMode: Text.WordWrap
          font.family: root.fontSelected
        }

        KitText {
          text: "0123456789 {}[]() => != -> <="
          color: Theme.foreground2
          font.family: root.fontSelected
        }

        KitText {
          text: "iIlL1| oO0 ❯ ~/.dotfiles"
          color: Theme.foreground2
          font.family: root.fontSelected
        }
      }

      KitText {
        anchors.centerIn: parent
        width: parent.width - 40
        visible: !parent.drawable
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: root.fontRow && !root.fontRow.installed
          ? "Not installed yet.\nApply downloads it and restarts the shell."
          : "Installed after the shell started.\nApply restarts the shell to draw it."
      }
    }

    Column {
      id: fontList
      width: 190
      height: 240
      spacing: 8

      PickList {
        width: parent.width
        height: parent.height - fontButtons.height - parent.spacing
        model: root.fontRows
        selected: root.fontSelected
        current: FontService.current
        working: FontService.working
        onPicked: row => root.fontSelected = row.key
      }

      Row {
        id: fontButtons
        width: parent.width
        spacing: 6

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "x"
          text: "Cancel"
          disabled: root.fontSelected === FontService.current || FontService.busy
          onClicked: root.fontSelected = FontService.current
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: root.fontRow && !root.fontRow.installed ? "download" : "check"
          text: "Apply"
          busy: FontService.busy
          disabled: root.fontSelected === FontService.current || root.fontRow === null
          onClicked: FontService.apply(root.fontRow)
        }
      }
    }
  }

  KitText {
    width: parent.width
    visible: FontService.error !== ""
    text: FontService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  KitLine {}

  // ---- cursor ----------------------------------------------------------------------
  KitLabel {
    id: cursorGroup
    text: "CURSOR"
    value: CursorService.current.toUpperCase() + " · " + CursorService.size
  }

  // a click applies it (downloading first when needed)
  PickList {
    width: parent.width
    height: Math.min(6, root.cursorRows.length) * 32 + 2 * Theme.frameWidth
    model: root.cursorRows
    selected: CursorService.working || CursorService.current
    current: CursorService.current
    working: CursorService.working
    onPicked: row => {
      if (row.key !== CursorService.current)
        CursorService.apply(CursorService.cursors.find(c => c.name === row.key), CursorService.size);
    }
  }

  KitRow {
    label: "Size"
    hint: "pixels, at scale 1"

    KitChoices {
      model: [20, 24, 28, 32, 40].map(n => ({ label: String(n), value: n }))
      current: CursorService.size
      onPicked: value => CursorService.setSize(value)
    }
  }

  KitText {
    width: parent.width
    visible: CursorService.error !== ""
    text: CursorService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
