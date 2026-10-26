import QtQuick
import qs.config
import qs.kit

// Appearance: everything that changes how the desktop looks, top to bottom —
// STYLE (the language, controls, shape, the theme's mode and a sample), the accent,
// the wallpaper (the theme, the font and the cursor have pages of their own), ICONS. Each group has its caps
// label here or in its section.
KitColumn {
  id: root

  // the theme shown in the preview; Apply makes it the active one
  property string selected: ThemeService.current
  readonly property var themeColors: ThemeService.colors[selected] ?? ({})
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property bool imageWallpaper: ShellSettings.wallpaperMode === "image"
  // the picture of the active theme
  readonly property string currentImage: imageWallpaper ? WallpaperService.imageFor(ThemeService.current) : ""
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : p("background1")

  function p(role) { return themeColors[role] ?? Theme[role]; }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "sun"
  readonly property string title: "Appearance"
  readonly property string subtitle: (ThemeService.current || "—").toUpperCase()
    + (currentImage !== "" ? " · IMAGE WALLPAPER" : customWallpaper ? " · CUSTOM WALLPAPER" : " · THEME WALLPAPER")
    + (ShellSettings.accent ? " · ACCENT " + ShellSettings.accentStops.map(n => n === "theme" ? "THEME" : n.toUpperCase()).join(" → ") : "")

  // groups for the Shell Manager's sidebar: a click scrolls to `y`
  // the header's Reset: these ShellSettings keys back to their defaults (the theme, the font and the cursor are on their pages)
  readonly property var resetKeys: ["solidIcons", "wallpaperMode", "wallpaperColor", "wallpaperImages", "wallpaperOutputs", "corners", "cornerRadius", "cornerSplit", "cornerRadii", "material", "visualStyle", "accent", "accentStops", "accentGradient", "accentCustom", "accentWhere", "passwordDots"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }

  readonly property var jumps: [
    { key: "style",     label: "Style",     y: styleLabel.y },
    { key: "accent",    label: "Accent",    y: accentSection.y },
    { key: "wallpaper", label: "Wallpaper", y: wallpaperSection.y },
    { key: "icons",     label: "Icons",     y: shapeLabel.y }
  ]

  spacing: Theme.gapGroup

  // the three axes of the look (Theme › design language), then the theme's mode, then a
  // sample of real controls in the result
  KitLabel {
    id: styleLabel
    width: parent.width
    text: "STYLE"
    value: (ShellSettings.visualStyle === "strict" ? "STRICT" : "MATERIAL")
      + " · " + (ShellSettings.material ? "FILLED" : "OUTLINED")
      + " · " + (ShellSettings.corners === "round" ? "ROUND " + ShellSettings.cornerRadius + " PX" : "SHARP")
  }

  KitRow {
    wide: true
    label: "Style"
    hint: "Material 3, or quiet and dense"

    KitSegments {
      model: [{ label: "Material", value: "material" }, { label: "Strict", value: "strict" }]
      current: ShellSettings.visualStyle
      onPicked: value => ShellSettings.set("visualStyle", value)
    }
  }

  KitRow {
    wide: true
    label: "Controls"
    hint: "Outlined: framed, no fills"

    KitSegments {
      model: [
        { label: "Filled", value: true },
        { label: "Outlined", value: false }
      ]
      current: ShellSettings.material
      onPicked: value => ShellSettings.set("material", value)
    }
  }

  CornersSection { id: cornersSection; width: parent.width }

  // the theme's light or dark twin (themes/mktheme.py); a theme without one stays
  KitRow {
    wide: true
    label: "Mode"
    hint: "The theme's light or dark twin"

    KitSegments {
      disabled: ThemeService.busy
      model: [{ label: "Dark", value: false }, { label: "Light", value: true }]
      current: ThemeService.light
      onPicked: value => ThemeService.setLight(value)
    }
  }

  // the result in real controls: they follow every choice above at once
  Flow {
    id: sample
    width: parent.width
    spacing: Theme.gapMedium
    property bool on: true

    KitButton { primary: true; text: "Apply" }
    KitButton { text: "Cancel" }
    KitButton { selected: true; text: "Picked" }
    KitButton { variant: "text"; text: "More" }
    KitInput { width: 160; placeholder: "Field" }
    KitSwitch { checked: sample.on; onToggled: sample.on = !sample.on }
  }
  KitLine {}

  AccentSection { id: accentSection; width: parent.width }
  KitLine {}
  WallpaperSection { id: wallpaperSection; width: parent.width; page: root }
  KitLine {}

  KitLabel {
    id: shapeLabel
    width: parent.width
    text: "ICONS"
    value: ShellSettings.solidIcons ? "SOLID" : "OUTLINE"
  }

  IconsSection { id: iconsSection; width: parent.width }

  // how a typed password shows: the lock and every password field of the shell
  KitRow {
    wide: true
    label: "Typed characters"
    hint: "In every password field"

    KitSegments {
      model: [{ label: "Dots", value: true }, { label: "Squares", value: false }]
      current: ShellSettings.passwordDots
      onPicked: value => ShellSettings.set("passwordDots", value)
    }
  }

  KitGrouper {}
}
