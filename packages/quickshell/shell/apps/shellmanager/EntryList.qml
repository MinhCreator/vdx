import QtQuick
import qs.config
import qs.kit

// The list on the left of Modules and Shell apps: a caps title with the
// count, a search (typing jumps to the first match, arrows move through the
// matches) and a framed list of entries {id, label, icon, link?, off?}; the
// chosen one filled and bold, a link (set elsewhere) muted with an arrow, an
// entry that is off (not installed) muted. A click or an arrow emits picked(id).
Column {
  id: root

  property string title: ""
  property var model: []
  property string selected: ""
  signal picked(string id)

  property string query: ""
  readonly property var matches: model.filter(p => p.label.toLowerCase().includes(query.trim().toLowerCase()))

  function step(delta) {
    const i = matches.findIndex(p => p.id === selected);
    if (matches.length > 0) picked(matches[Math.max(0, Math.min(matches.length - 1, i < 0 ? 0 : i + delta))].id);
  }
  width: Theme.sideWidth
  height: parent.height
  spacing: Theme.gapMedium

  KitLabel {
    width: parent.width
    text: root.title
    value: String(root.model.length)
  }

  // typing jumps to the first match, arrows move through the matches
  KitInput {
    width: parent.width
    placeholder: "search"
    text: root.query
    onTextEdited: {
      root.query = text;
      if (root.matches.length > 0 && !root.matches.some(p => p.id === root.selected))
        root.picked(root.matches[0].id);
    }
    Keys.onDownPressed: root.step(1)
    Keys.onUpPressed: root.step(-1)
  }

  Rectangle {
    radius: Theme.radiusControl
    width: parent.width
    height: Math.min(root.height - y, rows.implicitHeight + 2 * Theme.frameWidth)
    color: Theme.controlFill
    border.width: Theme.frameWidth
    border.color: Theme.gray

    Flickable {
      anchors { fill: parent; margins: Theme.frameWidth }
      contentHeight: rows.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: rows
        width: parent.width

        Repeater {
          model: root.matches

          Rectangle {
            radius: Theme.radiusControl
            id: row

            required property var modelData

            readonly property bool active: modelData.id === root.selected

            width: rows.width
            height: 32
            color: active ? Theme.background3 : rowArea.containsMouse ? Theme.controlHover : Theme.clear
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

            KitIcon {
              id: rowIcon
              anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
              name: row.modelData.icon
              tint: row.active ? Theme.foreground0 : row.modelData.link || row.modelData.off ? Theme.muted : Theme.foreground2
              size: Theme.iconSmall
            }

            KitText {
              anchors { left: rowIcon.right; leftMargin: Theme.gapMedium; right: parent.right; rightMargin: row.modelData.link ? 26 : 8; verticalCenter: parent.verticalCenter }
              text: row.modelData.label
              elide: Text.ElideRight
              color: row.active || rowArea.containsMouse ? Theme.foreground0 : row.modelData.link || row.modelData.off ? Theme.muted : Theme.foreground2
              Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
              font.weight: row.active ? Font.ExtraBold : Font.DemiBold
            }

            // set elsewhere: a click goes there
            KitIcon {
              anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
              visible: !!row.modelData.link
              name: "external"
              size: 12
              tint: rowArea.containsMouse ? Theme.foreground0 : Theme.muted
            }

            MouseArea {
              id: rowArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: root.picked(row.modelData.id)
            }
          }
        }
      }
    }
  }
}
