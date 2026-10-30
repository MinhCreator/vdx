import QtQuick
import qs.config
import qs.kit

// The folder shown: as a list (folders as tiles above, Settings › Folders as tiles; then the files as a
// table in one raised box: a box to tick, the name, the type, size and date, ⋮ for the menu), as a grid
// of cards, or as columns (the parent and the selected folder beside the list). Files dropped from
// another app land in it.
Item {
  id: root

  required property var files   // the Files window
  property alias listView: list
  property alias gridView: grid
  // the list's own rows: the files only while the folders stand above as tiles
  readonly property var listModel: files.tiles ? files.svc.shown.filter(e => e.kind !== "dir") : files.svc.shown
  readonly property var folders: files.tiles ? files.svc.shown.filter(e => e.kind === "dir") : []
  readonly property int rowH: files.svc.rowHeight
  // the icon's slot in a row: a thumbnail takes the same, so the names line up
  readonly property int slot: Math.min(rowH - 10, 24)
  readonly property int allRows: files.svc.rows.length
  readonly property int picked: files.svc.selection.length

  // the Columns view: the parent folder on the left, the selected folder on the right
  FilesColumn {
    svc: root.files.svc
    id: parentCol
    visible: files.columnsView && files.svc.canUp
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    width: files.parentW
    folder: visible ? files.svc.parentOf(files.svc.path) : ""
    highlight: files.svc.path
    title: "PARENT"
    onOpened: p => files.svc.go(p)
  }

  FilesColumn {
    svc: root.files.svc
    id: childCol
    visible: files.columnsView && files.selectedDir
    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
    width: files.childW
    folder: visible ? files.svc.selected[0].path : ""
    title: visible ? files.svc.selected[0].name.toUpperCase() : ""
    onOpened: p => files.svc.go(p)
  }

  // the strips beside the side columns: drag one to widen its column
  FilesSplit {
    id: parentStrip
    visible: parentCol.visible
    x: parentCol.x + parentCol.width
    y: 0
    height: root.height
    reference: root
    onDragged: x => files.parentW = Math.max(120, Math.min(320, x - width / 2))
    onFinished: files.svc.setOption("parentWidth", files.parentW)
  }

  FilesSplit {
    id: childStrip
    visible: childCol.visible
    x: childCol.x - width
    y: 0
    height: root.height
    reference: root
    onDragged: x => files.childW = Math.max(140, Math.min(340, root.width - x - width / 2))
    onFinished: files.svc.setOption("childWidth", files.childW)
  }

  Item {
    id: listBox
    anchors {
      top: parent.top; bottom: parent.bottom
      left: parentCol.visible ? parentStrip.right : parent.left
      right: childCol.visible ? childStrip.left : parent.right
    }

    // nothing here: under the Up row
    KitText {
      anchors { top: parent.top; topMargin: Theme.gapGroup + (files.svc.canUp && !files.svc.searching ? root.rowH : 0); horizontalCenter: parent.horizontalCenter }
      visible: files.svc.shown.length === 0 && !files.svc.loading
      text: files.svc.error !== "" ? files.svc.error
          : files.svc.dupes ? "No file here has a copy."
          : files.svc.searching || files.svc.query.trim() !== "" ? "Nothing matches \"" + files.svc.query.trim() + "\""
          : files.svc.inTrash ? "The trash is empty."
          : files.svc.atRecent ? "No file opened lately."
          : files.svc.atStarred ? "Nothing starred: right click › Star."
          : "This folder is empty."
      color: files.svc.error !== "" ? Theme.red : Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }

    ListView {
      id: list
      visible: !files.grid
      anchors.fill: parent
      clip: true
      model: root.listModel
      boundsBehavior: Flickable.StopAtBounds
      // the header grows and shrinks as the rows come (the captions, the tiles): a list at its top stays there
      property real lastOrigin: 0
      onOriginYChanged: { if (contentY <= lastOrigin + 1) contentY = originY; lastOrigin = originY; }
      // the Up row, the folders' tiles and the table's captions scroll with the rows
      header: Column {
        id: head
        width: list.width
        // where the table's box starts: its captions
        readonly property real boxTop: captions.y

        FilesUp { svc: root.files.svc; height: active ? root.rowH : 0 }

        // ---- the folders, as tiles ----
        Item {
          width: parent.width
          height: visible ? foldersLabel.height + Theme.gapMedium : 0
          visible: root.folders.length > 0
          KitLabel { id: foldersLabel; width: parent.width; text: "FOLDERS"; value: root.folders.length + "" }
        }

        Grid {
          id: tiles
          readonly property int across: Math.max(1, Math.floor((head.width + Theme.gapMedium) / (176 + Theme.gapMedium)))
          visible: root.folders.length > 0
          width: parent.width
          columns: across
          spacing: Theme.gapMedium

          Repeater {
            model: root.folders
            FilesTile {
              required property var modelData
              files: root.files
              entry: modelData
              width: (head.width - (tiles.across - 1) * Theme.gapMedium) / tiles.across
            }
          }
        }

        Item {
          width: parent.width
          height: visible ? Theme.gapGroup + filesLabel.height + Theme.gapMedium : 0
          visible: root.folders.length > 0 && root.listModel.length > 0
          KitLabel { id: filesLabel; anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.gapMedium; width: parent.width; text: "FILES"; value: root.listModel.length + "" }
        }

        // ---- the table's captions: a caption sorts by its column, the arrow shows the order ----
        Item {
          id: captions
          visible: root.listModel.length > 0
          width: parent.width
          height: visible ? 34 : 0
          readonly property var c: files.cols(width)

          // over the NAME caption (it starts at 0 and would take the click: a sort, not a select)
          FilesCheck {
            z: 1
            visible: files.svc.checkboxes && !files.picker
            x: Theme.gapWide
            anchors.verticalCenter: parent.verticalCenter
            checked: root.allRows > 0 && root.picked === root.allRows
            partial: root.picked > 0
            onToggled: { if (root.picked > 0) files.svc.selection = []; else files.svc.selectAll(); }
          }

          FilesCaption { svc: root.files.svc;
            x: 0
            width: captions.c.nameEnd
            height: parent.height
            textX: files.nameX
            text: "NAME"
            key: "name"
          }
          FilesCaption { svc: root.files.svc;
            visible: !!captions.c.kind
            x: captions.c.kind ? captions.c.kind.x : 0
            width: captions.c.kind ? captions.c.kind.w : 0
            height: parent.height
            text: "TYPE"
            key: ""
          }
          FilesCaption { svc: root.files.svc;
            visible: !!captions.c.size
            x: captions.c.size ? captions.c.size.x : 0
            width: captions.c.size ? captions.c.size.w : 0
            height: parent.height
            alignRight: true
            text: "SIZE"
            key: "size"
          }
          FilesCaption { svc: root.files.svc;
            visible: !!captions.c.date
            x: captions.c.date ? captions.c.date.x : 0
            width: captions.c.date ? captions.c.date.w : 0
            height: parent.height
            alignRight: true
            text: files.svc.inTrash ? "DELETED" : files.svc.atRecent ? "OPENED" : "MODIFIED"
            key: files.svc.inTrash || files.svc.atRecent ? "" : "mtime"
          }

          // the column separators, down the captions and every row
          Repeater {
            model: captions.c.seps
            KitLine { required property real modelData; x: modelData; y: Theme.gapMedium; vertical: true; height: captions.height - 2 * Theme.gapMedium;  }
          }

          // the strips on the separators of size and date: drag one to widen its column (the name takes the rest)
          FilesSplit {
            visible: !!captions.c.size
            stripWidth: Theme.gapSmall
            reference: captions
            x: (captions.c.size ? captions.c.size.x : 0) - Theme.gapWide / 2 - width / 2
            height: captions.height
            property real startX: 0
            property int startSize: 0
            onDragged: x => {
              if (startX === 0 && startSize === 0) { startX = x; startSize = files.sizeWidth; }
              files.sizeWidth = Math.max(48, Math.min(200, startSize - (x - startX)));
            }
            onFinished: { startX = 0; startSize = 0; files.svc.setOption("sizeWidth", files.sizeWidth); }
          }

          FilesSplit {
            visible: !!captions.c.date
            stripWidth: Theme.gapSmall
            reference: captions
            x: (captions.c.date ? captions.c.date.x : 0) - Theme.gapWide / 2 - width / 2
            height: captions.height
            property real startX: 0
            property int startDate: 0
            onDragged: x => {
              if (startX === 0 && startDate === 0) { startX = x; startDate = files.dateWidth; }
              files.dateWidth = Math.max(80, Math.min(220, startDate - (x - startX)));
            }
            onFinished: { startX = 0; startDate = 0; files.svc.setOption("dateWidth", files.dateWidth); }
          }

          KitLine { anchors.bottom: parent.bottom; x: Theme.gapWide; width: parent.width - 2 * Theme.gapWide; sectionBreak: false;  }
        }
      }

      // the room under the box's last row
      footer: Item { width: list.width; height: root.listModel.length > 0 ? Theme.gapSmall : 0 }

      // the table's box: from its captions to its last row
      Rectangle {
        parent: list.contentItem
        z: -1
        visible: root.listModel.length > 0 && list.headerItem !== null
        y: list.headerItem ? list.headerItem.y + list.headerItem.boxTop : 0
        width: list.width
        height: list.contentHeight + list.originY - y
        radius: Theme.radiusCard
        color: Theme.background1
      }

      delegate: Item {
        id: row

        required property var modelData
        required property int index

        readonly property bool picked: files.svc.selection.includes(modelData.path)
        readonly property bool editing: files.renaming === modelData.path
        readonly property bool header: modelData.kind === "group"
        readonly property bool hovered: hover.containsMouse || dots.containsMouse
        readonly property var c: files.cols(width)

        width: list.width
        height: root.rowH

        // the row's fill, inset in the box
        Rectangle {
          anchors { fill: parent; leftMargin: Theme.gapHair; rightMargin: Theme.gapHair }
          radius: Theme.radiusControl
          color: row.picked ? Theme.background3 : row.hovered ? Theme.background2 : Theme.clear
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
        }

        // the hairline between rows
        KitLine {
          visible: row.index > 0 && !row.picked
          x: Theme.gapWide
          width: parent.width - 2 * Theme.gapWide
          sectionBreak: false

        }

        // a drag takes the selection (or this row) out to another app
        Item {
          id: dragProxy
          Drag.active: hover.drag.active
          Drag.dragType: Drag.Automatic
          Drag.supportedActions: Qt.CopyAction
          Drag.mimeData: { "text/uri-list": (row.picked ? files.svc.selection : [row.modelData.path])
                            .map(p => files.svc.fileUri(p)).join("\r\n") }
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
              if (mouse.button === Qt.RightButton) files.menuAt(mapToItem(null, mouse.x, mouse.y), files.groupMenu(row.modelData));
              else files.svc.toggleGroup(row.modelData.group);
              return;
            }
            if (mouse.button === Qt.RightButton) files.contextMenu(row.modelData, mapToItem(null, mouse.x, mouse.y));
            else files.click(row.modelData, mouse);
          }
          onDoubleClicked: mouse => {
            if (mouse.button === Qt.LeftButton && !row.header) files.open(row.modelData);
          }
        }

        Repeater {
          model: row.header ? [] : row.c.seps
          KitLine { required property real modelData; x: modelData; y: Theme.gapSmall; vertical: true; height: row.height - 2 * Theme.gapSmall;  }
        }

        FilesCheck {
          visible: files.svc.checkboxes && !row.header && !files.picker
          x: Theme.gapWide
          anchors.verticalCenter: parent.verticalCenter
          checked: row.picked
          shown: row.hovered || root.picked > 0
          onToggled: files.svc.select(row.modelData.path, "toggle")
        }

        KitIcon {
          id: icon
          x: files.nameX + (root.slot - width) / 2
          anchors.verticalCenter: parent.verticalCenter
          visible: !row.header && !(row.modelData.kind === "image" && files.svc.thumbnails)
          name: files.iconFor(row.modelData.kind)
          size: Theme.iconSmall + 2
          tint: row.modelData.link ? Theme.muted : Theme.foreground0
        }

        // an image shows as its own small picture
        Image {
          x: files.nameX
          anchors.verticalCenter: parent.verticalCenter
          visible: row.modelData.kind === "image" && files.svc.thumbnails
          width: root.slot
          height: width
          source: visible ? files.fileUrl(row.modelData.path) : ""
          sourceSize: Qt.size(56, 56)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }

        KitText {
          id: name
          x: row.header ? Theme.gapWide : files.nameX + root.slot + Theme.gapMedium
          width: row.c.nameEnd - x - (files.svc.isStarred(row.modelData.path) ? 22 : 0)
          anchors.verticalCenter: parent.verticalCenter
          visible: !row.editing
          text: row.header ? (files.svc.isCollapsed(row.modelData.group) ? "▸ " : "▾ ") + row.modelData.name
              : files.svc.shownName(row.modelData) + (row.modelData.link ? " →" : "")
          elide: Text.ElideRight
          font.weight: row.header || row.picked ? Font.ExtraBold : Theme.fontWeight
          color: row.header ? Theme.muted : Theme.foreground0
        }

        // a search, the recent files, duplicates: the folder each is in, after the name
        KitText {
          visible: !row.header && !row.editing && (files.svc.searching || files.svc.virtual) && !files.svc.inTrash
          x: name.x + name.contentWidth + Theme.gapMedium
          width: Math.max(0, row.c.nameEnd - x)
          anchors.verticalCenter: parent.verticalCenter
          text: files.svc.parentOf(row.modelData.path).replace(files.svc.home, "~")
          elide: Text.ElideMiddle
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        KitIcon {
          visible: !row.header && files.svc.isStarred(row.modelData.path)
          x: row.c.nameEnd - 18
          anchors.verticalCenter: parent.verticalCenter
          name: "star"
          solid: true
          size: Theme.iconSmall
          tint: Theme.foreground2
        }

        // a rename: the name's place, enter keeps it, escape drops it
        KitInput {
          x: name.x
          width: row.c.nameEnd - x
          anchors.verticalCenter: parent.verticalCenter
          visible: row.editing
          passKeys: [Qt.Key_Escape]
          onVisibleChanged: if (visible) { text = row.modelData.name; input.selectAll(); input.forceActiveFocus(); }
          onAccepted: files.finishRename(row.modelData, text)
          onKeyPassed: { files.renaming = ""; files.forceActiveFocus(); }
        }

        KitText {
          visible: !row.header && !!row.c.kind
          x: row.c.kind ? row.c.kind.x : 0
          width: row.c.kind ? row.c.kind.w : 0
          anchors.verticalCenter: parent.verticalCenter
          text: files.kindLabel(row.modelData)
          elide: Text.ElideRight
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          visible: !row.header && !!row.c.size
          x: row.c.size ? row.c.size.x : 0
          width: row.c.size ? row.c.size.w : 0
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignRight
          text: files.sizeLabel(row.modelData)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          visible: !row.header && !!row.c.date
          x: row.c.date ? row.c.date.x : 0
          width: row.c.date ? row.c.date.w : 0
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignRight
          // while the trash is entered, the folder's rows are still there for a moment: no deleted date yet
          text: files.svc.inTrash ? (row.modelData.deleted ?? "").replace("T", " ")
              : files.svc.atRecent && row.modelData.visited ? files.when(Date.parse(row.modelData.visited) / 1000)
              : files.when(row.modelData.mtime)
          elide: Text.ElideLeft
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        // ⋮: the row's menu
        Rectangle {
          visible: files.svc.rowActions && !row.header
          anchors { right: parent.right; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
          width: 24
          height: 24
          radius: Theme.radiusFor(height)
          opacity: row.hovered || row.picked ? 1 : 0
          color: dots.containsMouse ? Theme.hoverOn(true) : Theme.clear
          Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }

          KitIcon { anchors.centerIn: parent; name: "more"; size: Theme.iconSmall + 2; tint: Theme.foreground2 }

          MouseArea {
            id: dots
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => files.contextMenu(row.modelData, mapToItem(null, mouse.x, mouse.y))
          }
        }
      }
    }

    // ---- the grid: a card per entry ----
    GridView {
      id: grid
      visible: files.grid
      anchors.fill: parent
      clip: true
      model: files.svc.shown
      readonly property int size: ({ small: 104, medium: 128, large: 164 })[files.svc.gridSize] ?? 128
      // the cards fill the width: as many as fit, stretched to it
      cellWidth: Math.floor(width / Math.max(1, Math.floor(width / size)))
      cellHeight: size + 8
      boundsBehavior: Flickable.StopAtBounds
      header: FilesUp { svc: root.files.svc; height: active ? root.rowH : 0 }
      onWidthChanged: files.svc.columns = Math.max(1, Math.floor(width / size))

      delegate: Item {
        id: cell

        required property var modelData

        readonly property bool picked: files.svc.selection.includes(modelData.path)
        readonly property bool image: modelData.kind === "image" && files.svc.thumbnails
        readonly property int art: grid.size - 56

        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
          id: card
          anchors { fill: parent; margins: Theme.gapHair }
          radius: Theme.radiusCard
          color: cell.picked ? Theme.background3 : cellArea.containsMouse ? Theme.background2 : Theme.background1
          border.width: cellDrop.containsDrag ? 2 : 0
          border.color: Theme.foreground2
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          Item {
            id: cellDrag
            Drag.active: cellArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: { "text/uri-list": (cell.picked ? files.svc.selection : [cell.modelData.path])
                              .map(p => files.svc.fileUri(p)).join("\r\n") }
          }

          MouseArea {
            id: cellArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            drag.target: cellDrag
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) files.contextMenu(cell.modelData, mapToItem(null, mouse.x, mouse.y));
              else files.click(cell.modelData, mouse);
            }
            onDoubleClicked: mouse => {
              if (mouse.button === Qt.LeftButton) files.open(cell.modelData);
            }
          }

          // a picture is its thumbnail, in a well; anything else its icon
          Rectangle {
            id: well
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: Theme.gapMedium }
            height: cell.art
            radius: Theme.radiusControl
            color: Theme.background0
            clip: true

            Image {
              anchors.fill: parent
              visible: cell.image
              source: visible ? files.fileUrl(cell.modelData.path) : ""
              sourceSize: Qt.size(256, 256)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }

            KitIcon {
              anchors.centerIn: parent
              visible: !cell.image
              name: files.iconFor(cell.modelData.kind)
              solid: cell.modelData.kind === "dir"
              size: Math.round(cell.art * 0.5)
              tint: cell.modelData.link ? Theme.muted : Theme.foreground1
            }
          }

          KitText {
            anchors { left: parent.left; right: parent.right; top: well.bottom; topMargin: Theme.gapSmall; leftMargin: Theme.gapMedium; rightMargin: Theme.gapMedium }
            text: files.svc.shownName(cell.modelData)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            font.pixelSize: Theme.fontSize - 1
            font.weight: cell.picked ? Font.ExtraBold : Theme.fontWeight
          }

          KitText {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: Theme.gapSmall; leftMargin: Theme.gapMedium; rightMargin: Theme.gapMedium }
            text: files.sizeLabel(cell.modelData)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }

          DropArea {
            id: cellDrop
            anchors.fill: parent
            enabled: cell.modelData.kind === "dir"
            keys: ["text/uri-list"]
            onDropped: drop => files.dropped(drop.urls ?? [], cell.modelData.path)
          }
        }
      }
    }

    // files dropped from another app land in the folder shown
    DropArea {
      anchors.fill: parent
      z: -1
      keys: ["text/uri-list"]
      onDropped: drop => files.dropped(drop.urls ?? [], files.svc.path)
    }
  }
}
