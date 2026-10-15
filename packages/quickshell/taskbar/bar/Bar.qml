import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.kit
import qs.plugins.ai
import qs.plugins.audio
import qs.plugins.battery
import qs.plugins.brightness
import qs.plugins.capture
import qs.plugins.clipboard
import qs.plugins.clock
import qs.plugins.language
import qs.plugins.mihomo
import qs.plugins.music
import qs.plugins.notifications
import qs.plugins.sysmon
import qs.plugins.radio
import qs.plugins.wifi
import qs.plugins.workspaces

// Top bar for one screen. Plugins come from BarLayout (three zones, order,
// switched-off ones); separators sit between neighbours of a zone only. The
// Shell button opens the Shell Manager. While BarLayout.editing the window
// grows downward by the edit panel (BarShelf) and every module can be dragged
// (within a zone, to another one, down onto the shelf); the bar itself keeps
// its place.
PanelWindow {
  id: root

  required property var modelData   // the screen, injected by Variants

  readonly property var modules: ({
    workspaces: workspaces, music: music, radio: radio, clock: clock,
    brightness: brightness, audio: audio, wifi: wifi, mihomo: mihomo,
    battery: battery, language: language, ai: ai, notifications: notifications,
    shell: shell, capture: capture, clipboard: clipboard, sysmon: sysmon
  })

  readonly property string screenName: modelData.name
  readonly property Item dragLayer: dragLayerItem
  readonly property var zoneItems: ({ left: leftZone, center: centerZone, right: rightZone })

  // drag state: the module under the pointer, the zone and slot it would take
  property string dragId: ""
  property string dropZone: ""        // left | center | right | shelf
  property int dropIndex: -1
  property real markerX: 0

  // Drop slot under the pointer (dragLayer coordinates): below the strip is
  // the shelf, on it the nearest zone and the slot among its modules.
  function track(x, y) {
    ghost.x = x - ghost.width / 2;
    ghost.y = y - ghost.height / 2;
    if (y >= Theme.barHeight) { dropZone = "shelf"; dropIndex = -1; return; }
    let best = "left";
    let gap = Infinity;
    for (const name of BarLayout.zones) {
      const z = zoneItems[name];
      const d = x < z.x ? z.x - x : x > z.x + z.width ? x - z.x - z.width : 0;
      if (d < gap) { gap = d; best = name; }
    }
    const z = zoneItems[best];
    const n = z.items.count;
    let index = 0;
    for (let j = 0; j < n; j++) {
      const l = z.items.itemAt(j).loader;
      if (l.mapToItem(dragLayerItem, l.width / 2, 0).x < x) index = j + 1;
    }
    dropZone = best;
    dropIndex = index;
    if (n === 0) markerX = z.x + z.width / 2 - 1;
    else if (index < n) markerX = z.items.itemAt(index).loader.mapToItem(dragLayerItem, 0, 0).x - 3;
    else {
      const l = z.items.itemAt(n - 1).loader;
      markerX = l.mapToItem(dragLayerItem, l.width, 0).x + 1;
    }
  }

  // The zones show only placed plugins; the stored order also holds the rest,
  // so the visible slot is translated through its visible neighbours.
  function drop() {
    const id = dragId;
    const zone = dropZone;
    const index = dropIndex;
    const s = screenName;
    dragId = "";
    dropZone = "";
    dropIndex = -1;
    if (id === "" || zone === "") return;
    const onShelf = BarLayout.unplaced(s).includes(id);
    if (zone === "shelf") {
      if (!onShelf) BarLayout.setEnabled(id, false, s);
      return;
    }
    const visible = BarLayout.visibleIn(zone, s);
    const current = visible.indexOf(id);
    const slot = current >= 0 && index > current ? index - 1 : index;
    const others = visible.filter(x => x !== id);
    const full = BarLayout.layout(s)[zone].filter(x => x !== id);
    const at = slot < others.length ? full.indexOf(others[slot])
             : others.length > 0 ? full.indexOf(others[others.length - 1]) + 1
             : full.length;
    if (onShelf) BarLayout.setEnabled(id, true, s);
    BarLayout.move(id, zone, at, s);
  }

  component Zone: Row {
    id: zone

    property string name
    property var modules: ({})
    readonly property alias items: repeater

    spacing: Theme.moduleSpacing
    // an empty zone still needs somewhere to drop
    width: Math.max(implicitWidth, BarLayout.editing ? 96 : 0)

    Repeater {
      id: repeater
      model: BarLayout.visibleIn(zone.name, root.modelData.name)

      Row {
        required property string modelData
        required property int index
        readonly property alias loader: moduleLoader

        spacing: Theme.moduleSpacing

        Separator {
          anchors.verticalCenter: parent.verticalCenter
          visible: index > 0
        }

        Loader {
          id: moduleLoader
          anchors.verticalCenter: parent.verticalCenter
          sourceComponent: zone.modules[modelData] ?? null

          // editing: a frame, and a mouse area above the module that swallows
          // its clicks and drags it
          Rectangle {
            z: 10
            visible: BarLayout.editing
            anchors.fill: parent
            anchors.margins: -2
            color: "transparent"
            border.width: 1
            border.color: root.dragId === modelData ? Theme.foreground2 : Theme.gray
            opacity: root.dragId === modelData ? 0.4 : 1
          }

          MouseArea {
            z: 11
            enabled: BarLayout.editing
            anchors.fill: parent
            anchors.margins: -2
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: mouse => {
              root.dragId = modelData;
              const p = mapToItem(dragLayerItem, mouse.x, mouse.y);
              root.track(p.x, p.y);
            }
            onPositionChanged: mouse => {
              if (root.dragId === "") return;
              const p = mapToItem(dragLayerItem, mouse.x, mouse.y);
              root.track(p.x, p.y);
            }
            onReleased: root.drop()
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
  implicitHeight: Theme.barHeight + (BarLayout.editing ? shelf.implicitHeight : 0)
  exclusiveZone: Theme.barHeight
  color: Theme.background0

  // the bar proper, always Theme.barHeight tall
  Item {
    id: strip
    anchors { top: parent.top; left: parent.left; right: parent.right }
    height: Theme.barHeight

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
  }

  BarShelf {
    id: shelf
    visible: BarLayout.editing
    anchors { top: strip.bottom; left: parent.left; right: parent.right }
    bar: root
  }

  // editing: zone outlines, the insertion marker and the icon being dragged
  Item {
    id: dragLayerItem
    z: 100
    anchors.fill: parent
    visible: BarLayout.editing

    Repeater {
      model: [leftZone, centerZone, rightZone]

      Rectangle {
        required property Item modelData

        x: modelData.x - 4
        y: modelData.y - 4
        width: modelData.width + 8
        height: modelData.height + 8
        color: "transparent"
        border.width: 1
        border.color: root.dragId !== "" && root.dropZone === modelData.name ? Theme.foreground2 : Theme.background3
      }
    }

    Rectangle {
      visible: root.dragId !== "" && root.dropZone !== "" && root.dropZone !== "shelf"
      x: root.markerX
      y: 4
      width: 2
      height: Theme.barHeight - 8
      color: Theme.foreground0
    }

    Rectangle {
      id: ghost
      visible: root.dragId !== ""
      width: 30
      height: 30
      color: Theme.background3
      border.width: Theme.frameWidth
      border.color: Theme.foreground2

      KitIcon {
        anchors.centerIn: parent
        name: BarLayout.icon(root.dragId)
        solid: ShellSettings.solidIcons
        size: 16
      }
    }
  }

  Component { id: workspaces; Workspaces {} }
  Component { id: music; Music { bar: root } }
  Component { id: radio; Radio { bar: root } }
  Component { id: clock; Clock {} }
  Component { id: brightness; Brightness { bar: root } }
  Component { id: audio; Audio { bar: root } }
  Component { id: wifi; Wifi { bar: root } }
  Component { id: mihomo; Mihomo { bar: root } }
  Component { id: battery; Battery { bar: root } }
  Component { id: language; Language {} }
  Component { id: ai; Ai { bar: root } }
  Component { id: notifications; Notifications { bar: root } }
  Component { id: capture; Capture { bar: root } }
  Component { id: clipboard; Clipboard { bar: root } }
  Component { id: sysmon; Sysmon { bar: root } }

  // The Shell Manager's button; a plugin of its own so it can move between zones.
  Component {
    id: shell

    KitBarItem {
      id: shellButton
      icon: "sliders"

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellSettings.managerOpen = !ShellSettings.managerOpen
      }
    }
  }
}
