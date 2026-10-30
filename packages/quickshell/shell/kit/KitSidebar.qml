import QtQuick
import qs.config
import qs.kit

// The sidebar of an app's window, as Files', Music's and Shell Manager's: its
// brand header (icon, name, a subtitle) over a line level with the page's own, then one
// row per page (KitSideRow: the same icon, pick and hover as Shell Manager's NavRow).
// The window is `KitSidebar` at the left and the page at `side.right`; the page's header
// line sits at `lineY`. `model`: [{label, value, icon, hint?}]. Children go under the rows
// (a group's own captions and rows, a button).
Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property var model: []
  property string current: ""
  // the line under the brand: level with the page's header line (KitHeader + gap)
  property real lineY: Theme.windowPadding - Theme.headerInset + brand.implicitHeight + Theme.sectionGap
  default property alias extra: more.data

  signal picked(string value)

  width: Theme.sideWidth + Theme.windowPadding
  color: Theme.sideFill

  KitHeader {
    id: brand
    x: Theme.windowPadding
    y: Theme.windowPadding - Theme.headerInset
    width: root.width - 2 * Theme.windowPadding
    icon: root.icon
    title: root.title
    subtitle: root.subtitle
  }

  KitLine {
    id: line
    x: Theme.windowPadding
    y: root.lineY
    width: root.width - 2 * Theme.windowPadding
  }

  Column {
    x: Theme.windowPadding
    y: line.y + line.height + Theme.gapGroup
    width: root.width - 2 * Theme.windowPadding
    spacing: Theme.gapHair

    Repeater {
      model: root.model

      KitSideRow {
        required property var modelData
        icon: modelData.icon
        text: modelData.label
        hint: modelData.hint ?? ""
        current: modelData.value === root.current
        onClicked: root.picked(modelData.value)
      }
    }

    Column {
      id: more
      width: parent.width
      spacing: Theme.gapHair
    }
  }
}
