import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.apps.shellmanager
import qs.bar.island
import qs.components
import qs.config
import qs.kit
import qs.modules.capture

// Top bar for one screen. Modules come from BarLayout (three zones, order,
// switched-off ones); separators sit between neighbours of a zone only. The
// Shell button opens the Shell Manager.
//
// Bar › Style island: no strip and no zones — the Island (bar/island) is the
// whole bar and every module opens out of it. The window is clear and as tall
// as the open island; its input mask is the island alone.
PanelWindow {
  id: root

  required property var modelData   // the screen, injected by Variants

  // id -> the module's Component, made for this bar
  readonly property var modules: faces.map

  ModuleFaces { id: faces; bar: root }

  // a module's options in the Shell Manager (a right click on it): an app's
  // bar module on the app's tab, the others on their page under Modules
  function openSettings(id) {
    const app = ShellAppsService.entries.find(a => a.module === id) ?? null;
    const has = app ? !!app.moduleSettings : !!BarLayout.modules.find(p => p.id === id)?.settings;
    if (has) Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "shell", "open",
                                      (app ? "apps" : "modules") + ":" + id]);
  }

  component Zone: Row {
    id: zone

    property string name
    property var modules: ({})

    readonly property var ids: Theme.island ? [] : BarLayout.visibleIn(zone.name, root.modelData.name)
    // folded into the Folder for want of room (BarLayout.overflow), and the rest
    readonly property var folded: BarLayout.overflow[root.modelData.name] ?? []
    readonly property var shown: ids.filter(id => !folded.includes(id))

    spacing: Theme.moduleSpacing
    onIdsChanged: root.scheduleFold()

    Repeater {
      model: zone.ids

      Row {
        id: cell

        required property string modelData
        readonly property bool custom: BarLayout.isSeparator(modelData)
        // folded: hidden, and no face here — the Folder makes it (one popup, one IPC target)
        readonly property bool folded: zone.folded.includes(modelData)
        readonly property int at: zone.shown.indexOf(modelData)

        visible: !folded
        spacing: Theme.moduleSpacing

        // a custom separator is its own line, always drawn; the automatic one sits
        // between two modules (none next to a custom one)
        Separator {
          anchors.verticalCenter: parent.verticalCenter
          visible: cell.custom || (cell.at > 0 && !BarLayout.isSeparator(zone.shown[cell.at - 1]))
          ruled: cell.custom || ShellSettings.barSeparators
        }

        // the module; a right click on it opens its options. A pointer handler,
        // not an overlay: hover, the cursor and the wheel stay with the module
        Item {
          visible: !cell.custom
          anchors.verticalCenter: parent.verticalCenter
          width: slot.width
          height: slot.height

          Loader {
            id: slot
            sourceComponent: cell.folded ? null : zone.modules[cell.modelData] ?? null
            // the width it takes, kept for when it is folded
            onWidthChanged: if (!cell.folded && !cell.custom) root.noteWidth(cell.modelData, width)
          }

          TapHandler {
            acceptedButtons: Qt.RightButton
            enabled: ShellSettings.barRightSettings
            onTapped: root.openSettings(cell.modelData)
          }
        }
      }
    }
  }

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  // island style: tall enough for a module's popup opened in the island
  implicitHeight: Theme.island ? Math.round(modelData.height * 0.92) : Theme.barHeight
  // a hidden island (no clock, nothing beside it) with no child bar showing
  // leaves the edge to windows
  readonly property bool childrenShown: edgeLeft.width + edgeRight.width + besideLeft.width + besideRight.width > 0
  exclusiveZone: islandItem?.hidden && !childrenShown ? 0 : Theme.barEdge
  // while a popup is open, a click into it (a text field) takes the keyboard;
  // otherwise the bar never does
  WlrLayershell.keyboardFocus: PopupManager.current || (islandItem?.grabbing ?? false)
    ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  color: Theme.island ? "transparent" : Theme.background0

  mask: Theme.island ? islandMask : null

  Region {
    id: islandMask
    item: root.islandItem && !root.islandItem.hidden ? root.islandItem.shape : null

    Region { item: root.islandItem?.bubble ?? null }
    Region { item: edgeLeft }
    Region { item: edgeRight }
    Region { item: besideLeft }
    Region { item: besideRight }
  }

  // ---- child bars ----
  // the child bars already on show, by spot: one that is new there (its first
  // module, a drop on another spot) grows in
  property KitSeen childSeen: KitSeen { motion: Theme.island ? Motion.island : Motion.bar }
  // BarLayout.barsOn this screen, in this bar's row: a side (left | right) at the screen's
  // edge or beside the centre (the island, the centre zone). Island style: an
  // island each (IslandChild), framed like the island; solid: a raised group in the strip.
  component ChildGroup: Row {
    id: group

    property string side
    property string place

    readonly property real band: Theme.island ? Theme.islandHeight : Theme.barHeight - 8

    y: Theme.island ? Theme.islandTop : Math.round((Theme.barHeight - band) / 2)
    spacing: Theme.gapMedium

    Repeater {
      model: BarLayout.barsOn(root.modelData.name).filter(b => b.side === group.side && b.place === group.place
                                                                && BarLayout.barModules(root.modelData.name, b.id).length > 0)

      IslandChild {
        id: child
        bar: root
        band: group.band

        property real grown: 1
        opacity: grown
        scale: 0.8 + 0.2 * grown
        NumberAnimation { id: growIn; target: child; property: "grown"; from: 0; to: 1; duration: Motion.normal; easing.type: Motion.easing }
        Component.onCompleted: if (root.childSeen.arrived(child.modelData.id + "/" + group.side + "/" + group.place)) growIn.start()
      }
    }
  }

  // island style: where a module's popup opens — the child bar's island it
  // sits in (IslandChild), or the island
  function popupHost(item) {
    for (let p = item; p; p = p.parent)
      if (p.hostsPopups === true) return p;
    return root.islandItem;
  }

  // the centre the "beside" groups hold on to, and the gap they keep
  readonly property real centreX: Theme.island ? islandLoader.x : centerZone.x
  readonly property real centreWidth: Theme.island ? islandLoader.width : centerZone.width
  readonly property real childGap: Theme.gapMedium
  // the island's back bubble takes room on its left while a module is open
  readonly property real bubbleRoom: (root.islandItem?.bubble?.reveal ?? 0) * (Theme.islandHeight + Theme.gapMedium)

  ChildGroup {
    id: edgeLeft
    side: "left"; place: "edge"
    x: Theme.island ? Theme.islandTop * 2 : leftZone.x + leftZone.width + (leftZone.width > 0 ? root.childGap : 0)
  }
  ChildGroup {
    id: edgeRight
    side: "right"; place: "edge"
    x: Theme.island ? root.width - width - Theme.islandTop * 2
                    : rightZone.x - width - (rightZone.width > 0 ? root.childGap : 0)
  }
  // no centre to hold on to (a hidden island, an empty centre zone): the
  // groups meant for it meet in the middle of the screen instead
  readonly property bool centreGone: Theme.island ? (root.islandItem?.hidden ?? false) : centerZone.width === 0
  readonly property real besideJoin: besideLeft.width > 0 && besideRight.width > 0 ? root.childGap : 0
  readonly property real besideStart: (root.width - besideLeft.width - besideRight.width - besideJoin) / 2

  ChildGroup {
    id: besideLeft
    side: "left"; place: "island"
    x: root.centreGone ? root.besideStart : root.centreX - width - root.childGap - root.bubbleRoom
  }
  ChildGroup {
    id: besideRight
    side: "right"; place: "island"
    x: root.centreGone ? root.besideStart + besideLeft.width + root.besideJoin
                       : root.centreX + root.centreWidth + root.childGap
  }

  Zone {
    id: leftZone
    name: "left"
    modules: root.modules
    anchors { left: parent.left; leftMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
  }

  Zone {
    id: centerZone
    name: "center"
    modules: root.modules
    anchors.centerIn: parent
  }

  Zone {
    id: rightZone
    name: "right"
    modules: root.modules
    anchors { right: parent.right; rightMargin: Theme.edgeMargin; verticalCenter: parent.verticalCenter }
  }

  // ---- overflow ----
  // Solid style: LEFT and RIGHT keep to their side of the centre (and of the
  // child bars); what does not fit folds into the Folder, from the centre
  // outwards, and comes back once there is room. Worked out from each face's
  // last width, so a folded face (not made here) still counts. No Folder on
  // this bar: nothing folds.
  readonly property int foldGap: 24            // kept free between a side and the centre
  property var faceWidths: ({})                // module id -> px

  function noteWidth(id, w) {
    if (w <= 0 || faceWidths[id] === w) return;
    faceWidths[id] = w;
    scheduleFold();
  }
  function scheduleFold() { Qt.callLater(root.computeFold); }

  // a zone's width with these ids, as Zone lays them out
  function zoneWidth(ids) {
    let w = 0;
    for (let i = 0; i < ids.length; i++) {
      if (i > 0) w += Theme.moduleSpacing;
      if (BarLayout.isSeparator(ids[i])) { w += separatorProbe.implicitWidth; continue; }
      if (i > 0 && !BarLayout.isSeparator(ids[i - 1])) w += separatorProbe.implicitWidth + Theme.moduleSpacing;
      w += faceWidths[ids[i]] ?? 0;
    }
    return w;
  }

  // what leaves `ids` (taken in `outward` order) until it fits `room`
  function fold(ids, room, outward) {
    let kept = ids.slice();
    const out = [];
    for (const id of outward) {
      if (zoneWidth(kept) <= room) break;
      if (id === "folder") continue;
      out.push(id);
      kept = kept.filter(x => x !== id);
    }
    return out;
  }

  function computeFold() {
    const screen = root.modelData.name;
    const left = BarLayout.visibleIn("left", screen);
    const right = BarLayout.visibleIn("right", screen);
    const folder = left.concat(BarLayout.visibleIn("center", screen), right).includes("folder");
    if (Theme.island || !folder || root.width <= 0) { BarLayout.setOverflow(screen, []); return; }
    const centreStart = centerZone.x - (besideLeft.width > 0 ? besideLeft.width + root.childGap : 0);
    const centreEnd = centerZone.x + centerZone.width + (besideRight.width > 0 ? besideRight.width + root.childGap : 0);
    const leftRoom = centreStart - Theme.edgeMargin - root.foldGap - (edgeLeft.width > 0 ? edgeLeft.width + root.childGap : 0);
    const rightRoom = root.width - Theme.edgeMargin - centreEnd - root.foldGap - (edgeRight.width > 0 ? edgeRight.width + root.childGap : 0);
    BarLayout.setOverflow(screen, fold(left, leftRoom, left.slice().reverse()).concat(fold(right, rightRoom, right)));
  }

  onWidthChanged: scheduleFold()
  Connections { target: centerZone; function onWidthChanged() { root.scheduleFold(); } }
  Connections { target: edgeLeft; function onWidthChanged() { root.scheduleFold(); } }
  Connections { target: edgeRight; function onWidthChanged() { root.scheduleFold(); } }
  Connections { target: besideLeft; function onWidthChanged() { root.scheduleFold(); } }
  Connections { target: besideRight; function onWidthChanged() { root.scheduleFold(); } }
  Connections { target: Theme; function onIslandChanged() { root.scheduleFold(); } }

  // the width of one "|" with its room, for zoneWidth
  Separator {
    id: separatorProbe
    visible: false
    onImplicitWidthChanged: root.scheduleFold()
  }

  // Super+Shift+S with no Capture module on this bar: the panel from the centre
  CaptureFallback { bar: root; anchorItem: centerZone }

  // island style: the Island; BarPopup opens a module's popup in it
  readonly property Item islandItem: islandLoader.item

  Loader {
    id: islandLoader
    active: Theme.island
    anchors.horizontalCenter: parent.horizontalCenter
    y: Theme.islandTop

    sourceComponent: Island {
      bar: root
      modules: root.modules
      onSettings: id => root.openSettings(id)
    }
  }
}
