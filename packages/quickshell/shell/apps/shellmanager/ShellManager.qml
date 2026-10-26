import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.config
import qs.kit

// Shell Manager: settings laid out like a system settings window — sections
// on the left, the chosen page on the right under its fixed header, scrolling
// on its own. Under the open section its groups (`jumps` of the page) jump
// there on a click.
// The sections come in four groups, by what the user is after:
//   LOOK     — how it looks and moves
//     APPEARANCE — theme, accent, wallpaper, text, cursor, shape and controls;
//     ANIMATIONS — how the shell moves: all on / off, speed, each part on its own.
//   DESKTOP  — the desktop itself
//     BAR           — the layout of the bar's zones, modules on / off.
//     BAR MODULES   — each bar module's own options, an app's module too.
//     WINDOWS       — the window mode, each mode's options, gaps, the taskbar.
//     LOCK SCREEN   — what the lock shows and where.
//     NOTIFICATIONS — toasts, the history popup, the bar's marks.
//   SYSTEM   — the machine's connections
//     NETWORK    — Wi-Fi, saved and new networks, hotspot, Ethernet.
//     BLUETOOTH  — the adapter, paired and nearby devices.
//   SHELL    — the shell's own apps and parts
//     APPS       — each app: its options and its window; the launcher and keybinds
//                  are here too, and the Shell Manager's own opening.
//     ABOUT      — the ideas behind it, the author, versions.
// A page may offer `changed` + `reset()`: Reset (two steps) in the header.
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
    { value: "themes",     label: "Themes",     icon: "palette" },
    { value: "fonts",      label: "Fonts",      icon: "text" },
    { value: "cursor",     label: "Cursor",     icon: "cursor" },
    { value: "animations", label: "Animations", icon: "zap" },
    { value: "bar",        label: "Bar",        icon: "layout",     caption: "DESKTOP" },
    { value: "modules",    label: "Bar modules", icon: "puzzle" },
    { value: "windows",    label: "Windows",    icon: "app-window" },
    { value: "lockscreen", label: "Lock screen", icon: "lock" },
    { value: "notifications", label: "Notifications", icon: "bell" },
    { value: "network",    label: "Network",    icon: "wifi",       caption: "SYSTEM" },
    { value: "bluetooth",  label: "Bluetooth",  icon: "bluetooth" },
    { value: "displays",   label: "Displays",   icon: "monitor" },
    { value: "apps",       label: "Apps",       icon: "grid",       caption: "SHELL" },
    { value: "about",      label: "About",      icon: "info" }
  ]

  // the pages that moved: Launcher and Keybinds are apps (Apps), Media is the
  // audio's (Bar modules), the lock and the notifications have pages of their
  // own (05). Their old names still open them: `shell open lock`,
  // `apps:lock`, `modules:notifications`, a saved last page.
  function resolve(value, target) {
    if (["launcher", "keybinds"].includes(value)) return { tab: "apps", target: value };
    if (value === "lock" || (value === "apps" && target === "lock")) return { tab: "lockscreen", target: "" };
    if (value === "modules" && target === "notifications") return { tab: "notifications", target: "" };
    if (value === "media") return { tab: "modules", target: "audio" };
    if (value === "display" || (value === "apps" && target === "display")) return { tab: "displays", target: "" };
    // the theme, the font and the cursor left Appearance for pages of their own
    if (value === "appearance" && ["themes", "font", "cursor"].includes(target))
      return { tab: target === "font" ? "fonts" : target, target: "" };
    return { tab: value, target: target ?? "" };
  }

  // ---- search ----
  // the sidebar's search (the field over the sections): every page's rows from
  // config/settings-index.json (scripts/settings_index.py, rebuilt with the
  // pages); a label match before a hint or place one, a pick opens its place
  readonly property bool searching: searchField.text.trim() !== ""
  property var index: []
  property int picked: 0
  readonly property var results: {
    const q = searchField.text.trim().toLowerCase();
    if (q === "") return [];
    const first = index.filter(e => e.label.toLowerCase().includes(q));
    const then = index.filter(e => !first.includes(e) && (e.hint + " " + e.where).toLowerCase().includes(q));
    return first.concat(then).slice(0, 30);
  }
  onResultsChanged: picked = 0

  function search(words) {
    searchField.text = words;
    searchField.input.forceActiveFocus();
  }

  function openResult(e) {
    if (!e) return;
    const [tab, target] = e.target.split(":");
    navigate(tab, target ?? "");
  }

  FileView {
    path: Quickshell.shellDir + "/config/settings-index.json"
    printErrors: false
    onLoaded: { try { root.index = JSON.parse(text()); } catch (e) { root.index = []; } }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    enabled: root.searching
    onActivated: searchField.text = ""
  }

  // the open section's group links, unfolded by a second click on it
  property bool navOpen: false
  readonly property bool dialogOpen: windowDialog.visible

  // another page, at one of its groups or (Shell apps) at one app: the
  // pages' links between each other (an app's bar module and back)
  function navigate(value, target) {
    const r = resolve(value, target);
    searchField.text = "";
    tab = r.tab;
    const p = pageFor(r.tab);
    const j = p.jumps.find(x => x.key === r.target);
    if (j) Qt.callLater(() => root.jumpTo(j));
    else if (r.target && typeof p.jump === "function") p.jump(r.target);
  }

  function pageFor(value) {
    return ({ themes: themes, fonts: fonts, cursor: cursor, bar: bar, animations: animations, windows: windows, network: network, bluetooth: bluetooth, displays: displays,
              modules: modules, apps: apps, about: about, lockscreen: lockscreen,
              notifications: notifications })[value] ?? appearance;
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
    lastJump = j;
    rejump.restart();
  }

  // a page laid out as it shows (Settings boxes, wrapped hints) moves its groups:
  // aim again once it has settled, unless someone scrolled meanwhile
  property var lastJump: null
  Timer {
    id: rejump
    interval: Motion.normal + 120
    onTriggered: {
      const j = root.currentPage.jumps.find(x => x.key === root.lastJump?.key);
      if (j && root.pinnedJump === j.key && Math.abs(page.contentY - j.y) > 2) {
        scroll.to = Math.min(Math.max(0, page.contentHeight - page.height), Math.max(0, j.y));
        scroll.restart();
      }
    }
  }

  color: Theme.background0

  // the gap under the header line, the sidebar's and the page's alike
  readonly property int contentGap: Theme.gapGroup

  // ---- navigation ----
  Rectangle {
    id: sidebar
    // the list's width plus the window's frame on its left: the labels keep their room
    width: Theme.sideWidth + Theme.windowPadding
    height: parent.height
    color: Theme.sideFill

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

    // the search, first in the list: typing swaps the sections for results
    KitInput {
      id: searchField
      x: Theme.windowPadding
      // level with the page's first row (pages.y under the header): one top for both columns
      y: brand.y + brand.height + root.contentGap
      width: nav.width
      placeholder: "Search…"
      passKeys: [Qt.Key_Up, Qt.Key_Down]
      onAccepted: root.openResult(root.results[root.picked])
      onKeyPassed: key => root.picked = Math.max(0, Math.min(root.results.length - 1, root.picked + (key === Qt.Key_Down ? 1 : -1)))
    }

    // the sections scroll when their group links outgrow the window
    Flickable {
      id: nav
      x: Theme.windowPadding
      y: searchField.y + searchField.height + Theme.gapMedium
      width: parent.width - 2 * Theme.windowPadding
      height: parent.height - y - Theme.windowPadding
      visible: !root.searching
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
          // a group after the first starts a gap of gapMedium between the groups' captions
          readonly property int lead: index > 0 ? Theme.gapMedium : 0

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
              anchors { left: parent.left; leftMargin: Theme.gapWide + 4; top: parent.top; topMargin: section.lead }
              text: Theme.captionCaps ? (section.modelData.caption ?? "").toUpperCase() : (section.modelData.caption ?? "")
              color: Theme.m3 ? Theme.surfaceVariantText : Theme.muted
              font.pixelSize: Theme.textCaption
              font.weight: Font.Medium
              font.letterSpacing: Theme.captionCaps ? 1 : 0
            }
          }

          Rectangle {
            id: item
            readonly property color ink: section.active ? Theme.selectedText : Theme.m3 ? Theme.surfaceVariantText : Theme.foreground2
            width: parent.width
            height: Theme.sideRowHeight
            radius: Theme.radiusFor(height)
            color: section.active ? Theme.selectedFill : itemArea.containsMouse ? Theme.hover(Theme.clear) : Theme.clear
            Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.quick } }

            KitIcon {
              id: itemIcon
              anchors { left: parent.left; leftMargin: Theme.gapWide + 4; verticalCenter: parent.verticalCenter }
              name: section.modelData.icon
              tint: item.ink
              size: Theme.iconSide
            }

            KitText {
              anchors { left: itemIcon.right; leftMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
              text: section.modelData.label
              color: item.ink
              font.weight: section.active || Theme.m3 ? Theme.controlWeight : Theme.restWeight
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
                  color: subArea.containsMouse ? Theme.background1 : Theme.clear
                  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

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
                    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
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

  }

  // the search's results where the sections are: label, and the page › group it is on
  ListView {
    id: found
    visible: root.searching
    x: nav.x
    y: nav.y
    width: nav.width
    height: nav.height
    clip: true
    spacing: Theme.gapHair
    boundsBehavior: Flickable.StopAtBounds
    model: root.results
    currentIndex: root.picked
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

    delegate: Rectangle {
      id: hit
      required property var modelData
      required property int index

      width: found.width
      height: hitText.implicitHeight + 2 * Theme.gapTight
      radius: Theme.radiusControl
      color: index === root.picked ? Theme.background3 : hitArea.containsMouse ? Theme.background1 : Theme.clear

      Column {
        id: hitText
        anchors { left: parent.left; leftMargin: Theme.gapLoose; right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }

        KitText {
          width: parent.width
          elide: Text.ElideRight
          text: hit.modelData.label
          font.weight: Font.DemiBold
        }

        KitText {
          width: parent.width
          elide: Text.ElideRight
          text: hit.modelData.where.toUpperCase()
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }

      MouseArea {
        id: hitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openResult(hit.modelData)
      }
    }

    KitText {
      visible: root.results.length === 0
      x: Theme.gapLoose
      text: "Nothing matches"
      color: Theme.muted
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

      // a page that can go back to its defaults: `changed`, `reset()`
      KitResetButton {
        visible: typeof root.currentPage.reset === "function"
        changed: root.currentPage.changed ?? false
        onReset: root.currentPage.reset()
      }

      // a page with tabs (Network) lists them: `tabs` [{label, value}], `tab`
      KitChoices {
        visible: (root.currentPage.tabs ?? []).length > 0
        model: root.currentPage.tabs ?? []
        current: root.currentPage.tab ?? ""
        onPicked: value => root.currentPage.tab = value
      }
    }

    KitLine {}
  }

  Flickable {
    id: page
    anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: header.bottom; bottom: parent.bottom }
    // to the window's edge: the rows scroll out of it, not out of a line above it
    // Apps, Bar modules and Themes fill the window and scroll their panes themselves: the page stays
    contentHeight: apps.visible || modules.visible || themes.visible ? height : pages.implicitHeight + pages.y + Theme.windowPadding
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    // a page with tabs (Network) shows a tab from its top
    Connections {
      target: root.currentPage
      ignoreUnknownSignals: true
      function onTabChanged() { page.contentY = 0; }
    }

    // a scroll by hand lets the marker follow the page again
    onContentYChanged: if (!scroll.running) root.pinnedJump = ""

    NumberAnimation on contentY {
      id: scroll
      running: false
      duration: Motion.normal
      easing.type: Motion.easing
    }

    // a new page comes in: a fade and a short move from the right
    Item {
      id: pages
      x: 24 + 16 * (1 - pageIn.shown)
      opacity: pageIn.shown
      y: root.contentGap
      width: page.width - 48
      implicitHeight: Math.max(appearance.visible ? appearance.implicitHeight : 0,
                               bar.visible ? bar.implicitHeight : 0,
                               themes.visible ? themes.height : 0,
                               fonts.visible ? fonts.implicitHeight : 0,
                               cursor.visible ? cursor.implicitHeight : 0,
                               animations.visible ? animations.implicitHeight : 0,
                               apps.visible ? apps.height : 0,
                               windows.visible ? windows.implicitHeight : 0,
                               network.visible ? network.implicitHeight : 0,
                               bluetooth.visible ? bluetooth.implicitHeight : 0,
                               displays.visible ? displays.implicitHeight : 0,
                               about.visible ? about.implicitHeight : 0,
                               lockscreen.visible ? lockscreen.implicitHeight : 0,
                               notifications.visible ? notifications.implicitHeight : 0,
                               modules.visible ? modules.height : 0)

      AppearancePage { id: appearance; width: parent.width; visible: root.tab === "appearance" }
      BarPage     { id: bar;     width: parent.width; visible: root.tab === "bar" }
      ThemesPage  { id: themes;  width: parent.width; height: page.height - pages.y; visible: root.tab === "themes" }
      FontsPage   { id: fonts;   width: parent.width; visible: root.tab === "fonts" }
      CursorPage  { id: cursor;  width: parent.width; visible: root.tab === "cursor" }
      AnimationsPage { id: animations; width: parent.width; visible: root.tab === "animations" }
      // fills the window and scrolls its two panes itself
      ShellAppsPage { id: apps;  width: parent.width; onNavigate: (t, k) => root.navigate(t, k); onWindowSetup: id => windowDialog.appId = id; height: page.height - pages.y; visible: root.tab === "apps" }
      WindowsPage { id: windows; width: parent.width; visible: root.tab === "windows" }
      NetworkPage   { id: network;   width: parent.width; visible: root.tab === "network" }
      BluetoothPage { id: bluetooth; width: parent.width; visible: root.tab === "bluetooth" }
      DisplaysPage  { id: displays;  width: parent.width; visible: root.tab === "displays" }
      AboutPage   { id: about;   width: parent.width; visible: root.tab === "about" }
      LockScreenPage { id: lockscreen; width: parent.width; visible: root.tab === "lockscreen" }
      NotificationsPage { id: notifications; width: parent.width; visible: root.tab === "notifications" }
      ModulesPage { id: modules; width: parent.width; onNavigate: (t, k) => root.navigate(t, k); height: page.height - pages.y; visible: root.tab === "modules" }
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
