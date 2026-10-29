import QtQuick

// The optional item at the left of a KitFoldRow's name (a sample of the thing): a Loader
// that sits after the handle's column and vertically in the row's first line.
Loader {
  property Component component: null

  sourceComponent: component
  active: component !== null
  anchors { left: parent.left; leftMargin: parent.indent; top: parent.top; topMargin: (parent.rowHeight - (item ? item.height : 0)) / 2 }
}
