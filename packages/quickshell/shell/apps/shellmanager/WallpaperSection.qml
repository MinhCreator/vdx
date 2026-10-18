import QtQuick
import Qt.labs.folderlistmodel
import qs.apps.files
import qs.config
import qs.kit
import "../../kit/colour.js" as Colour

// Appearance › WALLPAPER: the theme's colour, a picture per theme from
// ~/.dotfiles/wallpapers or a colour of your own (the accent's field and picker).
KitColumn {
  id: root

  required property Item page               // AppearancePage: the wallpaper shown

  property string imageDraft: ""
  property bool pickerOpen: false

  // the custom colour's palette: the dots of the picker, as the accent's
  readonly property var palette: ["red", "orange", "yellow", "green", "aqua", "blue", "purple"]
  function colourOf(name) { return Theme.accentColour(name); }
  function hexOf(name) { return Colour.hexOfColour(colourOf(name)); }
  // the palette name in use, "" for a colour of your own
  readonly property string pickedName: palette.filter(n => hexOf(n) === ShellSettings.wallpaperColor)[0] ?? ""

  spacing: Theme.gapGroup

  KitLabel {
    text: "WALLPAPER"
    value: page.currentImage !== "" ? page.currentImage.split("/").pop().toUpperCase()
                                    : String(page.wallpaper).toUpperCase()
  }

  // what fills the screen, like the cursor's colour: the theme's colour, a
  // picture of this theme or a colour of your own; below, only what that needs
  KitRow {
    wide: true
    label: "Source"
    hint: ShellSettings.wallpaperMode === "image" ? "A picture per theme"
        : ShellSettings.wallpaperMode === "custom" ? "One colour for every theme" : "The theme's own colour"

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

  // ---- custom: a colour of your own, typed (live, Enter not needed) or picked from the palette ----
  KitRow {
    visible: page.customWallpaper
    wide: true
    label: "Colour"
    hint: root.pickedName !== "" ? root.pickedName.charAt(0).toUpperCase() + root.pickedName.slice(1) : "Custom"

    KitColourField {
      value: ShellSettings.wallpaperColor
      placeholder: "#32302f"
      live: true
      open: root.pickerOpen
      onAccepted: colour => ShellSettings.set("wallpaperColor", colour)
      onChipClicked: root.pickerOpen = !root.pickerOpen
    }
  }

  KitColourPicker {
    visible: page.customWallpaper && root.pickerOpen
    width: parent.width
    colour: ShellSettings.wallpaperColor
    palette: root.palette
    picked: root.pickedName
    colours: name => [root.colourOf(name), root.colourOf(name)]
    onMoved: hex => ShellSettings.set("wallpaperColor", hex)
    onReleased: hex => ShellSettings.set("wallpaperColor", hex)
    onChosen: name => ShellSettings.set("wallpaperColor", root.hexOf(name))
  }

  // ---- image: the active theme's folder first, then the shared one ----
  Flow {
    width: parent.width
    visible: page.imageWallpaper && themePictures.count + commonPictures.count > 0
    spacing: Theme.gapSmall

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
        active: page.currentImage === ThemeService.current + "/" + fileName
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
        active: page.currentImage === "common/" + fileName
        onClicked: WallpaperService.choose(ThemeService.current, "common/" + fileName)
      }
    }
  }

  KitText {
    width: parent.width
    visible: page.imageWallpaper && themePictures.count + commonPictures.count === 0
    text: "No pictures yet — add one below, or put files into wallpapers/" + ThemeService.current + " or wallpapers/common."
    color: Theme.muted
    wrapMode: Text.WordWrap
  }

  Connections {
    target: WallpaperService
    function onAdded() { root.imageDraft = ""; }
  }

  KitRow {
    visible: page.imageWallpaper
    label: "Add image"
    hint: "Copied into this theme's folder"
    wide: true

    Row {
      spacing: Theme.gapMedium

      KitInput {
        width: parent.width - chooseImage.width - addImage.width - 2 * parent.spacing
        placeholder: "~/Pictures/wall.jpg"
        text: root.imageDraft
        onTextEdited: root.imageDraft = text
        onAccepted: WallpaperService.add(root.imageDraft, ThemeService.current)
      }

      KitButton {
        id: chooseImage
        icon: "folder"
        text: "Choose…"
        disabled: WallpaperService.busy
        onClicked: FilesService.pick("Pick the wallpaper", FilesService.home + "/Pictures", false, ["image/*"],
                                     p => { if (p !== "") root.imageDraft = p; })
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
}
