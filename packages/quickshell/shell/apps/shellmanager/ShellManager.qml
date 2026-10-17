import QtQuick
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right under its fixed header, scrolling
// on its own. Under the open section its groups (`jumps` of the page) jump
// there on a click.
// The sections come in three groups, by what the user is after:
//   LOOK     — how it looks and moves
//     APPEARANCE — theme, icon style, wallpaper, font and cursor;
//     ANIMATIONS — how the shell moves: all on / off, speed, each part on its own.
//   DESKTOP  — the desktop itself
//     BAR        — the layout of the bar's zones, modules on / off.
//     WINDOWS    — the window mode, each mode's options, gaps, the taskbar.
//   SHELL    — the shell's own apps and parts
//     SHELL APPS — each app: its options, its window, its bar module; the launcher,
//                  keybinds and lock screen are here too, and the Shell Manager's own opening.
//     MODULES    — each bar module's own options (the music's pause is the audio's).
//     ABOUT      — the ideas behind it, the author, versions.
Rectangle {
  id: root

  property string tab: "appearance"

  // opening: the main page, or the page it was left on (Shell apps › Shell Manager).
  // A page named by `shell open <page>` is set after this, so it wins.
  Connections {
    target: ShellSettings
    function onManagerOpenChanged() {
      if (ShellSettings.managerOpen)
        root.tab = ShellSettings.managerStart === "last" ? root.resolve(ShellSettings.managerTab).tab : "appearance";
    }
  }

  // `caption` opens a group in the sidebar
  readonly property var sections: [
    { value: "appearance", label: "Appearance", icon: "sun",        caption: "LOOK" },
    { value: "animations", label: "Animations", icon: "zap" },
    { value: "bar",        label: "Bar",        icon: "layout",     caption: "DESKTOP" },
    { value: "windows",    label: "Windows",    icon: "app-window" },
    { value: "apps",       label: "Apps",       icon: "grid",       caption: "SHELL" },
    { value: "modules",    label: "Modules",    icon: "puzzle" },
    { value: "about",      label: "About",      icon: "info" }
  ]

  // the pages that moved: Launcher, Keybinds and Lock screen are apps (Shell
  // apps), Media is the audio's (Modules). Their old names still open them:
  // `shell open lock`, a saved last page.
  function resolve(value, target) {
    if (["launcher", "keybinds", "lock"].includes(value)) return { tab: "apps", target: value };
    if (value === "media") return { tab: "modules", target: "audio" };
    return { tab: value, target: target ?? "" };
  }

  // the open section's group links, unfolded by a second click on it
  property bool navOpen: false
  readonly property bool dialogOpen: windowDialog.visible

  // another page, at one of its groups or (Shell apps) at one app: the
  // pages' links between each other (an app's bar module and back)
  function navigate(value, target) {
    const r = resolve(value, target);
    tab = r.tab;
    const p = pageFor(r.tab);
    const j = p.jumps.find(x => x.key === r.target);
    if (j) Qt.callLater(() => root.jumpTo(j));
    else if (r.target && typeof p.jump === "function") p.jump(r.target);
  }

  function pageFor(value) {
    return ({ bar: bar, animations: animations, windows: windows, modules: modules, apps: apps, about: about })[value] ?? appearance;
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
    // the list's width plus the window's frame on its left: the labels keep their room
    width: Theme.sideWidth + Theme.windowPadding
    height: parent.height
    color: Theme.background0

    // the window's own header, level with the page's: its line runs on across
    Column {
      id: brand
      anchors { left: parent.left; leftMargin: Theme.windowPadding; right: parent.right; top: parent.top; topMargin: Theme.windowPadding - Theme.headerInset }
      spacing: Theme.gapGroup

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
      x: Theme.windowPadding
      // the page's first label sits this far under the header: the list starts there too
      y: brand.y + brand.height + Theme.gapGroup
      width: parent.width - 2 * Theme.windowPadding
      height: parent.height - y - 40
      contentHeight: navColumn.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds

    Column {
      id: navColumn
      width: nav.width
      spacing: Theme.gapHair

      Repeater {
        model: root.sections

        Column {
          id: section

          required property var modelData
          required property int index

          readonly property bool active: modelData.value === root.tab
          readonly property bool hasJumps: root.pageFor(modelData.value).jumps.length > 0
          readonly property bool unfolded: active && root.navOpen
          // a group after the first starts a gap of gapGroup between the groups' captions
          readonly property int lead: index > 0 ? Theme.gapGroup - Theme.gapHair : 0

          width: parent.width
          spacing: Theme.gapTight

          // the group's caption, above its first section: its text sits on the top of the
          // box, so the first caption starts where the page's label does
          Item {
            width: section.width
            height: section.lead + captionText.implicitHeight + Theme.gapHair
            visible: !!section.modelData.caption

            KitText {
              id: captionText
              anchors { left: parent.left; leftMargin: Theme.gapLoose; top: parent.top; topMargin: section.lead }
              text: section.modelData.caption ?? ""
              color: Theme.gray
              font.pixelSize: Theme.fontSize - 2
              font.weight: Font.DemiBold
            }
          }

          Rectangle {
            radius: Theme.radiusControl
            id: item
            width: parent.width
            height: 34
            color: section.active ? Theme.background3 : itemArea.containsMouse ? Theme.background1 : "transparent"
            Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.quick } }

            KitIcon {
              id: itemIcon
              anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              name: section.modelData.icon
              tint: section.active ? Theme.foreground0 : Theme.foreground2
              size: 16
            }

            KitText {
              anchors { left: itemIcon.right; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              text: section.modelData.label
              color: section.active ? Theme.foreground0 : Theme.foreground2
              font.weight: section.active ? Font.ExtraBold : Font.DemiBold
            }

            // the open section with groups: a second click unfolds them
            KitIcon {
              anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              visible: section.active && section.hasJumps
              name: "chevron-down"
              size: Theme.iconSmall
              tint: Theme.foreground2
              rotation: section.unfolded ? 180 : 0
              Behavior on rotation { enabled: Motion.pages; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
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

            Behavior on height { enabled: Motion.pages; NumberAnimation { duration: Motion.ms(220); easing.type: Motion.easing } }
            Behavior on opacity { enabled: Motion.pages; NumberAnimation { duration: Motion.ms(220) } }

            Column {
              id: subs
              width: parent.width
              spacing: Theme.gapTight

              Repeater {
                model: root.pageFor(section.modelData.value).jumps

                Rectangle {
                  radius: Theme.radiusControl
                  id: sub

                  required property var modelData

                  readonly property bool here: section.active && modelData.key === root.currentJump

                  width: subs.width
                  height: 26
                  color: subArea.containsMouse ? Theme.background1 : "transparent"

                  // where the page is, as a thin line beside the name
                  Rectangle {
                    radius: Theme.pill(width)
                    anchors { left: parent.left; leftMargin: 17; top: parent.top; bottom: parent.bottom; margins: 5 }
                    width: 2
                    color: sub.here ? Theme.foreground2 : Theme.background3
                  }

                  KitText {
                    anchors { left: parent.left; leftMargin: 36; right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
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
      anchors { left: parent.left; leftMargin: Theme.windowPadding; bottom: parent.bottom; bottomMargin: 14 }
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
    anchors { left: sidebar.right; leftMargin: Theme.windowPadding; right: parent.right; rightMargin: Theme.windowPadding; top: parent.top; topMargin: Theme.windowPadding - Theme.headerInset }
    spacing: Theme.gapGroup

    KitHeader {
      icon: root.currentPage.icon
      title: root.currentPage.title
      subtitle: root.currentPage.subtitle
    }

    KitLine {}
  }

  Flickable {
    id: page
    anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: header.bottom; bottom: parent.bottom; bottomMargin: Theme.windowPadding }
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

    // a new page comes in: a fade and a short move from the right
    Item {
      id: pages
      x: 24 + 16 * (1 - pageIn.shown)
      opacity: pageIn.shown
      y: Theme.gapGroup
      width: page.width - 48
      implicitHeight: Math.max(appearance.visible ? appearance.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0,
                               animations.visible ? animations.implicitHeight : 0,
                               apps.visible ? apps.height : 0,
                               windows.visible ? windows.implicitHeight : 0,
                               about.visible ? about.implicitHeight : 0,
                               modules.visible ? modules.height : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      AnimationsPage { id: animations; width: parent.width; visible: root.tab === "animations" }
      // fills the window and scrolls its two panes itself
      ShellAppsPage { id: apps;  width: parent.width; onNavigate: (t, k) => root.navigate(t, k); onWindowSetup: id => windowDialog.appId = id; height: page.height - pages.y - 20; visible: root.tab === "apps" }
      WindowsPage { id: windows; width: parent.width; visible: root.tab === "windows" }
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

  QtObject { id: pageIn; property real shown: 1 }
  NumberAnimation { id: pageAnim; target: pageIn; property: "shown"; from: 0; to: 1; duration: Motion.ms(240); easing.type: Motion.easing }

  onTabChanged: {
    if (Motion.pages) pageAnim.restart();
    ShellSettings.set("managerTab", tab);   // kept for Shell apps › Shell Manager › Last page
    page.contentY = 0;
    pinnedJump = "";
    navOpen = false;
  }
}
