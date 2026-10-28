import QtQuick
import qs.apps.shellmanager
import qs.config
import qs.kit

// Wallpaper: the theme's colour, a picture per theme (and per monitor), or a colour of
// your own. It was Appearance's third tab; its keys are the same.
Column {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "image"
  readonly property string title: "Wallpaper"
  readonly property string description: "What is behind the windows."
  readonly property string subtitle: ShellSettings.wallpaperMode === "image" ? "PICTURE" : ShellSettings.wallpaperMode === "custom" ? "YOUR COLOUR" : "THE THEME'S COLOUR"
  readonly property var jumps: []

  readonly property var resetKeys: ["wallpaperMode", "wallpaperColor", "wallpaperImages", "wallpaperOutputs"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }

  // what the section reads (it was a page of Appearance)
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property bool imageWallpaper: ShellSettings.wallpaperMode === "image"
  readonly property string currentImage: WallpaperService.imageFor(ThemeService.current)
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : Theme.background1
  property string wallpaperOutput: ""
  readonly property string wallpaperRel: WallpaperService.outputsFor(ThemeService.current)[wallpaperOutput] || currentImage

  WallpaperSection { width: parent.width; page: root }

  KitGrouper {}
}
