import QtQuick
import qs.config
import qs.kit

// The list, the grid or the columns of the folder shown, framed; files dropped from another app land in it.
Rectangle {
  id: root

  required property var files   // the Files window
  property alias listView: list
  property alias gridView: grid
  radius: Theme.radiusCard
  color: Theme.background1
  border.width: Theme.frameWidth
  border.color: Theme.background2
  clip: true

  // the Columns view: the parent folder on the left, the selected folder on the right
  FilesColumn {
    id: parentCol
    visible: files.columnsView && FilesService.canUp
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Theme.gapWide }
    width: files.parentW
    folder: visible ? FilesService.parentOf(FilesService.path) : ""
    highlight: FilesService.path
    title: "PARENT"
    onOpened: p => FilesService.go(p)
  }

  FilesColumn {
    id: childCol
    visible: files.columnsView && files.selectedDir
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: Theme.gapWide }
    width: files.childW
    folder: visible ? FilesService.selected[0].path : ""
    title: visible ? FilesService.selected[0].name.toUpperCase() : ""
    onOpened: p => FilesService.go(p)
  }

  // the strips beside the side columns: drag one to widen its column
  FilesSplit {
    id: parentStrip
    visible: parentCol.visible
    x: parentCol.x + parentCol.width
    y: 0
    height: root.height
    reference: root
    onDragged: x => files.parentW = Math.max(120, Math.min(320, x - width / 2 - Theme.gapSmall))
    onFinished: FilesService.setOption("parentWidth", files.parentW)
  }

  FilesSplit {
    id: childStrip
    visible: childCol.visible
    x: childCol.x - width
    y: 0
    height: root.height
    reference: root
    onDragged: x => files.childW = Math.max(140, Math.min(340, root.width - Theme.gapSmall - x - width / 2))
    onFinished: FilesService.setOption("childWidth", files.childW)
  }

  Item {
    id: listBox
    anchors {
      top: parent.top; bottom: parent.bottom
      left: parentCol.visible ? parentCol.right : parent.left
      right: childCol.visible ? childCol.left : parent.right
      margins: Theme.gapWide
    }

    Item {
      id: captions
      visible: !files.grid
      width: parent.width
      height: nameCap.implicitHeight

      // a caption sorts by its column; the arrow shows the order
      Rectangle {
        id: nameHit
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: files.sepSizeX(captions.width)
        radius: Theme.radiusControl
        color: Theme.clear
        KitText {
          id: nameCap
          anchors { left: parent.left; leftMargin: Theme.gapLoose + Theme.iconSmall + Theme.gapMedium; verticalCenter: parent.verticalCenter }
          text: "NAME" + (FilesService.sortBy === "name" ? (FilesService.sortDesc ? " ↓" : " ↑") : "")
          color: FilesService.sortBy === "name" || nameArea.containsMouse ? Theme.foreground1 : Theme.muted
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
        }
        MouseArea { id: nameArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: FilesService.sortOn("name") }
      }

      Rectangle {
        id: sizeHit
        x: files.sepSizeX(captions.width)
        width: files.sepDateX(captions.width) - files.sepSizeX(captions.width)
        anchors { top: parent.top; bottom: parent.bottom }
        radius: Theme.radiusControl
        color: Theme.clear
        KitText {
          anchors { right: parent.right; rightMargin: Theme.gapHair; verticalCenter: parent.verticalCenter }
          text: "SIZE" + (FilesService.sortBy === "size" ? (FilesService.sortDesc ? " ↓" : " ↑") : "")
          color: FilesService.sortBy === "size" || sizeArea.containsMouse ? Theme.foreground1 : Theme.muted
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
        }
        MouseArea { id: sizeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: FilesService.sortOn("size") }
      }

      // the column separators: between name and size, size and date
      Rectangle {
        visible: !files.grid
        x: files.sepSizeX(captions.width)
        width: Theme.windowFrameWidth
        height: captions.height
        color: Theme.popupFrame
      }

      Rectangle {
        visible: !files.grid
        x: files.sepDateX(captions.width)
        width: Theme.windowFrameWidth
        height: captions.height
        color: Theme.popupFrame
      }

      Rectangle {
        id: dateHit
        x: files.sepDateX(captions.width)
        width: captions.width - files.sepDateX(captions.width)
        anchors { top: parent.top; bottom: parent.bottom }
        radius: Theme.radiusControl
        color: Theme.clear
        KitText {
          anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          text: (FilesService.inTrash ? "DELETED" : "MODIFIED") + (FilesService.sortBy === "mtime" && !FilesService.inTrash ? (FilesService.sortDesc ? " ↓" : " ↑") : "")
          color: (FilesService.sortBy === "mtime" && !FilesService.inTrash) || dateArea.containsMouse ? Theme.foreground1 : Theme.muted
          font.pixelSize: Theme.fontSize - 2
          font.letterSpacing: 1
        }
        MouseArea { id: dateArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: FilesService.sortOn("mtime") }
      }
    }

    // the column strips: drag one to widen its column (the name takes the rest)
    FilesSplit {
      id: sizeStrip
      visible: !files.grid
      stripWidth: Theme.gapSmall
      reference: captions
      x: files.sepSizeX(captions.width) - width / 2
      y: 0
      height: captions.height
      property real startX: 0
      property int startSize: 0
      onDragged: x => {
        if (startX === 0 && startSize === 0) { startX = x; startSize = files.sizeWidth; }
        files.sizeWidth = Math.max(48, Math.min(200, startSize - (x - startX)));
      }
      onFinished: { startX = 0; startSize = 0; FilesService.setOption("sizeWidth", files.sizeWidth); }
    }

    FilesSplit {
      id: dateStrip
      visible: !files.grid
      stripWidth: Theme.gapSmall
      reference: captions
      x: files.sepDateX(captions.width) - width / 2
      y: 0
      height: captions.height
      property real startX: 0
      property int startDate: 0
      onDragged: x => {
        if (startX === 0 && startDate === 0) { startX = x; startDate = files.dateWidth; }
        files.dateWidth = Math.max(80, Math.min(220, startDate - (x - startX)));
      }
      onFinished: { startX = 0; startDate = 0; FilesService.setOption("dateWidth", files.dateWidth); }
    }

    KitLine {
      id: captionLine
      visible: !files.grid
      anchors.top: captions.bottom
      anchors.topMargin: Theme.gapTight
      width: parent.width
    }

    // under the column captions (or the grid's top), and under the '..' row where there is one
    KitText {
      anchors { top: files.grid ? parent.top : captionLine.bottom; topMargin: Theme.gapLoose + (FilesService.canUp && !FilesService.searching ? 28 : 0); horizontalCenter: parent.horizontalCenter }
      visible: FilesService.shown.length === 0 && !FilesService.loading
      text: FilesService.error !== "" ? FilesService.error
          : FilesService.dupes ? "No file here has a copy."
          : FilesService.searching ? "Nothing matches \"" + FilesService.query.trim() + "\"."
          : FilesService.inTrash ? "The trash is empty." : "This folder is empty."
      color: FilesService.error !== "" ? Theme.red : Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }

    ListView {
      id: list
      visible: !files.grid
      anchors { top: captionLine.bottom; topMargin: Theme.gapTight; bottom: parent.bottom; left: parent.left; right: parent.right }
      clip: true
      model: FilesService.shown
      boundsBehavior: Flickable.StopAtBounds
      // ".." scrolls with the rows, first of them
      header: FilesUp {}

      delegate: Rectangle {
        id: row

        required property var modelData

        readonly property bool picked: FilesService.selection.includes(modelData.path)
        readonly property bool editing: files.renaming === modelData.path
      readonly property bool header: modelData.kind === "group"

        width: list.width
        height: 28
        radius: Theme.radiusControl
        color: picked ? Theme.background3 : hover.containsMouse ? Theme.background2 : Theme.clear
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        // a drag takes the selection (or this row) out to another app
        Item {
          id: dragProxy
          Drag.active: hover.drag.active
          Drag.dragType: Drag.Automatic
          Drag.supportedActions: Qt.CopyAction
          Drag.mimeData: { "text/uri-list": (row.picked ? FilesService.selection : [row.modelData.path])
                            .map(p => FilesService.fileUri(p)).join("\r\n") }
        }

        MouseArea {
          id: hover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          drag.target: row.header ? null : dragProxy
          onClicked: mouse => {
            if (row.header) {
              if (mouse.button === Qt.RightButton) files.menuAt(mapToItem(root, mouse.x, mouse.y), files.groupMenu(row.modelData));
              else FilesService.toggleGroup(row.modelData.group);
              return;
            }
            if (mouse.button === Qt.RightButton) files.contextMenu(row.modelData, mapToItem(root, mouse.x, mouse.y));
            else files.click(row.modelData, mouse);
          }
          onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) files.open(row.modelData);
          }
        }

        // the same separators as the captions, down every row
        Rectangle {
          visible: !row.header
          x: files.sepSizeX(list.width)
          width: Theme.windowFrameWidth
          height: parent.height
          color: Theme.popupFrame
        }

        Rectangle {
          visible: !row.header
          x: files.sepDateX(list.width)
          width: Theme.windowFrameWidth
          height: parent.height
          color: Theme.popupFrame
        }

        KitIcon {
          id: icon
          x: Theme.gapLoose
          anchors.verticalCenter: parent.verticalCenter
          visible: !row.header && !(row.modelData.kind === "image" && FilesService.thumbnails)
          name: files.iconFor(row.modelData.kind)
          size: Theme.iconSmall
          tint: row.modelData.link ? Theme.muted : Theme.foreground0
        }

        // an image shows as its own small picture
        Image {
          id: thumb
          x: Theme.gapLoose
          anchors.verticalCenter: parent.verticalCenter
          visible: row.modelData.kind === "image" && FilesService.thumbnails
          width: Theme.iconSmall
          height: Theme.iconSmall
          source: visible ? files.fileUrl(row.modelData.path) : ""
          sourceSize: Qt.size(36, 36)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }

        KitText {
          id: name
          x: icon.x + icon.width + Theme.gapMedium
          width: size.x - x - Theme.gapMedium
          anchors.verticalCenter: parent.verticalCenter
          visible: !row.editing
          text: row.header ? (FilesService.isCollapsed(row.modelData.group) ? "▸ " : "▾ ") + row.modelData.name
              : row.modelData.name + (row.modelData.link ? " →" : "") + ((FilesService.dupes || FilesService.searching) ? "   " + FilesService.parentOf(row.modelData.path).split("/").pop() : "")
          elide: Text.ElideRight
          font.weight: row.header || row.picked ? Font.ExtraBold : Theme.fontWeight
          color: row.header ? Theme.muted : Theme.foreground0
        }

        // a rename: the name's place, enter keeps it, escape drops it
        KitInput {
          id: renameField
          x: name.x
          width: name.width
          anchors.verticalCenter: parent.verticalCenter
          visible: row.editing
          passKeys: [Qt.Key_Escape]
          onVisibleChanged: if (visible) { text = row.modelData.name; input.selectAll(); input.forceActiveFocus(); }
          onAccepted: files.finishRename(row.modelData, text)
          onKeyPassed: { files.renaming = ""; files.forceActiveFocus(); }
        }

        KitText {
          id: size
          anchors { right: date.left; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
          width: files.sizeWidth
          horizontalAlignment: Text.AlignRight
          visible: !row.header
          text: row.modelData.kind === "dir" ? "--" : Format.humanSize(row.modelData.size)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          id: date
          anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
          width: files.dateWidth
          horizontalAlignment: Text.AlignRight
          visible: !row.header
          // while the trash is entered, the folder's rows are still there for a moment: no deleted date yet
          text: FilesService.inTrash ? (row.modelData.deleted ?? "").replace("T", " ") : files.when(row.modelData.mtime)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }
      }
    }

    GridView {
      id: grid
      visible: files.grid
      anchors.fill: parent
      clip: true
      model: FilesService.shown
      cellWidth: files.cellWidth
      cellHeight: files.cellHeight
      boundsBehavior: Flickable.StopAtBounds
      header: FilesUp {}
      onWidthChanged: FilesService.columns = Math.max(1, Math.floor(width / cellWidth))

      delegate: Rectangle {
        id: cell

        required property var modelData

        readonly property bool picked: FilesService.selection.includes(modelData.path)
        readonly property bool image: modelData.kind === "image" && FilesService.thumbnails

        width: grid.cellWidth - Theme.gapTight * 2
        height: grid.cellHeight - Theme.gapTight * 2
        radius: Theme.radiusCard
        color: picked ? Theme.background3 : cellArea.containsMouse ? Theme.background2 : Theme.clear
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        Item {
          id: cellDrag
          Drag.active: cellArea.drag.active
          Drag.dragType: Drag.Automatic
          Drag.supportedActions: Qt.CopyAction
          Drag.mimeData: { "text/uri-list": (cell.picked ? FilesService.selection : [cell.modelData.path])
                            .map(p => FilesService.fileUri(p)).join("\r\n") }
        }

        MouseArea {
          id: cellArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          drag.target: cellDrag
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton) files.contextMenu(cell.modelData, mapToItem(root, mouse.x, mouse.y));
            else files.click(cell.modelData, mouse);
          }
          onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton) files.open(cell.modelData);
          }
        }

        // a picture is its thumbnail; anything else its icon
        Image {
          anchors { top: parent.top; topMargin: Theme.gapMedium; horizontalCenter: parent.horizontalCenter }
          width: 64
          height: 64
          visible: cell.image
          source: visible ? files.fileUrl(cell.modelData.path) : ""
          sourceSize: Qt.size(128, 128)
          fillMode: Image.PreserveAspectFit
          asynchronous: true
        }

        KitIcon {
          anchors { top: parent.top; topMargin: Theme.gapMedium + 8; horizontalCenter: parent.horizontalCenter }
          visible: !cell.image
          name: files.iconFor(cell.modelData.kind)
          size: 32
          tint: cell.modelData.link ? Theme.muted : Theme.foreground0
        }

        KitText {
          anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.gapSmall }
          text: cell.modelData.name
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          maximumLineCount: 2
          elide: Text.ElideRight
          font.pixelSize: Theme.fontSize - 1
          font.weight: cell.picked ? Font.ExtraBold : Theme.fontWeight
        }
      }
    }

    // files dropped from another app land in the folder shown
    DropArea {
      anchors.fill: parent
      keys: ["text/uri-list"]
      onDropped: drop => files.dropped(drop.urls ?? [])
    }
  }
}
