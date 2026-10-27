import QtQuick
import qs.config

// A single Files window: every sample control has a purpose in the scene.
// Local interaction changes only this specimen, never files or devices.
Column {
  id: root
  readonly property bool kitUnboxed: true
  property string caption: ""
  property bool checked: true
  property real level: 0.65
  property string choice: "name"
  width: parent ? parent.width : 0
  spacing: Theme.gapWide

  Rectangle {
    width: parent.width; height: 36
    radius: Theme.barRadiusFor(height)
    color: Theme.background1
    Row {
      x: Theme.gapWide; anchors.verticalCenter: parent.verticalCenter
      spacing: Theme.gapMedium
      KitIcon { name: "layout"; size: Theme.iconSmall }
      KitText { text: "1   2   3"; color: Theme.foreground2; font.pixelSize: Theme.fontSize - 1 }
    }
    KitText { anchors.centerIn: parent; text: "12:30"; font.pixelSize: Theme.fontSize - 1 }
    Row {
      anchors { right: parent.right; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      spacing: 3
      Repeater {
        model: [5, 12, 8, 16, 6]
        Rectangle {
          required property int modelData
          width: 3; height: modelData
          anchors.verticalCenter: parent.verticalCenter
          color: Theme.accentFor("modules", Theme.foreground2)
        }
      }
      KitIcon { name: "wifi"; size: Theme.iconSmall; anchors.verticalCenter: parent.verticalCenter }
    }
  }
  Rectangle {
    width: parent.width
    height: windowBody.implicitHeight + 2 * Theme.gapWide
    radius: Theme.radiusSurface
    color: Theme.groupFill
    border.width: Theme.hairline
    border.color: Theme.controlLine
    Column {
      id: windowBody
      x: Theme.gapWide; y: Theme.gapWide
      width: parent.width - 2 * Theme.gapWide
      spacing: Theme.sectionGap
      Row {
        width: parent.width
        spacing: Theme.gapMedium
        KitIcon { name: "folder"; size: Theme.iconSmall; anchors.verticalCenter: parent.verticalCenter }
        KitText { text: "Files"; font.weight: Font.Medium; width: parent.width - 2 * Theme.iconSmall - 2 * parent.spacing }
        KitIcon { name: "x"; size: Theme.iconSmall; tint: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
      }
      KitLine {}
      KitSegments {
        width: parent.width
        model: [{label: "Home", value: "name"}, {label: "Recent", value: "recent"}]
        current: root.choice
        onPicked: value => root.choice = value
      }
      Row {
        width: parent.width
        spacing: Theme.gapWide
        Repeater {
          model: ["Documents", "Pictures"]
          Rectangle {
            required property string modelData
            width: (windowBody.width - Theme.gapWide) / 2
            height: 90
            radius: Theme.radiusCard
            color: Theme.background0
            Column {
              anchors.centerIn: parent
              spacing: Theme.gapMedium
              KitIcon { name: "folder"; size: 28; anchors.horizontalCenter: parent.horizontalCenter }
              KitText { text: parent.parent.modelData; font.pixelSize: Theme.fontSize - 2; anchors.horizontalCenter: parent.horizontalCenter }
            }
          }
        }
      }
      KitSelect {
        width: parent.width
        label: "Sort by"
        boxWidth: Math.min(150, width * 0.55)
        model: [{label: "Name", value: "name"}, {label: "Date", value: "date"}]
        property string sort: "name"
        current: sort
        onPicked: value => sort = value
      }
      Row {
        width: parent.width
        spacing: Theme.gapMedium
        KitText { width: Math.max(40, parent.width - hiddenSwitch.width - parent.spacing); text: "Hidden files"; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.fontSize - 1 }
        KitSwitch { id: hiddenSwitch; checked: root.checked; onToggled: root.checked = !checked; accessibleName: "Preview hidden files" }
      }
      KitText { text: "Icon size"; color: Theme.muted; font.pixelSize: Theme.fontSize - 1 }
      KitSlider { width: parent.width; height: Theme.controlHeight; value: root.level; onMoved: value => root.level = value; accessibleName: "Preview icon size" }
    }
  }
}
