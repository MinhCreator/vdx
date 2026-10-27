import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.apps.files
import qs.config
import qs.kit
import "../../kit/colour.js" as Colour

// Appearance › WALLPAPER: the theme's colour, a picture per theme (and per
// monitor, with more than one) from the repo's wallpapers or the user's own
// folder, or a colour of your own (the accent's field and picker).
KitColumn {
  id: root

  required property Item page               // AppearancePage: the wallpaper shown

  // the monitor a picked picture is for: "" every monitor
  property string output: page.wallpaperOutput
  onOutputChanged: page.wallpaperOutput = output
  readonly property var screens: Quickshell.screens.map(s => s.name)
  readonly property var overrides: WallpaperService.outputsFor(ThemeService.current)
  // the picture shown where the next pick goes
  readonly property string shown: output !== "" && overrides[output] ? overrides[output] : page.currentImage
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
    value: root.shown !== "" && page.imageWallpaper ? root.shown.split("/").pop()
                                    : String(page.wallpaper).toUpperCase()
  }

  // what fills the screen, like the cursor's colour: the theme's colour, a
  // picture of this theme or a colour of your own; below, only what that needs
  KitRow {
    wide: true
    label: "Source"
    hint: ShellSettings.wallpaperMode === "image" ? "A picture per theme"
        : ShellSettings.wallpaperMode === "custom" ? "One colour for every theme" : "The theme's own colour"

    KitSegments {
      model: [
        { label: "Theme",  value: "theme" },
        { label: "Image",  value: "image" },
        { label: "Colour", value: "custom" }
      ]
      current: ShellSettings.wallpaperMode
      onPicked: value => ShellSettings.set("wallpaperMode", value)
    }
  }

  // ---- custom: a colour of your own, typed (live, Enter not needed) or picked from the palette ----
  KitColourPicker {
    visible: page.customWallpaper
    width: parent.width
    palette: root.palette
    picked: root.pickedName
    colours: name => [root.colourOf(name), root.colourOf(name)]
    onChosen: name => ShellSettings.set("wallpaperColor", root.hexOf(name))
  }

  // ---- image: the active theme's folder first, the user's, then the shared one ----
  // with more than one monitor, a pick goes to every monitor or to one
  KitSelect {
    visible: page.imageWallpaper && root.screens.length > 1
    label: "Monitor"
    hint: root.output === "" ? "Drops each monitor's own" : root.overrides[root.output] ? "Its own picture" : "The theme's picture"
    model: [{ label: "Every monitor", value: "" }].concat(root.screens.map(n => ({ label: n, value: n })))
    current: root.screens.includes(root.output) ? root.output : ""
    onPicked: value => root.output = value
  }

  Flow {
    width: parent.width
    visible: page.imageWallpaper && WallpaperService.pictures.length > 0
    property bool kitUnboxed: true
    spacing: Theme.gapSmall

    Repeater {
      model: WallpaperService.pictures

      WallpaperThumb {
        required property var modelData
        width: (parent.width - 2 * Theme.gapSmall) / 3
        height: width * 9 / 16
        source: modelData.path
        active: root.shown === modelData.rel
        onClicked: WallpaperService.choose(ThemeService.current, modelData.rel, root.output)
      }
    }
  }

  KitText {
    width: parent.width
    visible: page.imageWallpaper && WallpaperService.pictures.length === 0
    text: "No pictures yet — add one below, or put files into wallpapers/" + ThemeService.current + " or wallpapers/common."
    color: Theme.muted
    wrapMode: Text.WordWrap
  }

  // the picker is the way in: the picked picture is added at once
  KitRow {
    visible: page.imageWallpaper
    label: "Add image"
    hint: "Kept outside the repo"

    KitButton {
      icon: "download"
      text: "Choose…"
      busy: WallpaperService.busy
      disabled: WallpaperService.busy
      onClicked: FilesService.pick("Pick the wallpaper", FilesService.home + "/Pictures", false, ["image/*"],
                                   p => { if (p !== "") WallpaperService.add(p, ThemeService.current, root.output); })
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

  KitGrouper {}
}
