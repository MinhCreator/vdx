import QtQuick
import qs.config
import qs.kit

// One palette token selects a solid accent throughout the shell.
KitColumn {
  spacing: Theme.sectionGap

  id: root
  readonly property var names: ["theme", "red", "orange", "yellow", "green", "aqua", "blue", "purple"]
  readonly property var targets: [
    { value: "switches",   label: "Switches",      hint: "The ones that are on" },
    { value: "sliders",    label: "Sliders",       hint: "The filled part" },
    { value: "choices",    label: "Choices",       hint: "The picked one" },
    { value: "selects",    label: "Dropdowns",     hint: "The open one's frame" },
    { value: "modules",    label: "Bar modules",   hint: "Active states, the equalizer; not warnings" }
  ]
  readonly property string selected: names.includes(ShellSettings.accentStops[0]) ? ShellSettings.accentStops[0] : "theme"
  function choose(name) {
    ShellSettings.set("accentStops", [name, name]);
    ShellSettings.set("accentGradient", false);
  }
  function setTarget(key, on) {
    ShellSettings.set("accentWhere", Object.assign({}, ShellSettings.accentWhere, { [key]: on }));
  }
  KitLabel { text: "ACCENT COLOUR" }
  KitRow {
    label: "Accent"
    hint: "Highlight active controls across the shell"
    KitSwitch { checked: ShellSettings.accent; onToggled: ShellSettings.set("accent", !checked) }
  }
  KitColourPicker {
    visible: ShellSettings.accent
    width: parent.width
    palette: root.names
    picked: root.selected
    colours: name => [Theme.accentColour(name), Theme.accentColour(name)]
    icons: name => name === "theme" ? "palette" : ""
    onChosen: name => root.choose(name)
  }
  KitLine {}
  KitLabel { text: "USE ACCENT ON" }
  Repeater {
    model: root.targets
    KitRow {
      id: target
      required property var modelData
      visible: ShellSettings.accent
      label: modelData.label
      hint: modelData.hint
      KitSwitch {
        checked: ShellSettings.accentWhere[target.modelData.value] === true
        onToggled: root.setTarget(target.modelData.value, !checked)
      }
    }
  }
  KitGrouper {}
}
