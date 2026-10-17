import QtQuick
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks — the theme with a
// live preview, the wallpaper, the system font and the cursor, one section each
// (ThemeSection … CursorSection), then the STYLE group: icons, corners and
// controls (IconsSection, CornersSection, ControlsSection) under one label.
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
    + (ShellSettings.solidIcons ? " · SOLID ICONS" : " · OUTLINE ICONS")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  readonly property var jumps: [
    { key: "themes",    label: "Themes",    y: themeSection.y },
    { key: "wallpaper", label: "Wallpaper", y: wallpaperSection.y },
    { key: "font",      label: "Font",      y: fontSection.y },
    { key: "cursor",    label: "Cursor",    y: cursorSection.y },
    { key: "style",     label: "Style",     y: styleLabel.y }
  ]

  spacing: Theme.gapGroup

  ThemeSection { id: themeSection; width: parent.width; page: root }
  KitLine {}
  WallpaperSection { id: wallpaperSection; width: parent.width; page: root }
  KitLine {}
  FontSection { id: fontSection; width: parent.width }
  KitLine {}
  CursorSection { id: cursorSection; width: parent.width }
  KitLine {}

  // the STYLE group: one label, then the three sections' rows, spaced like one group
  KitLabel {
    id: styleLabel
    width: parent.width
    text: "STYLE"
    value: [
      ShellSettings.solidIcons ? "SOLID" : "OUTLINE",
      ShellSettings.corners === "round" ? "ROUND " + ShellSettings.cornerRadius + " PX" : "SHARP",
      ShellSettings.material ? "MATERIAL" : "OUTLINED"
    ].join(" · ")
  }

  IconsSection { id: iconsSection; width: parent.width }
  CornersSection { id: cornersSection; width: parent.width }
  ControlsSection { id: controlsSection; width: parent.width }
}
