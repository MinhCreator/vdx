import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.components
import qs.config

// Popup chrome shared by every bar module: anchoring under the module, one open
// popup across the bar (PopupManager), keyboard focus for inputs and
// outside-click dismissal (HyprlandFocusGrab).
//
// The signals are `shown` / `hidden` because PopupWindow already owns `opened`
// and `closed`; redeclaring them trips qt.qml.invalidOverride.
PopupWindow {
  id: root

  required property Item anchorItem
  required property PanelWindow bar

  // `qs -c shell ipc call <ipcTarget> toggle` opens / closes the popup
  // (Hyprland binds, checks); with a bar per monitor, the focused one's
  // answers (PopupManager.ipcOwner). Empty disables it.
  property string ipcTarget: ""

  // Escape closes the popup. A popup with its own Escape handling (nested
  // views going back first) turns this off.
  property bool closeOnEscape: true

  // Modules in the left half grow their popup to the right from their left
  // edge, the rest to the left from their right edge; set on every anchoring.
  property bool alignLeft: false

  // When the popup last closed. The outside click that closes it also reaches
  // the module right after; toggle() ignores that echo.
  property real closedAt: 0

  signal shown()
  signal hidden()

  function toggle() {
    if (Date.now() - closedAt > 300) visible = !visible;
  }

  anchor.window: root.bar
  anchor.edges: Edges.Bottom | (alignLeft ? Edges.Left : Edges.Right)
  anchor.gravity: Edges.Bottom | (alignLeft ? Edges.Right : Edges.Left)

  // Bar x of the popup's corner, fixed while it is open (-1: closed).
  property real anchorX: -1

  // A corner under the module, taken once per show: modules change width while
  // the popup is open (track titles, values) and the popup must not follow.
  anchor.onAnchoring: {
    if (root.anchorX < 0) {
      root.alignLeft = root.anchorItem.mapToItem(root.bar.contentItem, root.anchorItem.width / 2, 0).x
                       < root.bar.width / 2;
      const p = root.anchorItem.mapToItem(root.bar.contentItem, root.alignLeft ? 0 : root.anchorItem.width, 0);
      root.anchorX = Math.round(p.x) - 1;
    }
    anchor.rect.x = root.anchorX;
    anchor.rect.y = Theme.barHeight - 1;
    anchor.rect.width = 1;
    anchor.rect.height = 1 + Theme.popupGap;
  }

  color: "transparent"
  visible: false
  // No xdg popup grab: the compositor would dismiss the popup whenever another
  // surface takes focus (slurp) and swallow the click on another module.
  // Keyboard focus comes from HyprlandFocusGrab, outside clicks from
  // PopupCatcher.
  grabFocus: false

  onVisibleChanged: {
    if (visible) {
      PopupManager.open(root);       // closes the previous popup: its line is the slide's start
      underline.start();
      root.shown();
    } else {
      root.closedAt = Date.now();
      root.anchorX = -1;
      underline.stop();
      PopupManager.close(root);
      root.hidden();
    }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    context: Qt.WindowShortcut
    enabled: root.visible && root.closeOnEscape
    onActivated: root.visible = false
  }

  IpcHandler {
    target: root.ipcTarget
    enabled: root.ipcTarget !== "" && PopupManager.ipcOwner(root.ipcTarget) === root
    function toggle(): void { root.toggle(); }
  }
  Component.onCompleted: if (ipcTarget !== "") PopupManager.addIpc(ipcTarget, root)
  Component.onDestruction: if (ipcTarget !== "") PopupManager.removeIpc(ipcTarget, root)

  // hidden, not closed, while the capture overlay's still copy stands in for it
  Binding {
    target: root.contentItem
    property: "opacity"
    value: PopupManager.frozen ? 0 : 1
  }

  // The face's color: the first KitBarItem (icon + tint) inside the module.
  function tintOf(item) {
    if (!item) return undefined;
    if (item.tint !== undefined && item.icon !== undefined) return item.tint;
    for (let i = 0; i < item.children.length; i++) {
      const c = root.tintOf(item.children[i]);
      if (c !== undefined) return c;
    }
    return undefined;
  }

  // Underline at the bar's bottom edge under the module while its popup is
  // open. It lives in the bar, not in the module: a module tucked in a folder
  // is transparent, and its line shows under the folder it stands in for.
  //
  // ShellSettings.underlineAnimation: none — appears in place; grow — opens
  // from the middle; slide — moves over from the popup that just closed on
  // this bar (grows when there is none).
  Rectangle {
    id: underline
    parent: root.bar.contentItem
    visible: active && !PopupManager.frozen
    y: Theme.barHeight - height
    height: 2
    color: root.tintOf(root.anchorItem) ?? Theme.foreground0

    // set before the line shows: it never paints a frame at a stale spot
    property bool active: false
    property bool smooth: false

    Behavior on x { enabled: underline.smooth; NumberAnimation { duration: Theme.underlineMs; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: underline.smooth; NumberAnimation { duration: Theme.underlineMs; easing.type: Easing.OutCubic } }

    function target() {
      const p = root.anchorItem.mapToItem(root.bar.contentItem, 0, 0);
      return { x: Math.round(p.x), width: Math.round(root.anchorItem.width) };
    }

    function start() {
      const t = target();
      const mode = ShellSettings.underlineAnimation;
      const last = PopupManager.lastLine;
      smooth = false;
      if (mode === "slide" && last && last.bar === root.bar && Date.now() - last.at < 500) {
        x = last.x;
        width = last.width;
      } else if (mode !== "none") {
        x = t.x + t.width / 2;
        width = 0;
      } else {
        x = t.x;
        width = t.width;
      }
      active = true;
      toX = toWidth = -1;
      if (mode === "none") follow(t);
      else waitFrames = 1;            // starts once the popup window is up
    }

    // Showing the popup blocks the GUI thread for a few frames (the window
    // is created and drawn); an animation running through that stalls and
    // then jumps. It starts on the first steady frame after the stall.
    property int waitFrames: 0
    function settle(frameTime) {
      if (waitFrames === 1 || (frameTime > 0.025 && waitFrames < 20)) { waitFrames++; return; }
      waitFrames = 0;
      smooth = true;
      follow(target());
    }

    function stop() {
      if (!active) return;
      active = false;
      waitFrames = 0;
      smooth = false;
      PopupManager.lastLine = { bar: root.bar, x: x, width: width, at: Date.now() };
    }

    // a write restarts the animation: only when the module really moved
    property real toX: -1
    property real toWidth: -1
    function follow(t) {
      if (t.x === toX && t.width === toWidth) return;
      toX = t.x;
      toWidth = t.width;
      x = t.x;
      width = t.width;
    }
  }

  FrameAnimation {
    running: underline.waitFrames > 0
    onTriggered: underline.settle(frameTime)
  }

  // modules change width and shift their neighbours while the popup is open
  Timer {
    interval: 200
    repeat: true
    running: underline.active
    onTriggered: if (underline.waitFrames === 0) underline.follow(underline.target())
  }

  HyprlandFocusGrab {
    windows: [root]
    active: root.visible && !PopupManager.holding
    onCleared: if (!PopupManager.holding) root.visible = false
  }
}
