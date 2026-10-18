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
  // The box takes the standard width (KitRow's, so the right edges line up) when
  // the row has room for it; a narrower row gives the label half of it (less the
  // gap). It never grows past the standard width: a long choice elides in the box.
  property real boxWidth: Math.min(width, Math.max(Math.min(choiceWidth, Theme.controlWidth),
    Math.min(Theme.controlWidth, (width - Theme.gapWide) / 2)))
  // The open list floats over what follows instead of pushing it down.
  property bool overlay: false

  readonly property var selected: model.find(c => c.value === current) ?? null

  // the width the widest choice needs: its text in the font, plus the box's
  // and the list's own padding (text margin, chevron or check, gaps)
  readonly property real choiceWidth: {
    let widest = 0;
    for (let i = 0; i < choiceSizes.count; i++) widest = Math.max(widest, choiceSizes.objectAt(i).advanceWidth);
    return Math.ceil(widest) + 2 * Theme.gapLoose + Theme.iconSmall + Theme.gapSmall;
  }

  // a hidden measure of every choice's text, in the box's font
  Item {
    visible: false
    Instantiator {
      id: choiceSizes
      model: root.model

      TextMetrics {
        required property var modelData
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        text: modelData.label
      }
    }
  }

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
      height: Theme.controlHeight
      radius: Theme.radiusControl
      color: boxArea.containsMouse && !root.disabled ? Theme.controlHover : Theme.controlFill
      border.width: Theme.frameWidth
      border.color: root.expanded ? Theme.accentFor("selects", Theme.foreground2)
        : boxArea.containsMouse ? Theme.foreground2 : Theme.gray
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
          size: Theme.iconSmall
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
  // The list spans the whole row: the box's width is for the closed control only.
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
      x: 0
      height: options.implicitHeight + 2 * inset
      radius: Theme.radiusControl
      // round corners keep the rows off the frame's curve
      readonly property int inset: Theme.frameWidth + (Theme.round ? 3 : 0)

      // the choices drop in: a fade and a few pixels down
      property real shown: 1
      transform: Translate { y: -6 * (1 - list.shown) }
      opacity: shown
      onVisibleChanged: if (visible && Motion.controls) dropIn.restart()
      NumberAnimation { id: dropIn; target: list; property: "shown"; from: 0; to: 1; duration: Motion.normal; easing.type: Motion.easing }
      color: Theme.material ? Theme.background1 : root.overlay ? Theme.background0 : Theme.clear
      border.width: Theme.frameWidth
      border.color: Theme.gray

      Column {
        id: options
        x: list.inset
        y: list.inset
        width: parent.width - 2 * list.inset

        Repeater {
          model: root.model

          Rectangle {
            id: option

            required property var modelData

            readonly property bool active: modelData.value === root.current

            width: options.width
            height: 28
            radius: Math.max(0, Theme.radiusControl - 2)
            color: active ? Theme.background3 : optionArea.containsMouse ? Theme.controlHover : Theme.clear
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

            KitText {
              anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              text: option.modelData.label
              color: option.active || optionArea.containsMouse ? Theme.foreground0 : Theme.foreground2
              Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
              font.weight: option.active ? Font.ExtraBold : Font.DemiBold
            }

            KitIcon {
              anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              visible: option.active
              name: "check"
              tint: Theme.green
              size: Theme.iconSmall
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
