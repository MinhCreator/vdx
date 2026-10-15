import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right under its fixed header, scrolling
// on its own. Under the
// open section its groups (`jumps` of the page) jump there on a click.
//   APPEARANCE — theme, icon style, wallpaper, font and cursor;
//   BAR        — the layout of the bar's zones, modules on / off, underline.
//   PLUGINS    — each plugin's own options.
//   SHELL APPS — how the shell's own windows open: floating or tiled, size, spot.
//   BINDS      — Hyprland's keybinds by group, with a search.
Rectangle {
  id: root

  property string tab: "appearance"

  readonly property var sections: [
    { value: "appearance", label: "Appearance", icon: "sun" },
    { value: "bar",        label: "Bar",        icon: "layout" },
    { value: "plugins",    label: "Plugins",    icon: "grid" },
    { value: "apps",       label: "Shell apps", icon: "app-window" },
    { value: "binds",      label: "Binds",      icon: "keyboard" },
    { value: "about",      label: "About",      icon: "info" }
  ]

  function pageFor(value) {
    return value === "bar" ? bar : value === "plugins" ? plugins : value === "binds" ? binds : value === "apps" ? apps : value === "about" ? about : appearance;
  }
  readonly property Item currentPage: pageFor(tab)

  // the group being read: the last one whose title is within 40px of the
  // view's top (under the fixed header), the last group once the page is scrolled to the end. A
  // clicked one stays marked until the next scroll by hand.
  property string pinnedJump: ""
  readonly property string currentJump: {
    if (pinnedJump !== "") return pinnedJump;
    const list = currentPage.jumps;
    if (list.length === 0) return "";
    if (page.contentY >= page.contentHeight - page.height - 1 && page.interactive)
      return list[list.length - 1].key;
    let key = list[0].key;
    for (const j of list) if (j.y + pages.y <= page.contentY + 40) key = j.key;
    return key;
  }

  function jumpTo(j) {
    if (typeof currentPage.jump === "function") currentPage.jump(j.key);   // e.g. unfold it
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

    // the window's own header, level with the page's: its line runs on across
    Column {
      id: brand
      anchors { left: parent.left; leftMargin: 13; right: parent.right; top: parent.top; topMargin: 20 }
      spacing: 14

      KitHeader {
        icon: "settings"
        title: "Shell Manager"
        subtitle: "SUPER + S"
      }

      KitLine {}
    }

    Column {
      x: 12
      y: brand.y + brand.height + 14
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

          // the open page's groups: a click scrolls there. They unfold under
          // the section as it opens and fold away as another one does.
          Item {
            width: section.width
            height: section.active ? subs.implicitHeight : 0
            opacity: section.active ? 1 : 0
            clip: true

            Behavior on height { NumberAnimation { duration: Theme.underlineMs + 40; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.underlineMs + 40 } }

            Column {
              id: subs
              width: parent.width
              spacing: 2

              Repeater {
                model: root.pageFor(section.modelData.value).jumps

                Rectangle {
                  id: sub

                  required property var modelData

                  readonly property bool here: section.active && modelData.key === root.currentJump

                  width: subs.width
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
  // the open page's header stays put; only what is under it scrolls
  Column {
    id: header
    anchors { left: sidebar.right; leftMargin: 25; right: parent.right; rightMargin: 24; top: parent.top; topMargin: 20 }
    spacing: 14

    KitHeader {
      icon: root.currentPage.icon
      title: root.currentPage.title
      subtitle: root.currentPage.subtitle
    }

    KitLine {}
  }

  Flickable {
    id: page
    anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: header.bottom; bottom: parent.bottom }
    contentHeight: pages.implicitHeight + pages.y + 20
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
      y: 14
      width: page.width - 48
      implicitHeight: Math.max(appearance.visible ? appearance.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0,
                               binds.visible ? binds.implicitHeight : 0,
                               apps.visible ? apps.implicitHeight : 0,
                               about.visible ? about.implicitHeight : 0,
                               plugins.visible ? plugins.height : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      // fills the window and scrolls its two panes itself
      ShellAppsPage { id: apps;  width: parent.width; visible: root.tab === "apps" }
      AboutPage   { id: about;   width: parent.width; visible: root.tab === "about" }
      BindsPage   { id: binds;   width: parent.width; visible: root.tab === "binds" }
      PluginsPage { id: plugins; width: parent.width; height: page.height - pages.y - 20; visible: root.tab === "plugins" }
    }
  }

  onTabChanged: {
    if (tab === "themes" || tab === "wallpaper") tab = "appearance";
    page.contentY = 0;
    pinnedJump = "";
  }
}
