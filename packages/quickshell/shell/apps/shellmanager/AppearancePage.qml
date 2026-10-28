import QtQuick
import qs.config
import qs.kit

// Interface (style, corners) and accent use a full-width form. Icons and Wallpaper are pages of their own.
KitSettingsWorkspace {
  id: root
  readonly property bool fillsViewport: true
  readonly property Item previewItem: null
  readonly property var tabs: sections
  readonly property string icon: "sun"
  readonly property string title: "Appearance"
  readonly property string description: "The colour, shape and style of the whole shell. Applies at once."
  readonly property string subtitle: "Make the shell feel like yours"
  property string tab: "style"
  readonly property var jumps: [
    { key: "style", label: "Interface", y: 0 },
    { key: "accent", label: "Accent", y: 0 },
    { key: "shape", label: "Shape", y: 0 }
  ]
  function jump(key) {
    tab = key === "accent" ? "accent" : "style";
  }
  readonly property var resetKeys: ["corners", "cornerRadius", "cornerSplit", "cornerRadii", "material", "accent", "accentStops", "accentGradient", "accentCustom", "accentWhere"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }

  sections: [{label: "Interface", value: "style"}, {label: "Accent", value: "accent"}]
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
        KitGrouper {}
      }
      AccentSection { width: parent.width; visible: root.tab === "accent" }
      KitGrouper {}
    }
  }
}
