import QtQuick
import qs.config

// A setting row: a label (and a dim hint under it) on the left, an outlined
// box with the current value and a chevron on the right. Clicking the box
// opens the choices in an outlined list under the row. Model: [{label, value}].
Column {
  id: root

  property string label: ""
  property string hint: ""
  property color hintColor: Theme.muted
  property var model: []
  property var current: null
  property bool busy: false
  property bool disabled: false
  property bool expanded: false
  property real boxWidth: width * 0.48
  // The open list floats over what follows instead of pushing it down.
  property bool overlay: false

  readonly property var selected: model.find(c => c.value === current) ?? null

  signal picked(var value)

  width: parent ? parent.width : 0
  spacing: Theme.gapSmall
  z: expanded ? 10 : 0

  onDisabledChanged: if (disabled) expanded = false

  Item {
    id: row
    width: parent.width
    height: Math.max(box.height, text.implicitHeight)

    Column {
      id: text
      anchors { left: parent.left; right: box.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      spacing: Theme.gapTight

      KitText {
        width: parent.width
        text: root.label
        elide: Text.ElideRight
      }

      KitText {
        width: parent.width
        visible: root.hint !== ""
        text: root.hint
        elide: Text.ElideRight
        color: root.hintColor
        font.pixelSize: Theme.fontSize - 2
      }
    }

    Rectangle {
      id: box
      anchors.right: parent.right
      width: root.boxWidth
      height: 30
      color: boxArea.containsMouse && !root.disabled ? Theme.background1 : "transparent"
      border.width: Theme.frameWidth
      border.color: root.expanded || boxArea.containsMouse ? Theme.foreground2 : Theme.gray
      opacity: root.disabled ? 0.4 : 1

      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
      Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

      KitText {
        anchors { left: parent.left; leftMargin: Theme.gapLoose; right: mark.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
        text: root.selected?.label ?? "—"
        elide: Text.ElideRight
      }

      Item {
        id: mark
        anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
        width: 14
        height: 14

        KitSpinner {
          anchors.centerIn: parent
          visible: root.busy
        }

        KitIcon {
          anchors.centerIn: parent
          visible: !root.busy
          name: "chevron-down"
          tint: Theme.foreground2
          size: 14
          rotation: root.expanded ? 180 : 0

          Behavior on rotation { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
        }
      }

      MouseArea {
        id: boxArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!root.disabled && !root.busy) root.expanded = !root.expanded
      }
    }
  }

  // Column lays out no zero-height child, so in overlay mode the list hangs
  // off the row (below it, over the following content) instead of the slot.
  Item {
    id: slot
    width: parent.width
    height: list.height
    visible: root.expanded && !root.overlay

    Rectangle {
      id: list
      parent: root.overlay ? row : slot
      y: root.overlay ? row.height + root.spacing : 0
      visible: root.expanded
      width: parent.width
      height: options.implicitHeight + 2 * Theme.frameWidth

      // the choices drop in: a fade and a few pixels down
      property real shown: 1
      transform: Translate { y: -6 * (1 - list.shown) }
      opacity: shown
      onVisibleChanged: if (visible && Motion.controls) dropIn.restart()
      NumberAnimation { id: dropIn; target: list; property: "shown"; from: 0; to: 1; duration: Motion.normal; easing.type: Motion.easing }
      color: root.overlay ? Theme.background0 : "transparent"
      border.width: Theme.frameWidth
      border.color: Theme.gray

      Column {
        id: options
        x: Theme.frameWidth
        y: Theme.frameWidth
        width: parent.width - 2 * Theme.frameWidth

        Repeater {
          model: root.model

          Rectangle {
            id: option

            required property var modelData

            readonly property bool active: modelData.value === root.current

            width: options.width
            height: 28
            color: active ? Theme.background3 : optionArea.containsMouse ? Theme.background1 : "transparent"

            KitText {
              anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              text: option.modelData.label
              color: option.active || optionArea.containsMouse ? Theme.foreground0 : Theme.foreground2
              font.weight: option.active ? Font.ExtraBold : Font.DemiBold
            }

            KitIcon {
              anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              visible: option.active
              name: "check"
              tint: Theme.green
              size: 14
            }

            MouseArea {
              id: optionArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (!option.active) root.picked(option.modelData.value);
                root.expanded = false;
              }
            }
          }
        }
      }
    }
  }
}
