import QtQuick
import Qt.labs.folderlistmodel
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks — a live preview
// beside the theme list (pick one to preview it, Apply to switch),
// wallpaper (the theme's colour, a custom one or a picture per theme from
// ~/.dotfiles/wallpapers), the system font (the same
// preview-and-apply) and the cursor (applied on click); the icon style for the whole shell.
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

  function p(role) { return themeColors[role] ?? Theme[role]; }

  // the font in the preview; Apply installs it if needed and makes it the system one
  property string fontSelected: FontService.current
  readonly property var fontRow: FontService.fonts.find(f => f.family === fontSelected) ?? null
  readonly property var fontRows: FontService.fonts.map(f => ({ key: f.family, label: f.family.replace(" Nerd Font", ""),
                                                               installed: f.installed, family: f.family }))
  // short names: "Bibata-Modern-Classic" reads "Bibata Classic", "phinger-cursors-dark" "phinger dark"
  function cursorLabel(name) {
    return name.replace(/-/g, " ").replace("Modern ", "").replace(" cursors", "").replace("Original Classic", "Original");
  }
  readonly property var cursorRows: CursorService.cursors.map(c => ({ key: c.name, installed: c.installed, label: cursorLabel(c.name) }))

  // the cursor in the preview and its colour; Apply makes them the system's
  property string cursorSelected: CursorService.base
  property string cursorMode: CursorService.mode
  property string cursorCustom: CursorService.mode === "custom" ? CursorService.fill : "d8a657"
  readonly property var cursorRow: CursorService.cursors.find(c => c.name === cursorSelected) ?? null
  readonly property bool cursorCustomValid: /^[0-9a-f]{6}$/.test(cursorCustom)
  readonly property bool cursorChanged: cursorSelected !== CursorService.base || cursorMode !== CursorService.mode
                                        || (cursorMode === "custom" && cursorCustom !== CursorService.fill)
  // the preview follows the selection (a theme-coloured one, the theme too)
  readonly property string cursorPreviewKey: cursorRow && cursorRow.installed
    ? [cursorSelected, cursorMode, cursorCustomValid ? cursorCustom : "", CursorService.themeColours].join(" ") : ""
  onCursorPreviewKeyChanged: if (cursorPreviewKey !== "" && (cursorMode !== "custom" || cursorCustomValid))
    CursorService.preview(cursorSelected, cursorMode, cursorCustom)

  function resetCursor() {
    cursorSelected = CursorService.base;
    cursorMode = CursorService.mode;
    cursorCustom = CursorService.mode === "custom" ? CursorService.fill : "d8a657";
  }

  function setWallpaper(value) {
    const hex = value.trim().replace(/^#?/, "#").toLowerCase();
    ShellSettings.set("wallpaperColor", hex);
    ShellSettings.set("wallpaperMode", "custom");
    draft = hex;
  }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "sun"
  readonly property string title: "Appearance"
  readonly property string subtitle: (ThemeService.current || "—").toUpperCase()
    + (currentImage !== "" ? " · IMAGE WALLPAPER" : customWallpaper ? " · CUSTOM WALLPAPER" : " · THEME WALLPAPER")
    + (ShellSettings.solidIcons ? " · SOLID ICONS" : " · OUTLINE ICONS")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "themes",    label: "Themes",    y: themesGroup.y },
    { key: "icons",     label: "Icons",     y: iconsGroup.y },
    { key: "wallpaper", label: "Wallpaper", y: wallpaperGroup.y },
    { key: "font",      label: "Font",      y: fontGroup.y },
    { key: "cursor",    label: "Cursor",    y: cursorGroup.y }
  ]

  spacing: 14

  // ---- theme -----------------------------------------------------------------------
  KitLabel {
    id: themesGroup
    text: "THEME"
    value: (ThemeService.current || "—").toUpperCase() + " · " + ThemeService.themes.length + " IN ALL"
  }

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
                    tint: Theme.green
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

  // ---- icons -----------------------------------------------------------------------
  KitLabel {
    id: iconsGroup
    text: "ICONS"
    value: ShellSettings.solidIcons ? "SOLID" : "OUTLINE"
  }

  KitRow {
    wide: true
    label: "Style"
    hint: "everywhere: the bar, popups and windows"

    KitChoices {
      stretch: true
      model: [
        { label: "Outline", value: false },
        { label: "Solid",   value: true }
      ]
      current: ShellSettings.solidIcons
      onPicked: value => ShellSettings.set("solidIcons", value)
    }
  }

  KitLine {}

  // ---- wallpaper -------------------------------------------------------------------
  KitLabel {
    id: wallpaperGroup
    text: "WALLPAPER"
    value: root.currentImage !== "" ? root.currentImage.split("/").pop().toUpperCase()
                                    : String(root.wallpaper).toUpperCase()
  }

  // what fills the screen, like the cursor's colour: the theme's colour, a
  // picture of this theme or a colour of your own; below, only what that needs
  KitRow {
    wide: true
    label: "Source"
    hint: ShellSettings.wallpaperMode === "image" ? "a picture per theme"
        : ShellSettings.wallpaperMode === "custom" ? "one colour for every theme" : "the theme's own colour"

    KitChoices {
      stretch: true
      model: [
        { label: "Theme",  value: "theme" },
        { label: "Image",  value: "image" },
        { label: "Custom", value: "custom" }
      ]
      current: ShellSettings.wallpaperMode
      onPicked: value => ShellSettings.set("wallpaperMode", value)
    }
  }

  // ---- custom: a colour of your own
  ColourRow {
    visible: root.customWallpaper
    value: root.draft
    onEdited: text => root.draft = text
    onAccepted: colour => root.setWallpaper(colour)
  }

  // ---- image: the active theme's folder first, then the shared one
  Flow {
    width: parent.width
    visible: root.imageWallpaper && themePictures.count + commonPictures.count > 0
    spacing: 6

    Repeater {
      model: FolderListModel {
        id: themePictures
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
        id: commonPictures
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

  KitText {
    width: parent.width
    visible: root.imageWallpaper && themePictures.count + commonPictures.count === 0
    text: "No pictures yet — add one below, or put files into wallpapers/" + ThemeService.current + " or wallpapers/common."
    color: Theme.muted
    wrapMode: Text.WordWrap
  }

  Connections {
    target: WallpaperService
    function onAdded() { root.imageDraft = ""; }
  }

  KitRow {
    visible: root.imageWallpaper
    label: "Add image"
    hint: "copied into this theme's folder"
    wide: true

    Row {
      spacing: 8

      KitInput {
        width: parent.width - addImage.width - parent.spacing
        placeholder: "~/Pictures/wall.jpg"
        text: root.imageDraft
        onTextEdited: root.imageDraft = text
        onAccepted: WallpaperService.add(root.imageDraft, ThemeService.current)
      }

      KitButton {
        id: addImage
        icon: "download"
        text: "Add"
        busy: WallpaperService.busy
        disabled: root.imageDraft.trim() === ""
        onClicked: WallpaperService.add(root.imageDraft, ThemeService.current)
      }
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
    value: root.cursorLabel(CursorService.base).toUpperCase() + " · " + CursorService.mode.toUpperCase() + " · " + CursorService.size
  }

  // the main shapes of the selected cursor in the chosen colour, beside the list
  Row {
    width: parent.width
    spacing: 14

    Rectangle {
      width: parent.width - cursorList.width - 14
      height: cursorList.height
      color: Theme.background1
      border.width: Theme.frameWidth
      border.color: Theme.gray

      readonly property bool ready: root.cursorRow !== null && root.cursorRow.installed
                                    && CursorService.shapesKey === CursorService.wantedKey

      Grid {
        anchors.centerIn: parent
        visible: parent.ready
        columns: 4
        columnSpacing: 26
        rowSpacing: 22

        Repeater {
          model: CursorService.shapes

          Image {
            required property var modelData
            width: 40
            height: 40
            source: "file://" + modelData.path + "?" + CursorService.shapesKey
            sourceSize: Qt.size(modelData.width, modelData.height)
            cache: false
            smooth: true
          }
        }
      }

      KitSpinner {
        anchors.centerIn: parent
        visible: root.cursorRow !== null && root.cursorRow.installed && !parent.ready
      }

      KitText {
        anchors.centerIn: parent
        width: parent.width - 40
        visible: root.cursorRow !== null && !root.cursorRow.installed
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: "Not installed yet.\nApply downloads it."
      }
    }

    Column {
      id: cursorList
      width: 190
      height: 240
      spacing: 8

      PickList {
        width: parent.width
        height: parent.height - cursorButtons.height - parent.spacing
        model: root.cursorRows
        selected: root.cursorSelected
        current: CursorService.base
        working: CursorService.working
        onPicked: row => root.cursorSelected = row.key
      }

      Row {
        id: cursorButtons
        width: parent.width
        spacing: 6

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "x"
          text: "Cancel"
          disabled: !root.cursorChanged || CursorService.busy
          onClicked: root.resetCursor()
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: root.cursorRow && !root.cursorRow.installed ? "download" : "check"
          text: "Apply"
          busy: CursorService.busy
          disabled: !root.cursorChanged || root.cursorRow === null
                    || (root.cursorMode === "custom" && !root.cursorCustomValid)
          onClicked: CursorService.apply(root.cursorRow, CursorService.size, root.cursorMode, root.cursorCustom)
        }
      }
    }
  }

  KitRow {
    wide: true
    label: "Colour"
    hint: root.cursorMode === "theme" ? "follows the theme's colours"
        : root.cursorMode === "custom" ? "your colour, outlined to stand out" : "as the cursor theme draws it"

    KitChoices {
      stretch: true
      id: cursorColours
      model: [
        { label: "Original", value: "original" },
        { label: "Theme",    value: "theme" },
        { label: "Custom",   value: "custom" }
      ]
      current: root.cursorMode
      onPicked: value => root.cursorMode = value
    }
  }

  ColourRow {
    visible: root.cursorMode === "custom"
    value: "#" + root.cursorCustom
    onEdited: text => root.cursorCustom = text.trim().replace(/^#/, "").toLowerCase()
    onAccepted: colour => { if (root.cursorRow) CursorService.apply(root.cursorRow, CursorService.size, "custom", colour.slice(1)); }
  }

  KitRow {
    wide: true
    label: "Size"
    hint: "pixels at scale 1, applied at once"

    KitChoices {
      stretch: true
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
