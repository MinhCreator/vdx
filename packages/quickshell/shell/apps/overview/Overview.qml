import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.apps.shellmanager
import qs.components
import qs.config
import qs.kit
import qs.modules.windows
import Quickshell.Widgets

// Floating mode: TaskView (the workspaces as a strip, the chosen one's windows
// in a grid). The other modes:
// Niri's overview as one canvas: every workspace of the focused
// monitor is a row, and each window sits where it really is, so a scrolling
// workspace runs on sideways past the screen. Only the workspaces with
// windows (and the one in use) are rows, on the dimmed wallpaper. The wheel
// held down pans, the wheel turned scrolls (shift: sideways, Ctrl: zoom),
// arrows or hjkl step a row. A click on a window focuses it, on a workspace goes
// there; a window dragged with Super held onto another workspace moves there,
// the canvas scrolling by itself near the edges. Enter goes to
// the workspace in the middle, Escape or a click on the dimmed screen closes.
ScrimWindow {
  id: root

  readonly property var monitor: Hyprland.focusedMonitor
  readonly property real mw: (monitor?.width ?? 1920) / (monitor?.scale ?? 1)
  readonly property real mh: (monitor?.height ?? 1080) / (monitor?.scale ?? 1)

  // canvas units are logical pixels; a row is one monitor and the gap is 80 of them
  readonly property real gap: 90
  readonly property real pitch: mh + gap
  // floating windows overlap, so that mode gets the task view instead of the canvas
  readonly property bool taskView: WindowsService.mode === "floating"

  // Shell Manager › Windows › Overview (ModuleSettings "overview")
  readonly property bool previews: ModuleSettings.get("overview", "previews", true)
  readonly property bool names: ModuleSettings.get("overview", "names", true)
  readonly property bool dimOthers: ModuleSettings.get("overview", "dim", true)
  readonly property real wheelSpeed: ({ slow: 0.5, normal: 1, fast: 1.7 })[ModuleSettings.get("overview", "wheel", "normal")] ?? 1

  // + / - and Ctrl + wheel: fewer rows big, or more rows small
  property real zoomLevel: 1
  Behavior on zoomLevel { enabled: Motion.panels && root.glide; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

  // 0 -> 1 as it opens: the rows come in one after another, from the middle one out
  property real intro: 1
  NumberAnimation { id: introAnim; target: root; property: "intro"; from: 0; to: 1; duration: Motion.slow; easing.type: Motion.easing }
  readonly property real zoom: height * 0.42 / mh * zoomLevel

  // the rows: the monitor's workspaces that hold a window, and the one in use, lowest
  // first; and, like Niri, an empty one past each end that holds windows (the next
  // workspace to move a window to; ten at most)
  readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
  readonly property var rowIds: {
    const ids = {};
    ids[activeId] = true;
    for (const t of Hyprland.toplevels.values) {
      const w = t.workspace;
      if (w && w.id > 0 && w.monitor === root.monitor) ids[w.id] = true;
    }
    const list = Object.keys(ids).map(Number).sort((x, y) => x - y);
    const busy = id => Hyprland.toplevels.values.some(t => t.workspace?.id === id);
    if (list[0] > 1 && busy(list[0])) list.unshift(list[0] - 1);
    if (list[list.length - 1] < 10 && busy(list[list.length - 1])) list.push(list[list.length - 1] + 1);
    return list;
  }
  readonly property int rowCount: rowIds.length
  // the view: the canvas point in the middle of the screen
  property real camX: 0
  property real camY: 0
  // a key step glides, the wheel and a drag follow the hand
  property bool glide: false
  readonly property int centreIndex: Math.max(0, Math.min(rowCount - 1, Math.round((camY - mh / 2) / pitch)))
  readonly property int centreId: rowIds[centreIndex] ?? activeId

  Behavior on camX { enabled: Motion.panels && root.glide; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
  Behavior on camY { enabled: Motion.panels && root.glide; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

  function rowTop(i) { return i * pitch; }
  function pan(dx, dy) { camX = Math.max(extent[0], Math.min(extent[1], camX + dx)); camY = Math.max(mh / 2 - pitch / 2, Math.min((rowCount - 1) * pitch + mh / 2 + pitch / 2, camY + dy)); }
  function step(dx, dy) { touched = true; glide = true; pan(dx, dy); }
  function drag(dx, dy) { touched = true; glide = false; pan(dx, dy); }
  // the wheel: Ctrl zooms; a touchpad gives pixels on both axes, a wheel notches
  // (Shift turns them sideways)
  function scroll(e) {
    if (taskView) return;
    if (e.modifiers & Qt.ControlModifier) { zoomBy(e.angleDelta.y > 0 ? 1.1 : 1 / 1.1); return; }
    const smooth = e.pixelDelta.x !== 0 || e.pixelDelta.y !== 0;
    // a notch is 120 units: three of them carry a row across the screen's height
    const k = (smooth ? 1.5 : 3) * wheelSpeed;
    let dx = k * (smooth ? e.pixelDelta.x : e.angleDelta.x);
    let dy = k * (smooth ? e.pixelDelta.y : e.angleDelta.y);
    if ((e.modifiers & Qt.ShiftModifier) && dx === 0) { dx = dy; dy = 0; }
    touched = true;
    glide = !smooth;
    pan(-dx / zoom, -dy / zoom);
  }
  function zoomBy(f) { touched = true; zoomLevel = Math.max(0.1, Math.min(1.6, zoomLevel * f)); }

  // the widest stretch any row runs over (monitor coordinates): a scrolling row goes on
  // past the screen, and the view is first set so that all of it shows
  property bool touched: false
  readonly property var extent: {
    let lo = 0, hi = mw;
    for (const t of Hyprland.toplevels.values) {
      const ipc = t.lastIpcObject;
      if (!ipc?.at || !ipc?.size || rowIds.indexOf(t.workspace?.id) < 0) continue;
      const x = ipc.at[0] - (monitor?.x ?? 0);
      lo = Math.min(lo, x);
      hi = Math.max(hi, x + ipc.size[0]);
    }
    return [lo, hi];
  }
  function fit() {
    const span = extent[1] - extent[0];
    zoomLevel = Math.max(0.1, Math.min(1, width * 0.9 / (span * height * 0.42 / mh)));
    camX = (extent[0] + extent[1]) / 2;
  }
  // the windows' places arrive just after it opens: fit again until the view is touched
  onExtentChanged: if (open && !touched) fit();
  function goTo(id) { open = false; Hypr.call("hl.dispatch(hl.dsp.focus({ workspace = " + id + " }))"); }
  function focus(t) { open = false; Hypr.call("hl.dispatch(hl.dsp.focus({ window = \"" + Hypr.target(t) + "\" }))"); }
  function moveTo(t, id) {
    Hypr.call("hl.dispatch(hl.dsp.window.move({ workspace = " + id + ", window = \"" + Hypr.target(t) + "\", follow = false }))");
    settle.restart();
  }
  // the layout settles a moment after a move, in two steps (the windows' places come from
  // Hyprland, and the first reading can be the half-way one)
  // Quickshell does not re-read a window's place when the layout moves it, so Hyprland's
  // events about windows start the same settling as a drop does
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (root.open && ["movewindowv2", "openwindow", "closewindow", "changefloatingmode", "fullscreen"].includes(event.name)) settle.restart();
    }
  }

  // `settled` tells the windows' pictures to be taken again
  signal settled()
  Timer { id: settle; interval: 250; onTriggered: { Hyprland.refreshToplevels(); root.settled(); settleLate.restart(); } }
  Timer { id: settleLate; interval: 500; onTriggered: { Hyprland.refreshToplevels(); root.settled(); } }

  // Super + left drag of a window: it follows the pointer, and the canvas scrolls
  // by itself when the pointer is near an edge, so a far workspace can be reached
  property var dragged: null
  property point dragPos: Qt.point(0, 0)   // the pointer, in the canvas's own coordinates
  function placeDragged() {
    const w = dragged;
    if (!w) return;
    w.x = (dragPos.x - world.x) / zoom - w.width / 2;
    w.y = (dragPos.y - world.y) / zoom - w.parent.y - w.height / 2;
  }

  // near an edge the canvas scrolls towards it, faster the closer the pointer is
  Timer {
    interval: 16
    repeat: true
    running: root.dragged !== null
    onTriggered: {
      const m = Math.min(canvas.width, canvas.height) * 0.14;
      const edge = (v, size) => v < m ? -Math.min(1, 1 - v / m) : v > size - m ? Math.min(1, (v - (size - m)) / m) : 0;
      const ex = edge(root.dragPos.x, canvas.width), ey = edge(root.dragPos.y, canvas.height);
      if (ex === 0 && ey === 0) return;
      root.drag(ex * 32 / root.zoom, ey * 32 / root.zoom);
      root.placeDragged();
    }
  }

  // Hyprland's Super + mouse binds (drag, resize a window) stand down while this is
  // open: they would reach the windows under it (hypr/components/keybinds.lua)
  onOpenChanged: {
    Hypr.call("MouseBinds(" + !open + ")");
    if (!open) return;
    intro = Motion.panels ? 0 : 1;
    if (Motion.panels) introAnim.restart();
    const active = Math.max(0, rowIds.indexOf(activeId));
    glide = false;
    touched = false;
    fit();
    camY = mh / 2 + active * pitch;
    tasks.reset();
    Hyprland.refreshToplevels();
    canvas.forceActiveFocus();
  }
  // a shell that died with it open leaves them off: back on at start
  Component.onCompleted: Hypr.call("MouseBinds(true)")

  // the wallpaper awww draws under the windows: this monitor's own picture or the theme's
  readonly property string picture: {
    if (ShellSettings.wallpaperMode !== "image") return "";
    const own = WallpaperService.outputsFor(ThemeService.current)[monitor?.name ?? ""];
    const rel = own ?? WallpaperService.inUse;
    return rel ? WallpaperService.pathOf(rel) : "";
  }

  dim: false
  namespace: "overview"
  onDismissed: open = false

  IpcHandler {
    target: "overview"
    function toggle(): void { root.open = !root.open; }
    function open(): void { root.open = true; }
    function close(): void { root.open = false; }
  }

  Item {
    id: canvas
    anchors.fill: parent
    focus: true
    Keys.onUpPressed: root.taskView ? tasks.moveWin(0, -1) : root.step(0, -root.pitch)
    Keys.onDownPressed: root.taskView ? tasks.moveWin(0, 1) : root.step(0, root.pitch)
    Keys.onLeftPressed: root.taskView ? tasks.moveDesk(-1) : root.step(-root.mw / 2, 0)
    Keys.onRightPressed: root.taskView ? tasks.moveDesk(1) : root.step(root.mw / 2, 0)
    Keys.onPressed: event => {
      if (root.taskView) {
        if (event.key === Qt.Key_H) tasks.moveWin(-1, 0);
        else if (event.key === Qt.Key_L) tasks.moveWin(1, 0);
        else if (event.key === Qt.Key_K) tasks.moveWin(0, -1);
        else if (event.key === Qt.Key_J) tasks.moveWin(0, 1);
        else return;
        event.accepted = true;
        return;
      }
      if (event.key === Qt.Key_PageUp || event.key === Qt.Key_K) root.step(0, -root.pitch);
      else if (event.key === Qt.Key_PageDown || event.key === Qt.Key_J) root.step(0, root.pitch);
      else if (event.key === Qt.Key_H) root.step(-root.mw / 2, 0);
      else if (event.key === Qt.Key_L) root.step(root.mw / 2, 0);
      else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) root.zoomBy(1.25);
      else if (event.key === Qt.Key_Minus) root.zoomBy(0.8);
      else return;
      event.accepted = true;
    }
    Keys.onReturnPressed: root.taskView ? tasks.pick() : root.goTo(root.centreId)
    Keys.onEscapePressed: root.open = false


    // the wallpaper, dimmed: it hides the windows behind, so only the overview shows.
    // Wider than the screen: the panel grows from 96 % as it opens
    Item {
      anchors.fill: parent
      anchors.margins: -parent.width * 0.05
      clip: true

      Rectangle {
        anchors.fill: parent
        color: ShellSettings.wallpaperMode === "custom" ? ShellSettings.wallpaperColor : Theme.background1
      }
      Image {
        anchors.fill: parent
        source: root.open && root.picture !== "" ? "file://" + root.picture : ""
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: root.width
      }
      Rectangle { anchors.fill: parent; color: Theme.scrim }
    }

    // a click on the empty screen closes
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismissed()
      // the windows' own areas leave the wheel alone, so it reaches this one from anywhere
      onWheel: wheel => root.scroll(wheel)
    }

    // the wheel held down pans the canvas
    DragHandler {
      target: null
      enabled: !root.taskView
      acceptedButtons: Qt.MiddleButton
      property real lastX: 0
      property real lastY: 0
      onActiveChanged: { lastX = 0; lastY = 0; }
      onTranslationChanged: {
        root.drag(-(translation.x - lastX) / root.zoom, -(translation.y - lastY) / root.zoom);
        lastX = translation.x;
        lastY = translation.y;
      }
    }

    // the rail: one mark per workspace, the one in the middle long
    Column {
      z: 1
      visible: !root.taskView
      anchors.left: parent.left
      anchors.leftMargin: Theme.gapWide * 2
      anchors.verticalCenter: parent.verticalCenter
      spacing: Theme.gapMedium

      Repeater {
        model: root.rowCount

        Rectangle {
          required property int index
          readonly property bool centre: index === root.centreIndex
          width: 4
          height: centre ? 28 : 14
          radius: Theme.pill(width)
          color: centre ? Theme.foreground0 : Theme.gray
          Behavior on height { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
        }
      }
    }

    // the keys, at the bottom
    Rectangle {
      z: 1
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Theme.gapWide * 2
      width: hints.implicitWidth + Theme.gapWide * 3
      height: hints.implicitHeight + Theme.gapWide * 1.5
      radius: Theme.pill(height)
      color: Theme.background1
      border.width: Theme.hairline
      border.color: Theme.popupFrame

      KitText {
        id: hints
        anchors.centerIn: parent
        text: root.taskView ? "←→ workspace  ·  ↑↓ hjkl window  ·  Enter open  ·  Esc close"
                            : "Hold the wheel to pan  ·  Super + drag a window to a workspace  ·  ↑↓ workspaces  ·  + − zoom  ·  Enter open  ·  Esc close"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }

    TaskView {
      id: tasks
      z: 1
      anchors.fill: parent
      visible: root.taskView
      overview: root
    }

    // the canvas: rows of workspaces and the windows on them, panned and zoomed
    Item {
      id: world
      visible: !root.taskView
      transformOrigin: Item.TopLeft
      scale: root.zoom
      x: canvas.width / 2 - root.camX * root.zoom
      y: canvas.height / 2 - root.camY * root.zoom

      Repeater {
        model: root.rowCount

        Item {
          id: space
          required property int index
          readonly property int wsId: root.rowIds[index]
          readonly property bool active: root.monitor?.activeWorkspace?.id === wsId
          // the row's windows: the list is replaced only when the set changes, not at every
          // change of a title or a place, which would remake each window and its picture
          property var wins: []
          readonly property string winKey: Hyprland.toplevels.values.filter(t => t.workspace?.id === wsId).map(t => t.address).join(",")
          onWinKeyChanged: wins = Hyprland.toplevels.values.filter(t => t.workspace?.id === wsId)
          Component.onCompleted: wins = Hyprland.toplevels.values.filter(t => t.workspace?.id === wsId)

          // comes in with the opening: later the further it is from the row in the middle
          readonly property real appear: Math.max(0, Math.min(1, root.intro * 1.8 - Math.abs(index - root.centreIndex) * 0.25))
          property real dimLevel: !root.dimOthers || wsId === root.centreId ? 1 : 0.45
          Behavior on dimLevel { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

          y: root.rowTop(index) + (1 - appear) * 80
          // the row of the window being dragged stays above the others
          z: root.dragged && root.dragged.parent === space ? 1 : 0
          width: root.mw
          height: root.mh
          // the row in the middle is the one Enter opens; the others step back
          opacity: dimLevel * appear

          // the workspace's own area: a click goes there, a drop moves a window
          // no tile: the windows lie on the dimmed screen. An empty workspace is drawn as
          // a screen, so it can be seen and dropped on; any row lights under a dragged window
          Rectangle {
            readonly property bool empty: space.wins.length === 0
            radius: Theme.radiusCard / root.zoom
            anchors.fill: parent
            color: drop.containsDrag ? Theme.background2 : empty ? Theme.background1 : "transparent"
            border.width: (drop.containsDrag ? Theme.ring : empty ? Theme.hairline : 0) / root.zoom
            border.color: drop.containsDrag ? Theme.foreground0 : Theme.gray
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
          }

          // above the row: its number and what is on it
          KitText {
            x: 8
            y: -root.gap * 0.7
            text: space.wsId + "   ·   " + (space.wins.length === 0 ? "Empty" : space.wins.length + (space.wins.length === 1 ? " window" : " windows"))
            color: space.wsId === root.centreId ? Theme.foreground0 : Theme.muted
            font.pixelSize: 36
            font.letterSpacing: 2
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.normal } }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.goTo(space.wsId)
          }

          DropArea {
            id: drop
            anchors.fill: parent
            onDropped: drag => { if (drag.source.homeId !== space.wsId) root.moveTo(drag.source.toplevel, space.wsId); }
          }

          // windows at their real place: a scrolling column may run past the edge
          Repeater {
            model: space.wins

            ClippingRectangle {
              radius: Theme.radiusControl
              id: win
              required property var modelData
              readonly property var toplevel: modelData
              readonly property int homeId: space.wsId
              readonly property var ipc: modelData.lastIpcObject ?? {}
              readonly property real wx: (ipc.at?.[0] ?? 0) - (root.monitor?.x ?? 0)
              readonly property real wy: (ipc.at?.[1] ?? 0) - (root.monitor?.y ?? 0)

              x: wx
              y: wy
              width: ipc.size?.[0] ?? 0
              height: ipc.size?.[1] ?? 0
              color: Theme.background2
              readonly property bool focused: Hyprland.activeToplevel === modelData
              border.width: (focused ? Theme.ring : Theme.hairline) / root.zoom
              border.color: focused || hover.containsMouse ? Theme.foreground0 : Theme.gray
              Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
              Drag.active: root.dragged === win
              Drag.source: win
              Drag.hotSpot.x: width / 2
              Drag.hotSpot.y: height / 2

              // a little forward under the pointer, more while carried; its place glides
              // when the layout changes or when it is let go
              scale: root.dragged === win ? 1.03 : hover.containsMouse ? 1.012 : 1
              Behavior on scale { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
              Behavior on x { enabled: Motion.controls && root.dragged !== win; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
              Behavior on y { enabled: Motion.controls && root.dragged !== win; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

              ScreencopyView {
                id: shot
                anchors.fill: parent
                anchors.margins: 1
                // asked for a moment after the window appears here, not in the same frame (a
                // picture requested at once, for a window just made, never comes); kept while
                // the screen fades out: the picture would give way to the icon
                property bool armed: false
                Timer { interval: 120; running: true; onTriggered: shot.armed = true }
                captureSource: armed && root.visible && root.previews ? win.modelData.wayland : null
                live: false

                // after a move settles the picture is taken again, at the window's new size
                Connections { target: root; function onSettled() { if (root.previews && shot.armed) shot.captureFrame(); } }
              }

              // a window past the screen's edge is not drawn, so it has no picture:
              // its icon and title stand in
              Column {
                anchors.centerIn: parent
                width: parent.width - 80
                spacing: 24
                visible: root.open && !shot.hasContent

                Image {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 200
                  height: 200
                  sourceSize: Qt.size(200, 200)
                  source: Hypr.iconOf(win.modelData)
                  asynchronous: true
                }
                KitText {
                  width: parent.width
                  horizontalAlignment: Text.AlignHCenter
                  text: win.modelData.title
                  color: Theme.muted
                  font.pixelSize: 34
                  elide: Text.ElideRight
                }
              }

              // the app's name, like a title bar
              Rectangle {
                x: 16
                y: 16
                width: cap.implicitWidth + 24
                height: cap.implicitHeight + 12
                radius: Theme.pill(height)
                color: Theme.scrim
                visible: root.names && Hypr.classOf(win.modelData) !== ""

                KitText {
                  id: cap
                  anchors.centerIn: parent
                  text: Hypr.classOf(win.modelData)
                  color: win.focused ? Theme.foreground0 : Theme.muted
                  font.pixelSize: 26
                  font.letterSpacing: 1
                }
              }

              MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                // a click opens the window; with Super held the left button carries it
                property bool moving: false
                // set once the window is carried: letting go is not a click on it
                property bool carried: false
                cursorShape: moving ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                onPressed: mouse => { moving = (mouse.modifiers & Qt.MetaModifier) !== 0; carried = false; }
                onClicked: if (!moving && !carried) root.focus(win.toplevel)
                onPositionChanged: mouse => {
                  if (!moving || !pressed) return;
                  carried = true;
                  root.dragPos = hover.mapToItem(canvas, mouse.x, mouse.y);
                  root.dragged = win;
                  root.placeDragged();
                }
                onReleased: {
                  if (root.dragged === win) {
                    win.Drag.drop();
                    root.dragged = null;
                    win.x = Qt.binding(() => win.wx);
                    win.y = Qt.binding(() => win.wy);
                  }
                  moving = false;
                }
              }
            }
          }
        }
      }
    }
  }
}
