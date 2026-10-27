import QtQuick
import qs.config
import qs.kit

// Interface, accent and wallpaper settings use a full-width form.
KitSettingsWorkspace {
  id: root
  readonly property bool fillsViewport: true
  readonly property Item previewItem: null
  readonly property var tabs: sections
  readonly property string icon: "sun"
  readonly property string title: "Appearance"
  readonly property string subtitle: "Make the shell feel like yours"
  property string tab: "style"
  readonly property var jumps: [
    { key: "style", label: "Interface", y: 0 },
    { key: "accent", label: "Accent", y: 0 },
    { key: "wallpaper", label: "Wallpaper", y: 0 },
    { key: "shape", label: "Shape", y: 0 }
  ]
  function jump(key) {
    tab = key === "shape" ? "style" : ["style", "accent", "wallpaper"].includes(key) ? key : "style";
  }
  readonly property var resetKeys: ["solidIcons", "wallpaperMode", "wallpaperColor", "wallpaperImages", "wallpaperOutputs", "corners", "cornerRadius", "cornerSplit", "cornerRadii", "material", "accent", "accentStops", "accentGradient", "accentCustom", "accentWhere"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }
  readonly property bool customWallpaper: ShellSettings.wallpaperMode === "custom"
  readonly property bool imageWallpaper: ShellSettings.wallpaperMode === "image"
  readonly property string currentImage: WallpaperService.imageFor(ThemeService.current)
  readonly property color wallpaper: customWallpaper ? ShellSettings.wallpaperColor : Theme.background1
  property string wallpaperOutput: ""
  readonly property string wallpaperRel: WallpaperService.outputsFor(ThemeService.current)[wallpaperOutput] || currentImage

  sections: [{label: "Interface", value: "style"}, {label: "Accent", value: "accent"}, {label: "Wallpaper", value: "wallpaper"}]
  current: tab
  onPicked: value => tab = value

  settings: Component {
    Column {
      width: parent.width
      Column {
  spacing: Theme.sectionGap

        width: parent.width
        visible: root.tab === "style"
        KitLabel { text: "APPEARANCE" }
        KitRow {
          label: "Colour mode"
          wide: true
          KitSegments {
            model: [{label: "Dark", value: false}, {label: "Light", value: true}]
            current: ThemeService.light
            disabled: ThemeService.busy
            onPicked: value => ThemeService.setLight(value)
          }
        }
        KitRow {
          label: "Interface style"
          hint: ShellSettings.material ? "Tonal surfaces and soft controls" : "Clean outlines and compact controls"
          wide: true
          KitSegments {
            model: [{label: "Strict", value: false}, {label: "Material 3", value: true}]
            current: ShellSettings.material
            onPicked: value => ShellSettings.set("material", value)
          }
        }
        KitLine {}
        KitLabel { text: "SHAPE" }
        CornersSection { width: parent.width }
        IconsSection { width: parent.width }
        KitGrouper {}
      }
      AccentSection { width: parent.width; visible: root.tab === "accent" }
      WallpaperSection { width: parent.width; page: root; visible: root.tab === "wallpaper" }
      KitGrouper {}
    }
  }
}
