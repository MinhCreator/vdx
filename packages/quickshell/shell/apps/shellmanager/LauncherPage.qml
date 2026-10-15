import QtQuick
import qs.apps.launcher
import qs.config
import qs.kit

// Launcher: how the system menu (Super+R) looks — rows in the list, the
// panel's width and where it sits; then its TABS: ORDER, the tabs in the order
// they show, and HIDDEN below them. Drag a chip along a band to reorder it, into
// HIDDEN to hide it, back into ORDER to show it; one tab always stays shown. Then
// the tab it opens on and whether the search clears on close (ModuleSettings "launcher").
Column {
  id: root

  function opt(key, fallback) { return ModuleSettings.get("launcher", key, fallback); }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "menu"
  readonly property string title: "Launcher"
  readonly property string subtitle: root.opt("rows", 8) + " ROWS · " + String(root.opt("size", "medium")).toUpperCase()
                                     + " · " + String(root.opt("position", "top")).toUpperCase()

  // no groups for the sidebar
  readonly property var jumps: []

  spacing: 14

  // ---- tabs: the drag state and what each band holds ----
  property string dragId: ""
  property string dropZone: ""        // order | hidden
  property int dropIndex: -1
  property string hoverId: ""
  readonly property string focusId: dragId !== "" ? dragId : hoverId
  readonly property int chipHeight: 28

  readonly property var shownIds: LauncherService.tabs.map(t => t.value)
  readonly property var hiddenIds: LauncherService.orderAll.filter(v => LauncherService.hiddenTabs.includes(v))
  readonly property bool isDefault: LauncherService.orderAll.join() === LauncherService.defaultOrder.join()
                                    && LauncherService.hiddenTabs.length === 0

  function tab(id) { return LauncherService.allTabs.find(t => t.value === id) ?? { label: id, icon: "app-window" }; }
  function ids(zone) { return zone === "hidden" ? hiddenIds : shownIds; }
  function save(order, hidden) {
    ModuleSettings.set("launcher", "order", order);
    ModuleSettings.set("launcher", "hidden", hidden);
  }

  // where the pointer would drop: the band under y, then the chip slot in reading
  // order — chips on earlier lines, or left of the pointer on its line, come before it
  function track(x, y) {
    ghost.x = x + 10;
    ghost.y = y - ghost.height / 2;
    for (let i = 0; i < bands.count; i++) {
      const band = bands.itemAt(i);
      if (y < band.y - 6 || y > band.y + band.height + 6) continue;
      let index = 0;
      const chips = band.chips;
      for (let j = 0; j < chips.count; j++) {
        const c = chips.itemAt(j);
        const p = c.mapToItem(zonesArea, c.width / 2, c.height / 2);
        if (p.y < y - root.chipHeight / 2 || (Math.abs(p.y - y) <= root.chipHeight / 2 && p.x < x)) index = j + 1;
      }
      dropZone = band.zone;
      dropIndex = index;
      return;
    }
    dropZone = "";
  }

  // the stored order holds hidden tabs too: the slot is translated through the
  // shown neighbours, as the Bar's
  function drop() {
    if (dragId !== "" && dropZone === "hidden") {
      if (shownIds.includes(dragId) && shownIds.length > 1)
        save(LauncherService.orderAll, LauncherService.hiddenTabs.concat([dragId]));
    } else if (dragId !== "" && dropZone === "order") {
      const others = shownIds.filter(v => v !== dragId);
      const current = shownIds.indexOf(dragId);
      const slot = current >= 0 && dropIndex > current ? dropIndex - 1 : dropIndex;
      const full = LauncherService.orderAll.filter(v => v !== dragId);
      const index = slot < others.length ? full.indexOf(others[slot])
                  : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
                  : full.length;
      full.splice(index, 0, dragId);
      save(full, LauncherService.hiddenTabs.filter(v => v !== dragId));
    }
    dragId = "";
    dropZone = "";
    dropIndex = -1;
  }

  // ---- layout ----
  KitLabel { text: "LAYOUT" }

  KitOptionRow {
    module: "launcher"; key: "rows"; fallback: 8
    label: "Rows"; hint: "Items shown before the list scrolls"
    model: [6, 8, 10, 12].map(v => ({ label: String(v), value: v }))
  }

  KitOptionRow {
    module: "launcher"; key: "size"; fallback: "medium"
    label: "Size"; hint: "The panel's width"
    model: [{ label: "Small", value: "small" }, { label: "Medium", value: "medium" }, { label: "Large", value: "large" }]
  }

  KitOptionRow {
    module: "launcher"; key: "position"; fallback: "top"
    label: "Position"; hint: "Where the panel sits on the screen"
    model: [{ label: "Top", value: "top" }, { label: "Center", value: "center" }, { label: "Bottom", value: "bottom" }]
  }

  KitLine {}

  // ---- tabs ----
  Item {
    width: parent.width
    height: tabsReset.height

    KitLabel {
      anchors { left: parent.left; right: tabsReset.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
      text: "TABS"
      // what the pointer is on, or how this works
      value: root.focusId !== "" ? root.tab(root.focusId).label.toUpperCase() : "DRAG TO ORDER OR HIDE"
      valueColor: root.focusId !== "" ? Theme.foreground2 : Theme.muted
    }

    KitButton {
      id: tabsReset
      anchors.right: parent.right
      icon: "rotate-ccw"
      text: "Reset"
      disabled: root.isDefault
      onClicked: root.save(LauncherService.defaultOrder, [])
    }
  }

  // two bands: ORDER (the tabs shown, in the order they show) and HIDDEN below
  Column {
    id: zonesArea
    width: parent.width
    spacing: 0

    Repeater {
      id: bands
      model: ["order", "hidden"]

      // a settings-style row: the band's name on the left, its chips on the
      // right, a thin line between; no boxes
      Item {
        id: band

        required property string modelData
        required property int index

        readonly property string zone: modelData
        readonly property var ids: root.ids(modelData)
        readonly property bool target: root.dragId !== "" && root.dropZone === modelData
        readonly property alias chips: chipRepeater

        width: zonesArea.width
        height: area.height + 12

        KitText {
          y: 8 + (root.chipHeight - height) / 2
          text: (band.zone === "order" ? "ORDER" : "HIDDEN") + " · " + band.ids.length
          color: band.target ? Theme.foreground0 : Theme.muted
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
        }

        // the chips; a faint fill marks the band a chip is dragged over
        Rectangle {
          id: area
          x: 110
          y: 8
          width: parent.width - x
          height: Math.max(root.chipHeight, flow.implicitHeight)
          color: band.target ? Theme.background1 : "transparent"

          Flow {
            id: flow
            width: parent.width
            spacing: 6

            Repeater {
              id: chipRepeater
              model: band.ids

              Rectangle {
                id: chip

                required property string modelData
                required property int index

                width: chipRow.implicitWidth + 20
                height: root.chipHeight
                color: chipArea.containsMouse && root.dragId === "" ? Theme.background3 : Theme.background1
                opacity: root.dragId === modelData ? 0.25 : 1

                Row {
                  id: chipRow
                  anchors.centerIn: parent
                  spacing: 6

                  KitIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.tab(chip.modelData).icon
                    tint: band.zone === "hidden" ? Theme.muted : Theme.foreground2
                    size: 14
                  }

                  KitText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.tab(chip.modelData).label
                    color: band.zone === "hidden" ? Theme.muted : Theme.foreground0
                    font.pixelSize: Theme.fontSize - 1
                  }
                }

                // insertion marker before this chip, or after the last one
                Rectangle {
                  readonly property bool after: chip.index === band.ids.length - 1 && root.dropIndex === band.ids.length
                  visible: band.target && (root.dropIndex === chip.index || after)
                  x: after ? parent.width + 2 : -4
                  width: 2
                  height: parent.height
                  color: Theme.foreground0
                }

                MouseArea {
                  id: chipArea
                  anchors.fill: parent
                  hoverEnabled: true
                  preventStealing: true
                  cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                  onEntered: root.hoverId = chip.modelData
                  onExited: if (root.hoverId === chip.modelData) root.hoverId = ""
                  onPressed: mouse => {
                    root.dragId = chip.modelData;
                    const p = mapToItem(zonesArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onPositionChanged: mouse => {
                    if (root.dragId === "") return;
                    const p = mapToItem(zonesArea, mouse.x, mouse.y);
                    root.track(p.x, p.y);
                  }
                  onReleased: root.drop()
                }
              }
            }
          }

          KitText {
            visible: band.ids.length === 0
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: root.dragId !== "" ? "drop here" : band.zone === "hidden" ? "nothing hidden" : "empty"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }
        }
      }
    }

    // the chip being dragged, following the pointer
    KitText {
      id: ghost
      z: 10
      visible: root.dragId !== ""
      text: root.tab(root.dragId).label
      font.weight: Font.ExtraBold
    }
  }

  KitLine {}

  // ---- opening ----
  KitLabel { text: "OPENING" }

  KitOptionRow {
    module: "launcher"; key: "opens"; fallback: "apps"
    label: "Opens on"; hint: "The tab shown first"
    model: LauncherService.allTabs.map(t => ({ label: t.label, value: t.value }))
  }

  KitToggleRow { module: "launcher"; key: "clear"; fallback: true; label: "Clear search on close"; hint: "Off: the search stays as it was" }

  KitToggleRow { module: "launcher"; key: "english"; fallback: true; label: "English layout on open"; hint: "Switches the keyboard when it opens" }
}
