import QtQuick
import QtQuick.Controls as Controls
import qs.config

// A single solid colour from the supplied palette. No custom editor or stops.
Flow {
  id: root
  property var palette: []
  property string picked: ""
  property var colours: name => [Theme.frame, Theme.frame]
  property var icons: name => ""
  signal chosen(string name)
  function selectPalette(name) { if (palette.includes(name)) chosen(name); }
  spacing: Theme.gapMedium
  Repeater {
    model: root.palette.filter(name => name !== "custom")
    Rectangle {
      id: swatch
      required property string modelData
      readonly property bool selected: root.picked === modelData
      width: 34; height: 34
      radius: Theme.radiusControl
      color: root.colours(modelData)[0]
      activeFocusOnTab: true
      Accessible.role: Accessible.RadioButton
      Accessible.name: modelData
      Accessible.checkable: true
      Accessible.checked: selected
      Accessible.onPressAction: root.selectPalette(modelData)
      Keys.onSpacePressed: root.selectPalette(modelData)
      Keys.onReturnPressed: root.selectPalette(modelData)
      Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: Theme.clear
        border.width: Theme.focusWidth
        border.color: swatch.activeFocus ? Theme.focusRing : Theme.foreground0
        visible: swatch.selected || swatch.activeFocus
      }
      KitIcon {
        anchors.centerIn: parent
        name: swatch.selected ? "check" : root.icons(swatch.modelData)
        visible: name !== ""
        size: 16
        tint: Theme.inkOn(swatch.color)
      }
      MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectPalette(swatch.modelData) }
      Controls.ToolTip.visible: area.containsMouse
      Controls.ToolTip.text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
      Controls.ToolTip.delay: 500
    }
  }
}
