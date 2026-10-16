import QtQuick
import qs.config
import qs.kit

// Chips in bands — a settings-style row per band: its name on the left, its
// chips (icon + label) on the right, wrapping; thin lines, no boxes. Drag a chip
// along a band or to another one; a thin line marks where it lands. On release
// `dropped(id, zone, index)` says where it went — what that means is the page's.
// The band "hidden" is shown muted.
Column {
  id: board

  // the bands in order, and each band's chip ids in order
  property var zones: []
  property var idsOf: zone => []
  // a chip's label and icon; a band's text when it has no chips
  property var labelOf: id => id
  property var iconOf: id => ""
  property var emptyText: zone => "empty"

  // the drag, and the chip under the pointer (the page can show it)
  property string dragId: ""
  property string dropZone: ""        // a band's zone, or "" off the bands
  property int dropIndex: -1
  property string hoverId: ""
  readonly property int chipHeight: 28

  signal dropped(string id, string zone, int index)

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
        const p = c.mapToItem(board, c.width / 2, c.height / 2);
        if (p.y < y - board.chipHeight / 2 || (Math.abs(p.y - y) <= board.chipHeight / 2 && p.x < x)) index = j + 1;
      }
      dropZone = band.zone;
      dropIndex = index;
      return;
    }
    dropZone = "";
  }

  function release() {
    if (dragId !== "" && dropZone !== "") dropped(dragId, dropZone, dropIndex);
    dragId = "";
    dropZone = "";
    dropIndex = -1;
  }

  spacing: 0

  Repeater {
    id: bands
    model: board.zones

    Item {
      id: band

      required property string modelData
      required property int index

      readonly property string zone: modelData
      readonly property var ids: board.idsOf(modelData)
      readonly property bool target: board.dragId !== "" && board.dropZone === modelData
      readonly property alias chips: chipRepeater

      width: board.width
      height: area.height + 12

      KitText {
        y: 8 + (board.chipHeight - height) / 2
        text: band.zone.toUpperCase() + " · " + band.ids.length
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
        height: Math.max(board.chipHeight, flow.implicitHeight)
        color: band.target ? Theme.background1 : "transparent"

        Flow {
          id: flow
          width: parent.width
          spacing: Theme.gapSmall

          Repeater {
            id: chipRepeater
            model: band.ids

            Rectangle {
              id: chip

              required property string modelData
              required property int index

              width: chipRow.implicitWidth + 20
              height: board.chipHeight
              color: chipArea.containsMouse && board.dragId === "" ? Theme.background3 : Theme.background1
              opacity: board.dragId === modelData ? 0.25 : 1

              Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: Theme.gapSmall

                KitIcon {
                  anchors.verticalCenter: parent.verticalCenter
                  name: board.iconOf(chip.modelData)
                  tint: band.zone === "hidden" ? Theme.muted : Theme.foreground2
                  size: 14
                }

                KitText {
                  anchors.verticalCenter: parent.verticalCenter
                  text: board.labelOf(chip.modelData)
                  color: band.zone === "hidden" ? Theme.muted : Theme.foreground0
                  font.pixelSize: Theme.fontSize - 1
                }
              }

              // insertion marker before this chip, or after the last one
              Rectangle {
                readonly property bool after: chip.index === band.ids.length - 1 && board.dropIndex === band.ids.length
                visible: band.target && (board.dropIndex === chip.index || after)
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
                onEntered: board.hoverId = chip.modelData
                onExited: if (board.hoverId === chip.modelData) board.hoverId = ""
                onPressed: mouse => {
                  board.dragId = chip.modelData;
                  const p = mapToItem(board, mouse.x, mouse.y);
                  board.track(p.x, p.y);
                }
                onPositionChanged: mouse => {
                  if (board.dragId === "") return;
                  const p = mapToItem(board, mouse.x, mouse.y);
                  board.track(p.x, p.y);
                }
                onReleased: board.release()
              }
            }
          }
        }

        KitText {
          visible: band.ids.length === 0
          anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
          text: board.dragId !== "" ? "drop here" : board.emptyText(band.zone)
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
    visible: board.dragId !== ""
    text: board.labelOf(board.dragId)
    font.weight: Font.ExtraBold
  }
}
