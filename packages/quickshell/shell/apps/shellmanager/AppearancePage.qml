import QtQuick
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks, top to bottom —
// the theme with a live preview, the accent, the wallpaper, the font and the
// cursor (ThemeSection … CursorSection), then SHAPE (corners, icons) and
// CONTROLS. Each group has its caps label here or in its section.
KitColumn {
  id: root

  // the theme shown in the preview; Apply makes it the active one
  property string selected: ThemeService.current
  readonly property var themeColors: ThemeService.colors[selected] ?? ({})
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property bool imageWallpaper: ShellSettings.wallpaperMode === "image"
  // the picture of the active theme, and the one the previewed theme would show
  readonly property string currentImage: imageWallpaper ? WallpaperService.imageFor(ThemeService.current) : ""
  readonly property string previewImage: imageWallpaper ? WallpaperService.imageFor(selected) : ""
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : p("background1")

  function p(role) { return themeColors[role] ?? Theme[role]; }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "sun"
  readonly property string title: "Appearance"
  readonly property string subtitle: (ThemeService.current || "—").toUpperCase()
    + (currentImage !== "" ? " · IMAGE WALLPAPER" : customWallpaper ? " · CUSTOM WALLPAPER" : " · THEME WALLPAPER")
    + (ShellSettings.accent ? " · ACCENT " + ShellSettings.accentStops.map(n => n === "theme" ? "THEME" : n.toUpperCase()).join(" → ") : "")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "themes",    label: "Themes",    y: themeSection.y },
    { key: "accent",    label: "Accent",    y: accentSection.y },
    { key: "wallpaper", label: "Wallpaper", y: wallpaperSection.y },
    { key: "font",      label: "Text",      y: fontSection.y },
    { key: "cursor",    label: "Cursor",    y: cursorSection.y },
    { key: "shape",     label: "Shape",     y: shapeLabel.y },
    { key: "controls",  label: "Controls",  y: controlsLabel.y }
  ]

  spacing: Theme.gapGroup

  ThemeSection { id: themeSection; width: parent.width; page: root }
  KitLine {}
  AccentSection { id: accentSection; width: parent.width }
  KitLine {}
  WallpaperSection { id: wallpaperSection; width: parent.width; page: root }
  KitLine {}
  FontSection { id: fontSection; width: parent.width }
  KitLine {}
  CursorSection { id: cursorSection; width: parent.width }
  KitLine {}

  KitLabel {
    id: shapeLabel
    width: parent.width
    text: "SHAPE"
    value: (ShellSettings.corners === "round" ? "ROUND " + ShellSettings.cornerRadius + " PX" : "SHARP")
      + " · " + (ShellSettings.solidIcons ? "SOLID" : "OUTLINE")
  }

  CornersSection { id: cornersSection; width: parent.width }
  IconsSection { id: iconsSection; width: parent.width }
  KitLine {}

  KitLabel {
    id: controlsLabel
    width: parent.width
    text: "CONTROLS"
    value: (ShellSettings.material ? "MATERIAL" : "OUTLINED")
      + " · " + (ShellSettings.passwordDots ? "DOTS" : "SQUARES")
  }

  ControlsSection { id: controlsSection; width: parent.width }
}
