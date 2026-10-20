import QtQuick
import qs.config
import qs.kit

// A row's menu, drawn as FilesMenu: opened at its ⋮ button, closed by a click anywhere
// else. `items`: [{label, note?, danger?, disabled?, line?, run}] — `line: true`
// is a hairline between groups. `host` is the item the menu floats in (the window).
Item {
  id: root

  property Item host: null
  property string title: ""
  property var items: []
  property bool open: false

  readonly property int menuWidth: 248

  anchors.fill: parent
  visible: open

  // the ⋮ button's top and bottom in the host: the panel sits under it, or above when there is no room
  property real anchorTop: 0
  property real anchorBottom: 0

  // opened at `anchor` (the ⋮ button)
  function show(heading, list, anchor) {
    title = heading;
    items = list;
    const at = anchor.mapToItem(host, 0, 0);
    panel.x = Math.max(Theme.gapMedium, Math.min(at.x + anchor.width - menuWidth, host.width - menuWidth - Theme.gapMedium));
    anchorTop = at.y;
    anchorBottom = at.y + anchor.height;
    open = true;
  }

  function close() { open = false; }

  // a click outside the panel closes it
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: root.close()
  }

  Rectangle {
    id: panel

    width: root.menuWidth
    height: list.implicitHeight + 2 * Theme.gapTight
    // a binding, not a value set once: the rows' height is laid out before the frame is drawn
    y: root.anchorBottom + Theme.gapHair + height > root.height - Theme.gapMedium
       ? Math.max(Theme.gapMedium, root.anchorTop - height - Theme.gapHair) : root.anchorBottom + Theme.gapHair
    radius: Theme.radiusSurface
    color: Theme.background0
    border.width: Theme.windowFrameWidth
    border.color: Theme.popupFrame

    Column {
      id: list
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapTight }
      spacing: Theme.gapHair

      KitText {
        visible: root.title !== ""
        x: Theme.gapMedium
        width: parent.width - 2 * Theme.gapMedium
        topPadding: Theme.gapHair
        text: root.title
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
      }

      KitLine { visible: root.title !== "" }

      Repeater {
        model: root.items

        Item {
          id: entry

          required property var modelData

          width: list.width
          height: modelData.line ? hairline.height : row.implicitHeight

          KitLine { id: hairline; visible: entry.modelData.line === true }

          MusicMenuRow {
            id: row
            visible: entry.modelData.line !== true
            label: entry.modelData.label ?? ""
            note: entry.modelData.note ?? ""
            danger: entry.modelData.danger === true
            disabled: entry.modelData.disabled === true
            onActivated: {
              root.close();
              entry.modelData.run();
            }
          }
        }
      }
    }
  }
}
