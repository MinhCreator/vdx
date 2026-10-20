import QtQuick
import qs.config
import qs.kit

// The sidebar: one ordered list (This computer, the places, the trash, the folders pinned), then the
// devices, which come and go by themselves. Drag a row to move it; right click a row for its menu.
// No frame: the strip beside it (Files' split) is the only line.
Item {
  id: root

  required property var files   // the Files window
  readonly property int visibleCount: FilesService.sidebarItems.filter(i => !i.hidden).length

  // the row being dragged (its index in the stored list), and the row a drop would land beside
  property int dragFrom: -1
  property int dropAt: -1

  function rowAt(sceneY) {
    let best = -1, dist = Infinity;
    for (let i = 0; i < rows.count; i++) {
      const r = rows.itemAt(i);
      if (!r || !r.visible) continue;
      const d = Math.abs(r.mapToItem(null, 0, r.height / 2).y - sceneY);
      if (d < dist) { dist = d; best = i; }
    }
    return best;
  }

  function drop() {
    if (dragFrom >= 0 && dropAt >= 0 && dropAt !== dragFrom) FilesService.moveSidebar(dragFrom, dropAt);
    dragFrom = -1;
    dropAt = -1;
  }

  function rowMenu(item) {
    const pinned = item.kind === "folder";
    return [
      { label: "Open", run: () => FilesService.go(item.path) },
      pinned ? { label: "Unpin", run: () => FilesService.unpin(item.path) }
             : { label: "Hide from the sidebar", run: () => FilesService.unpin(item.path) },
    ];
  }

  Flickable {
    id: sidebar
    anchors.fill: parent
    anchors.rightMargin: Theme.gapSmall
    contentHeight: sideColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: sideColumn
      width: sidebar.width
      spacing: Theme.gapTight

      KitLabel { x: Theme.gapLoose; width: parent.width - Theme.gapLoose; text: "PLACES" }

      Repeater {
        id: rows
        model: FilesService.sidebarItems

        FilesPlace {
          required property var modelData
          required property int index
          visible: !modelData.hidden
          draggable: true
          icon: modelData.kind === "computer" ? "monitor" : modelData.kind === "trash" ? "trash"
              : modelData.kind === "place" ? root.files.placeIcon(modelData.name) : "folder"
          text: modelData.name
          current: FilesService.path === modelData.path
          onClicked: FilesService.go(modelData.path)
          onRightClicked: at => root.files.menuAt(at, root.rowMenu(modelData))
          onDragged: sceneY => { root.dragFrom = index; root.dropAt = root.rowAt(sceneY); }
          onDropped: sceneY => { root.dropAt = root.rowAt(sceneY); root.drop(); }
        }
      }

      // what is left when every row is hidden
      KitLabel {
        x: Theme.gapLoose
        width: parent.width - Theme.gapLoose
        visible: root.visibleCount === 0
        text: "NOTHING PINNED"
      }
      Item {
        width: sidebar.width
        height: visible ? hint.implicitHeight : 0
        visible: root.visibleCount === 0
        KitText {
          id: hint
          width: parent.width - Theme.gapLoose
          x: Theme.gapLoose
          wrapMode: Text.WordWrap
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
          text: "Right click a folder › Pin to sidebar"
        }
      }

      Item { width: 1; height: Theme.gapMedium; visible: FilesService.devices.length > 0 }
      KitLabel { x: Theme.gapLoose; width: parent.width - Theme.gapLoose; text: "DEVICES"; visible: FilesService.devices.length > 0 }

      Repeater {
        model: FilesService.devices

        FilesPlace {
          required property var modelData
          icon: "package"
          text: modelData.name
          hint: modelData.mount !== "" ? "" : modelData.size
          current: modelData.mount !== "" && FilesService.path.startsWith(modelData.mount)
          onClicked: modelData.mount !== "" ? FilesService.go(modelData.mount) : FilesService.mountDevice(modelData, true)
          onRightClicked: at => root.files.menuAt(at, [
            { label: "Open", disabled: modelData.mount === "", run: () => FilesService.go(modelData.mount) },
            { label: "Mount", disabled: modelData.mount !== "", run: () => FilesService.mountDevice(modelData, false) },
            { label: "Unmount", disabled: modelData.mount === "", run: () => FilesService.unmountDevice(modelData) },
            { label: "Properties", run: () => FilesService.deviceProperties(modelData) },
          ])
        }
      }
    }

    // the drop line: where the dragged row lands
    Rectangle {
      visible: root.dragFrom >= 0 && root.dropAt >= 0 && root.dropAt !== root.dragFrom
      readonly property var target: visible ? rows.itemAt(root.dropAt) : null
      x: 0
      width: sideColumn.width
      height: 2
      radius: 1
      color: Theme.accent
      y: target ? (root.dropAt > root.dragFrom ? target.y + target.height : target.y) - 1 : 0
    }
  }
}
