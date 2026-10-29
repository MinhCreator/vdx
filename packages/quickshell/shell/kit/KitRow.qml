import QtQuick
import qs.config

// A setting row: a label and a dim hint under it on the left, a control (a
// switch, a button, a value) on the right (children).
//
// `wide`: the control is a set of choices or a field — it gets the standard
// width (Theme.controlWidth, so the right edges line up down a page); a narrow
// row keeps Theme.rowLabelMin for the label and the control gives way, and under
// Theme.rowStackBelow it goes under the label, full width. Give a wide KitChoices `stretch: true`.
//
// `needs`: what this row waits for, in one phrase ("Island style only", "Needs Live
// activities on"): the row stays in sight, its control out of reach, the phrase where the
// hint was and, if `needsAction` is set, one button that fixes it (needsActed()). The
// search index reads the phrase as the row's hint. The one dependency pattern of every page.
Item {
  id: root

  property string label: ""
  property string hint: ""
  property string tip: ""           // an explanation behind an info mark: a tooltip, the row stays one line
  property string tipLevel: "info"  // KitTip: info | ok | warn | danger
  property string hintLevel: "info" // warn | danger tint the hint: a caveat the reader must see, so it is never a tooltip
  property color labelColor: Theme.foreground0
  property bool wide: false
  property bool dimmed: false       // its option is unavailable (the adapter is off)
  property string needs: ""         // what it waits for: see above
  property string needsAction: ""   // the button that fixes it ("Use Island")
  signal needsActed()

  readonly property bool stacked: wide && width < Theme.rowStackBelow

  default property alias trailing: slot.data

  width: parent ? parent.width : 0
  opacity: dimmed ? 0.4 : needs !== "" ? 0.6 : 1
  implicitHeight: stacked ? text.implicitHeight + Theme.gapWide + slot.height
                          : Math.max(Theme.rowHeight, text.implicitHeight, slot.height)

  Column {
    id: text
    anchors {
      left: parent.left
      right: root.stacked ? parent.right : fix.visible ? fix.left : slot.left
      rightMargin: root.stacked ? 0 : 12
    }
    y: root.stacked ? 0 : (root.height - height) / 2
    spacing: Theme.gapTight

    Row {
      width: parent.width
      spacing: Theme.gapMedium

      KitText {
        width: Math.min(implicitWidth, parent.width - (tip.visible ? tip.width + parent.spacing : 0))
        text: root.label
        color: root.labelColor
        elide: Text.ElideRight
      }

      KitTip {
        id: tip
        visible: root.tip !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.tip
        level: root.tipLevel
      }
    }

    KitText {
      width: parent.width
      visible: root.hint !== "" || root.needs !== ""
      text: root.needs !== "" ? root.needs : root.hint
      color: root.hintLevel === "warn" ? Theme.yellow : root.hintLevel === "danger" ? Theme.red : Theme.muted
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }
  }

  // the one button that fixes what the row needs
  KitButton {
    id: fix
    visible: root.needs !== "" && root.needsAction !== ""
    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    text: root.needsAction
    onClicked: root.needsActed()
  }

  Row {
    id: slot
    visible: root.needs === ""
    anchors.right: parent.right
    y: root.stacked ? text.height + Theme.gapWide : (root.height - height) / 2
    spacing: Theme.gapMedium
  }

  // the one control of a wide row takes the standard width
  Binding {
    when: root.wide && slot.children.length > 0
    target: slot.children.length > 0 ? slot.children[0] : null
    property: "width"
    value: root.stacked ? root.width : Math.min(Theme.controlWidth, root.width - Theme.rowLabelMin)
  }
}
