import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right, scrolling on its own.
//   APPEARANCE — theme, wallpaper and icon style under one live preview;
//   BAR        — the layout of the bar's zones, icon style, modules on / off.
Rectangle {
  id: root

  property string tab: "appearance"

  readonly property var sections: [
    { value: "appearance", label: "Appearance", icon: "sun" },
    { value: "bar",        label: "Bar",        icon: "layout" }
  ]

  color: Theme.background0

  // ---- navigation --------------------------------------------------------------
  Rectangle {
    id: sidebar
    width: 190
    height: parent.height
    color: Theme.background0

    Column {
      x: 12
      y: 20
      width: parent.width - 24
      spacing: 4

      Repeater {
        model: root.sections

        Rectangle {
          id: item

          required property var modelData

          readonly property bool active: modelData.value === root.tab

          width: parent.width
          height: 34
          color: active ? Theme.background3 : itemArea.containsMouse ? Theme.background1 : "transparent"

          KitIcon {
            id: itemIcon
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            name: item.modelData.icon
            tint: item.active ? Theme.foreground0 : Theme.foreground2
            size: 16
          }

          KitText {
            anchors { left: itemIcon.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: item.modelData.label
            color: item.active ? Theme.foreground0 : Theme.foreground2
            font.weight: item.active ? Font.ExtraBold : Font.DemiBold
          }


          MouseArea {
            id: itemArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: item.active ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: root.tab = item.modelData.value
          }
        }
      }
    }

    KitText {
      anchors { left: parent.left; leftMargin: 22; bottom: parent.bottom; bottomMargin: 14 }
      text: "esc to close"
      color: Theme.gray
      font.pixelSize: Theme.fontSize - 2
    }
  }

  // hairline between navigation and page
  Rectangle {
    anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
    width: 1
    color: Theme.background3
  }

  // ---- page --------------------------------------------------------------------
  Flickable {
    id: page
    anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
    contentHeight: pages.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Item {
      id: pages
      x: 24
      y: 20
      width: page.width - 48
      implicitHeight: Math.max(appearance.visible ? appearance.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
    }
  }

  onTabChanged: {
    if (tab === "themes" || tab === "wallpaper") tab = "appearance";
    else if (tab === "plugins") tab = "bar";
    page.contentY = 0;
  }
}
