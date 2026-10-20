import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

// A child bar in the bar's row (Bar › Layout): its modules in a pill. In the
// island style it is a small island of its own: a module's popup opens inside
// it as in the island — the pill grows into the popup and folds back once it
// closes (BarPopup finds it through Bar.popupHost). Solid: a raised group in
// the strip, popups under their modules.
Rectangle {
  id: root

  required property var modelData             // its BarLayout.barsOn entry
  required property PanelWindow bar
  property real band: Theme.islandHeight

  // Bar.popupHost takes the nearest item that has it
  readonly property bool hostsPopups: Theme.island

  // ---- a module's popup ----
  property var popup: null                     // the BarPopup whose content is in here
  property Item popupContent: null             // its root item (a KitFrame)
  property bool popupShown: false

  function showPopup(p) {
    restoreTimer.stop();
    if (popup !== p) {
      restore();
      const from = p.contentItem.children;
      const kids = [];
      for (let i = 0; i < from.length; i++) kids.push(from[i]);
      kids.forEach(k => k.parent = host);
      popup = p;
      popupContent = kids[0] ?? null;
      if (popupContent && popupContent.inIsland !== undefined) popupContent.inIsland = true;
    }
    popupShown = true;
    popupSlot.forceActiveFocus();
  }

  function hidePopup(p) {
    if (popup !== p) return;
    popupShown = false;
    restoreTimer.restart();
  }

  // the content goes home once the pill has folded
  function restore() {
    if (!popup) return;
    const from = host.children;
    const kids = [];
    for (let i = 0; i < from.length; i++) kids.push(from[i]);
    kids.forEach(k => k.parent = popup.contentItem);
    if (popupContent && popupContent.inIsland !== undefined) popupContent.inIsland = false;
    popup = null;
    popupContent = null;
  }

  Timer {
    id: restoreTimer
    interval: Motion.slow + 60
    onTriggered: if (!root.popupShown) root.restore()
  }

  // ---- shape ----
  readonly property real pad: Theme.island ? Theme.gapGroup : Theme.gapLoose

  width: popupShown ? Math.max(Theme.popupWidth, popupContent?.implicitWidth ?? 0) : kids.width + 2 * pad
  height: popupShown ? (popupContent?.implicitHeight ?? band) : band
  radius: Theme.island ? Math.min(Theme.barRadiusFor(height), Theme.islandRadius) : Theme.radiusControl
  color: Theme.island ? Theme.background0 : Theme.background1
  border.width: Theme.island ? Theme.islandFrameWidth : 0
  border.color: Theme.background2
  clip: true

  Behavior on width { enabled: Motion.island && Theme.island; NumberAnimation { duration: Motion.slow; easing.type: Motion.morph } }
  Behavior on height { enabled: Motion.island && Theme.island; NumberAnimation { duration: Motion.slow; easing.type: Motion.morph } }
  Behavior on radius { enabled: Motion.island && Theme.island; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

  // the modules: they stay (their popups live in them), faded while one is open
  Row {
    id: kids
    anchors.horizontalCenter: parent.horizontalCenter
    y: (root.band - height) / 2
    spacing: Theme.moduleSpacing
    visible: opacity > 0
    opacity: root.popupShown ? 0 : 1
    Behavior on opacity { enabled: Motion.island && Theme.island; NumberAnimation { duration: Motion.quick } }

    Repeater {
      model: BarLayout.barModules(root.bar.modelData.name, root.modelData.id)

      Row {
        required property string modelData
        required property int index

        spacing: Theme.moduleSpacing

        Separator {
          anchors.verticalCenter: parent.verticalCenter
          visible: index > 0
          ruled: ShellSettings.barSeparators
        }

        Item {
          anchors.verticalCenter: parent.verticalCenter
          width: slot.width
          height: slot.height

          Loader {
            id: slot
            sourceComponent: root.bar.modules[modelData] ?? null
          }

          TapHandler {
            acceptedButtons: Qt.RightButton
            enabled: ShellSettings.barRightSettings
            onTapped: root.bar.openSettings(modelData)
          }
        }
      }
    }
  }

  // a module's popup content (showPopup); Escape closes it
  Item {
    id: popupSlot
    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
    width: root.width
    height: root.popupContent?.implicitHeight ?? 0
    visible: opacity > 0
    opacity: root.popupShown ? 1 : 0
    Behavior on opacity { enabled: Motion.island; NumberAnimation { duration: Motion.normal } }
    Keys.onEscapePressed: if (root.popup) root.popup.visible = false

    Item {
      id: host
      width: parent.width
      height: parent.height
    }
  }
}
