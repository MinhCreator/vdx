import QtQuick
import qs.config

// One stroke, no built-in margins. A Column uses Theme.sectionGap on both
// sides. Anchored/table dividers use the surrounding container's geometry.
// In grouped settings, sectionBreak ends a card; a heading replaces the
// stroke. KitGrouper sets geometry flags, never the caller's visible binding.
Rectangle {
  id: line
  property bool vertical: false
  property bool sectionBreak: true
  property bool groupManaged: false
  property bool groupCollapsed: false
  // Group backgrounds extend outside row bounds; centre the stroke between
  // the actual neighbouring surfaces, not their layout slots.
  property real strokeOffset: 0
  transform: Translate { y: line.vertical ? 0 : line.strokeOffset }
  readonly property bool isKitLine: !vertical
  readonly property bool kitUnboxed: !sectionBreak
  width: vertical ? Theme.dividerThickness : (parent ? parent.width : 0)
  implicitHeight: vertical ? (parent ? parent.height : 0)
    : groupManaged && groupCollapsed ? 0 : Theme.dividerThickness
  color: Theme.dividerColor
  opacity: groupManaged ? 0 : 1
}
