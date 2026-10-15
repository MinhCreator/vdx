import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right, scrolling on its own. Under the
// open section its groups (`jumps` of the page) jump there on a click.
//   APPEARANCE — theme, wallpaper and icon style under one live preview;
//   BAR        — the layout of the bar's zones, icon style, modules on / off.
//   PLUGINS    — each plugin's own options.
Rectangle {
  id: root

  property string tab: "appearance"

  readonly property var sections: [
    { value: "appearance", label: "Appearance", icon: "sun" },
    { value: "bar",        label: "Bar",        icon: "layout" },
    { value: "plugins",    label: "Plugins",    icon: "grid" }
  ]

  readonly property Item currentPage: tab === "bar" ? bar : tab === "plugins" ? plugins : appearance

  // the group the page shows at its top; a clicked one stays marked while the
  // page can't scroll it up there (the last groups)
  property string pinnedJump: ""
  readonly property string currentJump: {
    if (pinnedJump !== "") return pinnedJump;
    if (tab === "plugins") return plugins.selected;
    const list = currentPage.jumps;
    let key = list.length > 0 ? list[0].key : "";
    for (const j of list) if (j.y + 20 <= page.contentY + 40) key = j.key;
    return key;
  }

  function jumpTo(j) {
    if (j.y < 0) { currentPage.jump(j.key); return; }
    const max = Math.max(0, page.contentHeight - page.height);
    scroll.to = Math.min(max, Math.max(0, j.y));
    scroll.restart();
    pinnedJump = j.key;
  }

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

        Column {
          id: section

          required property var modelData

          readonly property bool active: modelData.value === root.tab

          width: parent.width
          spacing: 2

          Rectangle {
            id: item
            width: parent.width
            height: 34
            color: section.active ? Theme.background3 : itemArea.containsMouse ? Theme.background1 : "transparent"

            KitIcon {
              id: itemIcon
              anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
              name: section.modelData.icon
              tint: section.active ? Theme.foreground0 : Theme.foreground2
              size: 16
            }

            KitText {
              anchors { left: itemIcon.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
              text: section.modelData.label
              color: section.active ? Theme.foreground0 : Theme.foreground2
              font.weight: section.active ? Font.ExtraBold : Font.DemiBold
            }

            MouseArea {
              id: itemArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: section.active ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: root.tab = section.modelData.value
            }
          }

          // the open page's groups: a click scrolls there (or selects, on Plugins)
          Repeater {
            model: section.active ? root.currentPage.jumps : []

            Rectangle {
              id: sub

              required property var modelData

              readonly property bool here: modelData.key === root.currentJump

              width: section.width
              height: 26
              color: subArea.containsMouse ? Theme.background1 : "transparent"

              // where the page is, as a thin line beside the name
              Rectangle {
                anchors { left: parent.left; leftMargin: 17; top: parent.top; bottom: parent.bottom; margins: 5 }
                width: 2
                color: sub.here ? Theme.foreground2 : Theme.background3
              }

              KitText {
                anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: sub.modelData.label
                elide: Text.ElideRight
                color: sub.here || subArea.containsMouse ? Theme.foreground0 : Theme.muted
                font.weight: sub.here ? Font.ExtraBold : Font.DemiBold
                font.pixelSize: Theme.fontSize - 1
              }

              MouseArea {
                id: subArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.jumpTo(sub.modelData)
              }
            }
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
    // a scroll by hand lets the marker follow the page again
    onContentYChanged: if (!scroll.running) root.pinnedJump = ""

    NumberAnimation on contentY {
      id: scroll
      running: false
      duration: 220
      easing.type: Easing.OutCubic
    }

    Item {
      id: pages
      x: 24
      y: 20
      width: page.width - 48
      implicitHeight: Math.max(appearance.visible ? appearance.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0,
                               plugins.visible ? plugins.height : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      // fills the window and scrolls its two panes itself
      PluginsPage { id: plugins; width: parent.width; height: page.height - 40; visible: root.tab === "plugins" }
    }
  }

  onTabChanged: {
    if (tab === "themes" || tab === "wallpaper") tab = "appearance";
    page.contentY = 0;
    pinnedJump = "";
  }
}
