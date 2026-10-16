import QtQuick
import Qt.labs.folderlistmodel
import qs.config
import qs.kit

// Appearance › WALLPAPER: the theme's colour, a picture per theme from
// ~/.dotfiles/wallpapers or a colour of your own.
Column {
  id: root

  required property Item page               // AppearancePage: the wallpaper shown

  property string imageDraft: ""
  property string draft: ShellSettings.wallpaperColor

  function setWallpaper(value) {
    const hex = value.trim().replace(/^#?/, "#").toLowerCase();
    ShellSettings.set("wallpaperColor", hex);
    ShellSettings.set("wallpaperMode", "custom");
    draft = hex;
  }

  spacing: Theme.gapGroup

  KitLabel {
    id: wallpaperGroup
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

  // ---- custom: a colour of your own ----
  ColourRow {
    visible: page.customWallpaper
    value: root.draft
    onEdited: text => root.draft = text
    onAccepted: colour => root.setWallpaper(colour)
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
}
