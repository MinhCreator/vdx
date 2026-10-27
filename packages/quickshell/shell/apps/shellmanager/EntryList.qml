import QtQuick
import QtQuick.Controls as Controls
import qs.config
import qs.kit

// The list on the left of Bar modules and Apps, drawn as the Themes page's: a
// search (typing jumps to the first match, arrows move through the matches),
// then the entries {id, label, icon, link?, off?} in one raised box down to the
// pane's foot; the chosen one filled and bold, a link (set elsewhere) muted with
// an arrow, an entry that is off (not installed) muted. A click or an arrow
// emits picked(id).
Column {
  id: root

  property var model: []
  property string selected: ""
  signal picked(string id)

  property string query: ""
  readonly property var matches: model.filter(p => p.label.toLowerCase().includes(query.trim().toLowerCase()))

  onMatchesChanged: {
    if (matches.length && !matches.some(p => p.id === selected)) picked(matches[0].id);
    Qt.callLater(revealSelection);
  }
  onSelectedChanged: Qt.callLater(revealSelection)
  function revealSelection() {
    const i = matches.findIndex(p => p.id === selected);
    if (i < 0) return;
    const top = i * (Theme.navigationHeight + Theme.gapTight);
    if (top < scroller.contentY) scroller.contentY = top;
    else if (top + Theme.navigationHeight > scroller.contentY + scroller.height)
      scroller.contentY = Math.max(0, top + Theme.navigationHeight - scroller.height);
  }
  function step(delta) {
    const i = matches.findIndex(p => p.id === selected);
    if (matches.length > 0) picked(matches[Math.max(0, Math.min(matches.length - 1, i < 0 ? 0 : i + delta))].id);
  }
  width: Theme.sideWidth
  height: parent.height
  spacing: Theme.gapMedium

  // typing jumps to the first match, arrows move through the matches
  KitInput {
    width: parent.width
    placeholder: "Search…"
    icon: "search"
    text: root.query
    onTextEdited: {
      root.query = text;
      if (root.matches.length > 0 && !root.matches.some(p => p.id === root.selected))
        root.picked(root.matches[0].id);
    }
    passKeys: [Qt.Key_Up, Qt.Key_Down]
    onKeyPassed: key => root.step(key === Qt.Key_Down ? 1 : -1)
  }

  Rectangle {
    radius: Theme.radiusCard
    width: parent.width
    height: root.height - y
    color: Theme.groupFill
    border.width: Theme.material ? 0 : Theme.hairline
    border.color: Theme.controlLine

    Flickable {
      id: scroller
      Controls.ScrollBar.vertical: KitScrollBar {}
      anchors { fill: parent; margins: Theme.gapSmall }
      contentHeight: rows.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      KitEmptyState {
        visible: root.matches.length === 0
        width: parent.width
        title: root.query ? "No matches" : "Nothing to show"
        hint: root.query ? "Try a shorter search" : ""
      }
      Column {
        id: rows
        width: parent.width - Theme.gapMedium
        spacing: Theme.gapTight

        Repeater {
          model: root.matches

          Rectangle {
            radius: Theme.radiusControl
            id: row

            required property var modelData

            readonly property bool active: modelData.id === root.selected

            width: rows.width
            height: Theme.navigationHeight
            color: active ? Theme.pickFill : rowArea.containsMouse ? Theme.controlHover : Theme.clear
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

            KitIcon {
              id: rowIcon
              anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
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
              font.weight: row.active ? Theme.pickWeight : Font.Normal
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
