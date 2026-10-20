import QtQuick
import qs.config
import qs.kit

// This computer: the storage of the system. The view button decides the look: grid (a card per
// storage, used and free space as a bar) or list (a row per storage). A mounted one opens on a
// click; a removable drive not mounted yet mounts on a click and opens. Right click for the menu.
Rectangle {
  id: root

  required property var files   // the Files window

  readonly property bool asGrid: FilesService.computerView === "grid"
  // the storage in the sort's order: by name, or by size (the largest first)
  readonly property var storage: FilesService.volumes.slice().sort((a, b) =>
    FilesService.computerSort === "size" ? b.total - a.total : a.name.localeCompare(b.name))
  readonly property int barWidth: 160       // the list's fixed columns: the used bar, then the free / total text
  readonly property int spaceWidth: 200
  readonly property int gap: Theme.gapLoose

  radius: Theme.radiusCard
  color: "transparent"
  clip: true

  function kindOf(d) { return ({ disk: "DISK", removable: "REMOVABLE", network: "NETWORK" })[d.kind] ?? "DISK"; }
  function usedOf(d) { return d.total > 0 ? (d.total - d.free) / d.total : 0; }
  function caption(d) {
    return d.mount !== "" ? kindOf(d) + " · " + (d.fstype ?? "").toUpperCase()
                          : kindOf(d) + " · NOT MOUNTED" + (d.size ? " · " + d.size : "");
  }
  function space(d) {
    return d.mount !== "" ? Format.humanSize(d.free) + " free of " + Format.humanSize(d.total) : "";
  }
  function open(d) {
    if (d.mount !== "") FilesService.go(d.mount);
    else FilesService.mountDevice(d, true);
  }
  function menu(d, at) {
    root.files.menuAt(at, [
      { label: "Open", disabled: d.mount === "", run: () => FilesService.go(d.mount) },
      { label: "Mount", disabled: d.mount !== "", run: () => FilesService.mountDevice(d, false) },
      { label: "Unmount", disabled: d.mount === "", run: () => FilesService.unmountDevice(d) },
      { label: "Properties", run: () => FilesService.deviceProperties(d) },
    ]);
  }

  KitText {
    visible: root.storage.length === 0
    anchors { left: parent.left; top: parent.top; margins: Theme.gapLoose }
    text: "No storage found"
    color: Theme.muted
  }

  // ---- grid: a card each ----
  Flickable {
    visible: root.asGrid
    anchors { fill: parent; margins: Theme.gapSmall }
    contentHeight: flow.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Grid {
      id: flow
      // as many cards as fit at ~240 px; they share the width, so the row is always full
      readonly property int cols: Math.max(1, Math.floor((width + spacing) / (240 + spacing)))
      readonly property real cardWidth: (width - spacing * (cols - 1)) / cols
      width: parent.width
      columns: cols
      spacing: Theme.gapMedium

      Repeater {
        model: root.asGrid ? root.storage : []

        Rectangle {
          id: card
          required property var modelData
          readonly property bool mounted: modelData.mount !== ""

          width: flow.cardWidth
          height: 92
          radius: Theme.radiusControl
          color: area.containsMouse ? Theme.background2 : Theme.clear
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          KitIcon {
            id: glyph
            anchors { left: parent.left; top: parent.top; leftMargin: Theme.gapLoose; topMargin: Theme.gapLoose }
            name: modelData.kind === "network" ? "server" : modelData.kind === "removable" ? "package" : "monitor"
            size: Theme.iconSmall
          }

          KitText {
            anchors { left: glyph.right; leftMargin: Theme.gapMedium; right: parent.right; rightMargin: Theme.gapLoose; top: parent.top; topMargin: Theme.gapLoose }
            text: card.modelData.name
            elide: Text.ElideRight
            font.weight: Font.ExtraBold
          }

          KitText {
            anchors { left: glyph.right; leftMargin: Theme.gapMedium; right: parent.right; rightMargin: Theme.gapLoose; top: glyph.bottom; topMargin: 2 }
            text: root.caption(card.modelData)
            elide: Text.ElideRight
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }

          KitBar {
            visible: card.mounted
            anchors { left: parent.left; right: parent.right; leftMargin: Theme.gapLoose; rightMargin: Theme.gapLoose; bottom: space.top; bottomMargin: Theme.gapTight }
            value: root.usedOf(card.modelData)
            tint: value > 0.9 ? Theme.accent : Theme.foreground1
          }

          KitText {
            id: space
            visible: card.mounted
            anchors { left: parent.left; leftMargin: Theme.gapLoose; bottom: parent.bottom; bottomMargin: Theme.gapLoose }
            text: root.space(card.modelData)
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }

          MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) root.menu(card.modelData, card.mapToItem(null, mouse.x, mouse.y));
              else root.open(card.modelData);
            }
          }
        }
      }
    }
  }

  // ---- list: a caption row, then a row each; the columns are the same for all rows ----
  Item {
    id: head
    visible: !root.asGrid
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapSmall }
    height: nameCap.implicitHeight + Theme.gapTight

    KitText {
      id: nameCap
      anchors { left: parent.left; leftMargin: Theme.gapLoose + Theme.iconSmall + Theme.gapMedium; verticalCenter: parent.verticalCenter }
      text: "NAME"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }
    KitText {
      anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
      width: root.spaceWidth
      horizontalAlignment: Text.AlignRight
      text: "FREE OF TOTAL"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }
    KitLine {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    }
  }

  Flickable {
    visible: !root.asGrid
    anchors { fill: parent; margins: Theme.gapSmall; topMargin: head.height + Theme.gapSmall }
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width
      spacing: 2

      Repeater {
        model: root.asGrid ? [] : root.storage

        Rectangle {
          id: row
          required property var modelData
          readonly property bool mounted: modelData.mount !== ""

          width: rows.width
          height: 48
          radius: Theme.radiusControl
          color: rowArea.containsMouse ? Theme.background2 : Theme.clear
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          KitIcon {
            id: rowGlyph
            anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
            name: row.modelData.kind === "network" ? "server" : row.modelData.kind === "removable" ? "package" : "monitor"
            size: Theme.iconSmall
          }

          // the name takes what the fixed columns leave
          Column {
            anchors { left: rowGlyph.right; leftMargin: Theme.gapMedium; right: spaceText.left; rightMargin: root.gap; verticalCenter: parent.verticalCenter }

            KitText {
              width: parent.width
              text: row.modelData.name
              elide: Text.ElideRight
              font.weight: Font.ExtraBold
            }
            KitText {
              width: parent.width
              text: root.caption(row.modelData)
              elide: Text.ElideRight
              color: Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }
          }

          KitText {
            id: spaceText
            anchors { right: meter.left; rightMargin: root.gap; verticalCenter: parent.verticalCenter }
            width: root.spaceWidth
            horizontalAlignment: Text.AlignRight
            text: row.mounted ? Format.humanSize(row.modelData.free) + " / " + Format.humanSize(row.modelData.total) : ""
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
          }

          KitBar {
            id: meter
            visible: row.mounted
            anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
            width: root.barWidth
            value: root.usedOf(row.modelData)
            tint: value > 0.9 ? Theme.accent : Theme.foreground1
          }

          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton) root.menu(row.modelData, row.mapToItem(null, mouse.x, mouse.y));
              else root.open(row.modelData);
            }
          }
        }
      }
    }
  }
}
