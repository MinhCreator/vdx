import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar › one child bar: where it sits in the main bar's row (side, at the edge
// or by the centre, monitor) and its modules — THIS BAR in order, and OTHERS
// (the main bar's, or another child bar's) to drag in from. A module is in
// one bar only. Remove gives its modules back to the main bar.
Column {
  id: root

  property string barId: ""
  readonly property var config: BarLayout.bar(barId) ?? ({})

  signal removed()

  readonly property string focusId: chips.dragId !== "" ? chips.dragId : chips.hoverId

  function module(id) { return BarLayout.modules.find(p => p.id === id) ?? null; }
  function others() {
    const mine = BarLayout.barModules(barId);
    return BarLayout.modules.map(p => p.id).filter(id => !mine.includes(id) && BarLayout.installed(id) && id !== "folder");
  }
  function set(key, value) {
    const c = {};
    c[key] = value;
    BarLayout.updateBar(barId, c);
  }

  spacing: Theme.gapGroup

  // ---- place ----
  KitLabel {
    text: "PLACE"
    value: ((root.config.side ?? "") + " · " + (root.config.place === "island" ? "by the centre" : "at the edge")).toUpperCase()
  }

  KitRow {
    wide: true
    label: "Side"
    hint: "Of the main bar's row"

    KitChoices {
      stretch: true
      model: [{ label: "Left", value: "left" }, { label: "Right", value: "right" }]
      current: root.config.side ?? "right"
      onPicked: value => root.set("side", value)
    }
  }

  KitRow {
    wide: true
    label: "Place"
    hint: Theme.island ? "Screen edge, or by the island" : "Screen edge, or by the centre"

    KitChoices {
      stretch: true
      model: [{ label: "Edge", value: "edge" }, { label: "Centre", value: "island" }]
      current: root.config.place ?? "edge"
      onPicked: value => root.set("place", value)
    }
  }

  KitRow {
    wide: true
    label: "Monitor"
    hint: "One monitor, or every one"

    KitChoices {
      stretch: true
      model: [{ label: "All", value: "" }].concat(Quickshell.screens.map(s => ({ label: s.name, value: s.name })))
      current: root.config.screen ?? ""
      onPicked: value => root.set("screen", value)
    }
  }

  KitLine {}

  // ---- modules ----
  Item {
    width: parent.width
    height: removeButton.height

    KitLabel {
      anchors { left: parent.left; right: removeButton.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      text: "MODULES"
      value: root.focusId !== "" ? (root.module(root.focusId)?.label ?? "").toUpperCase()
                                 : "A MODULE HERE LEAVES THE MAIN BAR"
      valueColor: root.focusId !== "" ? Theme.foreground2 : Theme.muted
    }

    KitButton {
      id: removeButton
      anchors.right: parent.right
      icon: "trash"
      text: "Remove bar"
      onClicked: {
        BarLayout.removeBar(root.barId);
        root.removed();
      }
    }
  }

  KitChipBands {
    id: chips
    width: parent.width
    zones: ["bar", "others"]
    idsOf: zone => zone === "bar" ? BarLayout.barModules(root.barId) : root.others()
    labelOf: id => root.module(id)?.label ?? id
    iconOf: id => BarLayout.icon(id)
    zoneLabel: zone => zone === "bar" ? "THIS BAR" : "OTHERS"
    emptyText: zone => zone === "bar" ? "empty — drag modules here" : "every module is on this bar"
    onDropped: (id, zone, index) => {
      if (zone === "bar") {
        const current = BarLayout.barModules(root.barId).indexOf(id);
        BarLayout.moveToBar(id, root.barId, current >= 0 && index > current ? index - 1 : index);
      } else {
        BarLayout.moveToBar(id, "", 0);
      }
    }
  }
}
