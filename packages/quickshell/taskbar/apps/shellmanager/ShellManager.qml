import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right, scrolling on its own.
//   THEMES    — a gallery of themes with live previews;
//   WALLPAPER — solid colour: the theme's or a custom one;
//   BAR     — icon style and the layout of the bar's zones;
//   PLUGINS — a tile per plugin, on / off.
Rectangle {
  id: root

  property string tab: "themes"

  readonly property var sections: [
    { value: "themes",  label: "Themes",  icon: "sun",    count: ThemeService.themes.length },
    { value: "wallpaper", label: "Wallpaper", icon: "monitor", count: -1 },
    { value: "bar",     label: "Bar",     icon: "layout", count: -1 },
    { value: "plugins", label: "Plugins", icon: "grid",
      count: BarLayout.plugins.length - BarLayout.hidden.length }
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
      y: 16
      width: parent.width - 24
      spacing: 4

      Row {
        spacing: 10
        bottomPadding: 14

        KitIcon {
          anchors.verticalCenter: parent.verticalCenter
          name: "sliders"
          size: 20
        }

        KitText {
          anchors.verticalCenter: parent.verticalCenter
          text: "Shell"
          font.pixelSize: Theme.fontSize + 3
          font.weight: Font.ExtraBold
        }
      }

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

          KitText {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            visible: item.modelData.count >= 0
            text: String(item.modelData.count)
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
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
      implicitHeight: Math.max(themes.visible ? themes.implicitHeight : 0,
                               wallpaper.visible ? wallpaper.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0,
                               plugins.visible ? plugins.implicitHeight : 0)

      ThemesPage  { id: themes;  width: parent.width; visible: root.tab === "themes" }
      WallpaperPage { id: wallpaper; width: parent.width; visible: root.tab === "wallpaper" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      PluginsPage { id: plugins; width: parent.width; visible: root.tab === "plugins" }
    }
  }

  onTabChanged: page.contentY = 0
}
