import QtQuick
import qs.config
import qs.kit
import qs.modules.themes
import qs.modules.wallpapers

// Super+T in the island: the Themes and Wallpapers popups of modules/ (cards, faded ends, the wallpaper pick
// previewed while it is open) with a switch between them, wherever the modules sit on the bar.
// Tab switches, Escape closes. The popup in view owns the keys (its search field).
Item {
  id: root

  property string tab: "themes"             // themes | wall
  readonly property Item current: tab === "themes" ? themes : walls
  readonly property int pad: Theme.gapWide

  signal closeAsked()

  implicitWidth: current.implicitWidth
  implicitHeight: Theme.popupPadding + switcher.height + current.implicitHeight - Theme.popupPadding + Theme.gapSmall

  // the search takes the keys once the panel is on screen: a hidden item cannot hold the focus
  function reset() { tab = "themes"; focusSoon.restart(); }
  Timer { id: focusSoon; interval: 80; onTriggered: root.current.shown() }

  function pick(value) {
    if (value === tab) return;
    tab = value;
    focusSoon.restart();
  }

  // Escape and Tab, left unused by the popup's search field, arrive here
  Keys.onEscapePressed: closeAsked()
  Keys.onTabPressed: pick(tab === "themes" ? "wall" : "themes")
  Keys.onBacktabPressed: pick(tab === "themes" ? "wall" : "themes")

  KitChoices {
    id: switcher
    anchors { top: parent.top; topMargin: Theme.popupPadding; horizontalCenter: parent.horizontalCenter }
    width: parent.width - 2 * Theme.popupPadding
    stretch: true
    model: [{ label: "Themes", value: "themes", icon: "palette" }, { label: "Wallpapers", value: "wall", icon: "image" }]
    current: root.tab
    onPicked: value => root.pick(value)
  }

  ThemesPopup {
    id: themes
    inIsland: true
    visible: root.tab === "themes"
    anchors { top: switcher.bottom; topMargin: Theme.gapSmall - Theme.popupPadding; left: parent.left; right: parent.right }
  }

  WallpapersPopup {
    id: walls
    inIsland: true
    live: root.tab === "wall" && root.visible
    visible: root.tab === "wall"
    anchors { top: switcher.bottom; topMargin: Theme.gapSmall - Theme.popupPadding; left: parent.left; right: parent.right }
  }
}
