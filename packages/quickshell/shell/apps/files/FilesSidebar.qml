import QtQuick
import qs.config
import qs.kit

// The sidebar: places, bookmarks, devices; it scrolls when they don't fit.
Rectangle {
  id: root

  required property var files   // the Files window

  radius: Theme.radiusCard
  color: "transparent"
  border.width: FilesService.frames ? Theme.windowFrameWidth : 0
  border.color: Theme.popupFrame
  clip: true

  Flickable {
    id: sidebar
    anchors { fill: parent; margins: Theme.gapSmall }
    contentHeight: sideColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: sideColumn
      width: sidebar.width
      spacing: Theme.gapTight

      KitLabel { text: "PLACES" }

      Repeater {
        model: FilesService.places.concat([{ name: "Trash", path: FilesService.trashPath }])

        FilesPlace {
          required property var modelData
          icon: files.placeIcon(modelData.name)
          text: modelData.name
          current: FilesService.path === modelData.path
          onClicked: FilesService.go(modelData.path)
          onRightClicked: at => {
            if (modelData.path === FilesService.trashPath) return;
            files.menuAt(at, [
              { label: "Open", run: () => FilesService.go(modelData.path) },
              { label: "Bookmark", disabled: FilesService.bookmarks.some(b => b.path === modelData.path),
                run: () => FilesService.bookmark(modelData.path) },
            ]);
          }
        }
      }

      Item { width: 1; height: Theme.gapLoose; visible: FilesService.bookmarks.length > 0 }
      KitLabel { text: "BOOKMARKS"; visible: FilesService.bookmarks.length > 0 }

      Repeater {
        model: FilesService.bookmarks

        FilesPlace {
          required property var modelData
          icon: "folder"
          text: modelData.name
          current: FilesService.path === modelData.path
          onClicked: FilesService.go(modelData.path)
          onRightClicked: at => files.menuAt(at, [
            { label: "Open", run: () => FilesService.go(modelData.path) },
            { label: "Remove bookmark", run: () => FilesService.unbookmark(modelData.path) },
          ])
        }
      }

      Item { width: 1; height: Theme.gapLoose; visible: FilesService.devices.length > 0 }
      KitLabel { text: "DEVICES"; visible: FilesService.devices.length > 0 }

      Repeater {
        model: FilesService.devices

        FilesPlace {
          required property var modelData
          icon: "package"
          text: modelData.name
          hint: modelData.mount !== "" ? "" : modelData.size
          current: modelData.mount !== "" && FilesService.path.startsWith(modelData.mount)
          onClicked: modelData.mount !== "" ? FilesService.go(modelData.mount) : FilesService.mountDevice(modelData, true)
          onRightClicked: at => files.menuAt(at, [
            { label: "Open", disabled: modelData.mount === "", run: () => FilesService.go(modelData.mount) },
            { label: "Mount", disabled: modelData.mount !== "", run: () => FilesService.mountDevice(modelData, false) },
            { label: "Unmount", disabled: modelData.mount === "", run: () => FilesService.unmountDevice(modelData) },
          { label: "Properties", run: () => FilesService.deviceProperties(modelData) },
          ])
        }
      }
    }
  }
}

