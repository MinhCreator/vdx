import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right under its fixed header, scrolling
// on its own. Under the open section its groups (`jumps` of the page) jump
// there on a click.
//   APPEARANCE — theme, icon style, wallpaper, font and cursor;
//   BAR        — the layout of the bar's zones, modules on / off, underline.
//   MEDIA      — the music pauses while another app plays sound.
//   WINDOWS    — the window mode, each mode's options, gaps, the taskbar.
//   MODULES    — each bar module's own options (the modules; an app's is set with the app).
//   SHELL APPS — how the shell's own windows open: floating or tiled, size, spot.
//   LAUNCHER   — the launcher's (Super+R) rows, width, position and what it opens on.
//   KEYBINDS   — the keybinds panel's rows, width, position and what it opens on.
//   ABOUT      — how the Shell Manager opens, the ideas behind it, versions.
Rectangle {
  id: root

  property string tab: "appearance"

  // opening: the main page, or the page it was left on (About › Shell manager).
  // A page named by `shell open <page>` is set after this, so it wins.
  Connections {
    target: ShellSettings
    function onManagerOpenChanged() {
      if (ShellSettings.managerOpen)
        root.tab = ShellSettings.managerStart === "last" ? ShellSettings.managerTab : "appearance";
    }
  }

  readonly property var sections: [
    { value: "appearance", label: "Appearance", icon: "sun" },
    { value: "bar",        label: "Bar",        icon: "layout" },
    { value: "media",      label: "Media",      icon: "music" },
    { value: "windows",    label: "Windows",    icon: "app-window" },
    { value: "modules",    label: "Modules",    icon: "puzzle" },
    { value: "apps",       label: "Shell apps", icon: "grid" },
    { value: "launcher",   label: "Launcher",   icon: "menu" },
    { value: "keybinds",   label: "Keybinds",   icon: "keyboard" },
    { value: "about",      label: "About",      icon: "info" }
  ]

  // the open section's group links, unfolded by a second click on it
  property bool navOpen: false
  readonly property bool dialogOpen: windowDialog.visible

  // another page, at one of its groups or (Shell apps) at one app: the
  // pages' links between each other (an app's bar module and back)
  function navigate(value, target) {
    tab = value;
    const p = pageFor(value);
    const j = p.jumps.find(x => x.key === target);
    if (j) Qt.callLater(() => root.jumpTo(j));
    else if (target && typeof p.jump === "function") p.jump(target);
  }

  function pageFor(value) {
    return ({ bar: bar, media: media, windows: windows, modules: modules, apps: apps, launcher: launcher,
              keybinds: keybinds, about: about })[value] ?? appearance;
  }
  readonly property Item currentPage: pageFor(tab)

  // the group being read: the last one whose title is within 40px of the
  // view's top (under the fixed header), the last group once the page is
  // scrolled to the end. A clicked one stays marked until the next scroll by
  // hand.
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

  // ---- navigation ----
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

    // the sections scroll when their group links outgrow the window
    Flickable {
      id: nav
      x: 12
      y: brand.y + brand.height + 14
      width: parent.width - 24
      height: parent.height - y - 40
      contentHeight: navColumn.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds

    Column {
      id: navColumn
      width: nav.width
      spacing: 4

      Repeater {
        model: root.sections

        Column {
          id: section

          required property var modelData

          readonly property bool active: modelData.value === root.tab
          readonly property bool hasJumps: root.pageFor(modelData.value).jumps.length > 0
          readonly property bool unfolded: active && root.navOpen

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

            // the open section with groups: a second click unfolds them
            KitIcon {
              anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
              visible: section.active && section.hasJumps
              name: "chevron-down"
              size: 14
              tint: Theme.foreground2
              rotation: section.unfolded ? 180 : 0
              Behavior on rotation { NumberAnimation { duration: Theme.underlineMs; easing.type: Easing.OutCubic } }
            }

            MouseArea {
              id: itemArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: section.active && !section.hasJumps ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: {
                if (section.active) root.navOpen = !root.navOpen;
                else root.tab = section.modelData.value;
              }
            }
          }

          // the open page's groups: a click scrolls there. A second click on
          // the open section unfolds them; another section folds them away.
          Item {
            width: section.width
            height: section.unfolded ? subs.implicitHeight : 0
            opacity: section.unfolded ? 1 : 0
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
    }

    KitText {
      anchors { left: parent.left; leftMargin: 22; bottom: parent.bottom; bottomMargin: 14 }
      text: "Esc close"
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

  // ---- page ----
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
                               media.visible ? media.implicitHeight : 0,
                               apps.visible ? apps.height : 0,
                               windows.visible ? windows.implicitHeight : 0,
                               about.visible ? about.implicitHeight : 0,
                               launcher.visible ? launcher.implicitHeight : 0,
                               keybinds.visible ? keybinds.implicitHeight : 0,
                               modules.visible ? modules.height : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      MediaPage   { id: media;   width: parent.width; visible: root.tab === "media" }
      // fills the window and scrolls its two panes itself
      ShellAppsPage { id: apps;  width: parent.width; onNavigate: (t, k) => root.navigate(t, k); onWindowSetup: id => windowDialog.appId = id; height: page.height - pages.y - 20; visible: root.tab === "apps" }
      WindowsPage { id: windows; width: parent.width; visible: root.tab === "windows" }
      LauncherPage { id: launcher; width: parent.width; visible: root.tab === "launcher" }
      KeybindsPage { id: keybinds; width: parent.width; visible: root.tab === "keybinds" }
      AboutPage   { id: about;   width: parent.width; visible: root.tab === "about" }
      ModulesPage { id: modules; width: parent.width; onNavigate: (t, k) => root.navigate(t, k); height: page.height - pages.y - 20; visible: root.tab === "modules" }
    }
  }

  // over everything: how a shell window opens (Shell apps)
  WindowDialog {
    id: windowDialog
    anchors.fill: parent
    z: 10
  }

  onTabChanged: {
    ShellSettings.set("managerTab", tab);   // kept for About › Shell manager › Last page
    page.contentY = 0;
    pinnedJump = "";
    navOpen = false;
  }
}
