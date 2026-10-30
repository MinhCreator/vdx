import QtQuick
import Quickshell
import qs.config
import qs.kit

// The right-click menu of the file list: sections parted by lines, one row per
// item, its shortcut as a hint at the right; a row that can't act now is dimmed,
// `tone: "primary"` (the main action) takes the accent, `"danger"` the red. A
// pick, Escape or a click outside closes it. It is a surface of its own, so the
// window's edges never cut it: the compositor flips or slides it back inside the
// screen. It fades in and settles down (Motion.popups); it opens a few pixels off the pointer.
// `open(x, y, items)`, x and y in the host's (the window's) coordinates, with items
// [{label, hint, disabled, tone, run}], a {separator: true} between sections.
PopupWindow {
  id: root

  required property Item host
  property var items: []

  // the tallest it gets; past it the wheel scrolls
  readonly property int maxHeight: 720
  property real reveal: 1

  visible: false
  color: "transparent"
  implicitWidth: 260
  readonly property real dpr: panel.Screen.devicePixelRatio > 0 ? panel.Screen.devicePixelRatio : 1
  implicitHeight: Math.ceil(Math.min(column.implicitHeight + 2 * Theme.gapMedium, maxHeight) * dpr) / dpr
  grabFocus: true

  anchor.item: root.host
  anchor.edges: Edges.Top | Edges.Left
  anchor.gravity: Edges.Bottom | Edges.Right
  anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

  function open(x, y, list) {
    items = list;
    flick.contentY = 0;
    // a little off the pointer, never under it
    anchor.rect = Qt.rect(Math.round(x) + 6, Math.round(y) + 6, 1, 1);
    visible = true;
    revealAnim.stop();
    reveal = Motion.popups ? 0 : 1;
    if (Motion.popups) revealAnim.restart();
  }

  function close() { visible = false; }

  function toneColour(tone) {
    return tone === "danger" ? Theme.red : tone === "primary" ? Theme.focusRing : Theme.foreground0;
  }

  NumberAnimation { id: revealAnim; target: root; property: "reveal"; to: 1; duration: Motion.normal; easing.type: Motion.easing }

  Shortcut {
    sequences: [StandardKey.Cancel]
    context: Qt.WindowShortcut
    enabled: root.visible
    onActivated: root.close()
  }

  Rectangle {
    id: panel
    anchors.fill: parent
    radius: Theme.radiusSurface
    color: Theme.background0
    opacity: root.reveal
    transform: Translate { y: -6 * (1 - root.reveal) }

    Flickable {
      id: flick
      anchors { fill: parent; margins: Theme.gapMedium }
      contentHeight: column.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      clip: true
      interactive: contentHeight > height

      Column {
        id: column
        width: flick.width

        Repeater {
          model: root.items

          Item {
            id: entry

            required property var modelData
            readonly property bool line: modelData.separator === true

            width: column.width
            height: line ? Theme.dividerThickness + 2 * Theme.gapHair : 24

            KitLine {
              visible: entry.line
              sectionBreak: false
              anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            }

            Rectangle {
              visible: !entry.line
              anchors.fill: parent
              radius: Theme.radiusControl
              color: area.containsMouse && !entry.modelData.disabled ? Theme.controlHover : Theme.clear
              opacity: entry.modelData.disabled ? 0.4 : 1
              Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

              KitText {
                anchors { left: parent.left; leftMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                text: entry.modelData.label ?? ""
                color: root.toneColour(entry.modelData.tone)
              }

              KitText {
                anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
                visible: !!entry.modelData.hint
                text: entry.modelData.hint ?? ""
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
              }

              MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                enabled: !entry.modelData.disabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.close();
                  entry.modelData.run();
                }
              }
            }
          }
        }
      }
    }

    // the frame on top of the rows, so a stroke at the rounded corners is never overdrawn
    Rectangle {
      anchors.fill: parent
      radius: panel.radius
      color: Theme.clear
      border.width: Math.max(1, Math.round(Theme.windowFrameWidth * root.dpr)) / root.dpr
      border.color: Theme.popupFrame
    }
  }
}
