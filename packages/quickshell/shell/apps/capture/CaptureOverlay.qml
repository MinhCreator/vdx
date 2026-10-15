import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.kit

// The capture overlay, one per screen: a still copy of the screen (open bar
// popups included; with or without the pointer), dimmed except for the target — a dragged region, the
// window or the screen under the pointer. The toolbar sits on the focused
// monitor. A shot is cropped from the still at full resolution; a recording
// starts on the target. Esc or a right click cancels.
Variants {
  model: CaptureService.armed ? Quickshell.screens : []

  PanelWindow {
    id: root

    required property var modelData

    readonly property bool toolbarHere: (Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name) === modelData.name
    readonly property Item still: CaptureService.cursor ? stillCursor : stillPlain

    // the plain still: taken once the pointer is hidden, checked, retaken
    property bool plainOn: false
    property bool plainDone: false
    property int plainTries: 0
    readonly property point pointer: Qt.point(CaptureService.pointerAt.x - modelData.x, CaptureService.pointerAt.y - modelData.y)
    readonly property bool pointerHere: pointer.x >= 0 && pointer.y >= 0 && pointer.x < width && pointer.y < height

    function checkPlain() {
      if (!pointerHere || plainTries >= 20) { plainChecked(true); return; }
      probeCursor.scheduleUpdate();
      probePlain.scheduleUpdate();
      probeCursor.grabToImage(c => probePlain.grabToImage(p => comparer.compare(c, p)));
    }

    function plainChecked(clean) {
      if (plainDone || !CaptureService.armed) return;
      if (clean) {
        plainDone = true;
        CaptureService.plainStillReady();
        return;
      }
      plainTries += 1;
      plainOn = false;
      retake.restart();
    }
    readonly property real scale: still.sourceSize.width > 0 ? still.sourceSize.width / width : 1

    // the target in screen coordinates; empty while there is none
    property rect target: Qt.rect(0, 0, 0, 0)
    readonly property bool hasTarget: target.width > 0 && target.height > 0
    // the drawn frame glides between windows / screens, follows a drag at once
    property bool glide: false
    property real fx: target.x
    property real fy: target.y
    property real fw: target.width
    property real fh: target.height
    Behavior on fx { enabled: root.glide; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on fy { enabled: root.glide; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on fw { enabled: root.glide; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on fh { enabled: root.glide; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    readonly property bool live: CaptureService.shown && !CaptureService.closing

    function setTarget(r) {
      glide = hasTarget && CaptureService.mode !== "region";
      target = r;
    }
    property point pressAt: Qt.point(-1, -1)
    property bool dragging: false
    property bool finishing: false      // a shot / recording is on its way: the panel stays gone

    function clampToScreen(r) {
      const x1 = Math.max(0, r.x), y1 = Math.max(0, r.y);
      const x2 = Math.min(width, r.x + r.width), y2 = Math.min(height, r.y + r.height);
      return x2 > x1 && y2 > y1 ? Qt.rect(x1, y1, x2 - x1, y2 - y1) : Qt.rect(0, 0, 0, 0);
    }

    // what the pointer points at in window / screen mode
    function pick(x, y) {
      if (CaptureService.mode === "screen") return Qt.rect(0, 0, width, height);
      const gx = x + modelData.x, gy = y + modelData.y;
      const w = CaptureService.windows.find(w => gx >= w.x && gx < w.x + w.width && gy >= w.y && gy < w.y + w.height);
      return w ? clampToScreen(Qt.rect(w.x - modelData.x, w.y - modelData.y, w.width, w.height)) : Qt.rect(0, 0, 0, 0);
    }

    function finish() {
      if (!hasTarget) return;
      finishing = true;
      if (CaptureService.kind === "record") {
        CaptureService.startRecording(Qt.rect(target.x + modelData.x, target.y + modelData.y, target.width, target.height));
        return;
      }
      const path = CaptureService.shotPath();
      crop.scheduleUpdate();
      crop.grabToImage(result => {
        if (result.saveToFile(path)) CaptureService.shotSaved(path);
        else { CaptureService.fail("Screenshot failed", "could not save " + path); CaptureService.close(); }
      }, Qt.size(Math.round(target.width * scale), Math.round(target.height * scale)));
    }

    screen: modelData
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture"
    WlrLayershell.keyboardFocus: toolbarHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    Connections {
      target: CaptureService
      function onPlainCaptureChanged() { if (CaptureService.plainCapture) root.plainOn = true; }
      function onModeChanged() { root.setTarget(Qt.rect(0, 0, 0, 0)); }
    }

    Item {
      anchors.fill: parent
      opacity: CaptureService.shown ? 1 : 0
      focus: true

      Keys.onEscapePressed: CaptureService.close()

      // Two stills: with the pointer, then without it once CaptureService has
      // hidden it. Hide cursor picks which one is shown and saved, live.
      ScreencopyView {
        id: stillCursor
        anchors.fill: parent
        captureSource: root.modelData
        live: false
        paintCursor: true
        visible: CaptureService.cursor
        onHasContentChanged: if (hasContent) CaptureService.cursorStillReady()
      }

      ScreencopyView {
        id: stillPlain
        anchors.fill: parent
        captureSource: root.plainOn ? root.modelData : null
        live: false
        visible: !CaptureService.cursor
        onHasContentChanged: if (hasContent) root.checkPlain()
      }

      // ---- pointer-free check --------------------------------------------------------
      // Hyprland applies cursor:invisible on its next key event or a 500 ms tick,
      // so the plain still may still hold the pointer. Where the pointer is,
      // compare it with the pointer still; retake until they differ. Meanwhile
      // the overlay keeps redrawing, so every retake sees a fresh frame.
      ShaderEffectSource {
        id: probeCursor
        x: -64
        width: 24
        height: 24
        sourceItem: stillCursor
        sourceRect: Qt.rect(root.pointer.x, root.pointer.y, 24, 24)
        live: false
      }

      ShaderEffectSource {
        id: probePlain
        x: -32
        width: 24
        height: 24
        sourceItem: stillPlain
        sourceRect: Qt.rect(root.pointer.x, root.pointer.y, 24, 24)
        live: false
      }

      // the two probes as images, then compared pixel by pixel on a canvas
      Image { id: shotCursor; x: -128; width: 24; height: 24; cache: false }
      Image { id: shotPlain; x: -160; width: 24; height: 24; cache: false }

      Canvas {
        id: comparer
        x: -96
        width: 24
        height: 24

        property var pending: []

        function compare(cursorShot, plainShot) {
          pending = [cursorShot, plainShot];
          shotCursor.source = cursorShot.url;
          shotPlain.source = plainShot.url;
          tryCompare();
        }

        function tryCompare() {
          if (pending.length < 2 || !available) return;
          if (shotCursor.status !== Image.Ready || shotPlain.status !== Image.Ready) return;
          const ctx = getContext("2d");
          ctx.clearRect(0, 0, 24, 24);
          ctx.drawImage(shotCursor, 0, 0, 24, 24);
          const a = ctx.getImageData(0, 0, 24, 24).data;
          ctx.clearRect(0, 0, 24, 24);
          ctx.drawImage(shotPlain, 0, 0, 24, 24);
          const b = ctx.getImageData(0, 0, 24, 24).data;
          let diff = 0;
          for (let i = 0; i < a.length; i++) diff = Math.max(diff, Math.abs(a[i] - b[i]));
          pending = [];
          shotCursor.source = "";
          shotPlain.source = "";
          root.plainChecked(diff > 40);
        }

        onAvailableChanged: tryCompare()

        Connections {
          target: shotCursor
          function onStatusChanged() { comparer.tryCompare(); }
        }

        Connections {
          target: shotPlain
          function onStatusChanged() { comparer.tryCompare(); }
        }
      }

      Timer {
        id: retake
        interval: 40
        onTriggered: root.plainOn = true
      }

      // redraws this (transparent) overlay every frame until the plain still is
      // in: each new buffer makes Hyprland recompose the screen
      Rectangle {
        id: nudge
        property int frames: 0
        width: 1
        height: 1
        color: "transparent"
        x: frames % 2
      }

      FrameAnimation {
        running: CaptureService.redraw && !root.plainDone
        onTriggered: nudge.frames += 1
      }

      // the crop that gets saved: the still's own pixels, in place, at full size
      ShaderEffectSource {
        id: crop
        x: root.target.x
        y: root.target.y
        width: Math.max(1, root.target.width)
        height: Math.max(1, root.target.height)
        sourceItem: root.still
        sourceRect: root.target
        textureSize: Qt.size(Math.max(1, Math.round(width * root.scale)), Math.max(1, Math.round(height * root.scale)))
        // follows the still while selecting (a frozen texture showed as a black square)
        live: true
        visible: root.hasTarget
      }

      // ---- dim around the target ---------------------------------------------------
      Item {
        anchors.fill: parent
        opacity: root.live ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        readonly property rect r: root.hasTarget ? Qt.rect(root.fx, root.fy, root.fw, root.fh) : Qt.rect(0, 0, 0, 0)

        Rectangle { x: 0; y: 0; width: parent.width; height: parent.r.y; color: Theme.background0; opacity: 0.55 }
        Rectangle { x: 0; y: parent.r.y + parent.r.height; width: parent.width; height: parent.height - y; color: Theme.background0; opacity: 0.55 }
        Rectangle { x: 0; y: parent.r.y; width: parent.r.x; height: parent.r.height; color: Theme.background0; opacity: 0.55 }
        Rectangle { x: parent.r.x + parent.r.width; y: parent.r.y; width: parent.width - x; height: parent.r.height; color: Theme.background0; opacity: 0.55 }
      }

      // the target's frame and size
      Rectangle {
        visible: root.hasTarget && root.live
        x: root.fx - 1
        y: root.fy - 1
        width: root.fw + 2
        height: root.fh + 2
        color: "transparent"
        border.width: Theme.frameWidth
        border.color: CaptureService.kind === "record" ? Theme.red : Theme.foreground0
      }

      Rectangle {
        visible: root.hasTarget && root.live && CaptureService.mode === "region"
        x: Math.min(root.target.x, root.width - width)
        y: root.target.y + root.target.height + 6 + height > root.height ? root.target.y - height - 6 : root.target.y + root.target.height + 6
        width: sizeText.implicitWidth + 12
        height: sizeText.implicitHeight + 6
        color: Theme.background0

        KitText {
          id: sizeText
          anchors.centerIn: parent
          text: Math.round(root.target.width * root.scale) + " × " + Math.round(root.target.height * root.scale)
          font.pixelSize: Theme.fontSize - 2
        }
      }

      // ---- pointer -----------------------------------------------------------------
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // no shape of our own until the stills are taken: a crosshair over the
        // still-transparent overlay would land in the plain still, and differ
        // from the pointer still enough to pass for "the pointer is gone"
        cursorShape: !CaptureService.shown ? Qt.BlankCursor
                   : CaptureService.mode === "region" ? Qt.CrossCursor : Qt.PointingHandCursor

        onPressed: mouse => {
          if (mouse.button === Qt.RightButton) { CaptureService.close(); return; }
          if (CaptureService.mode !== "region") return;
          root.pressAt = Qt.point(mouse.x, mouse.y);
          root.dragging = true;
          root.setTarget(Qt.rect(mouse.x, mouse.y, 0, 0));
        }
        onPositionChanged: mouse => {
          if (CaptureService.mode !== "region") { root.setTarget(root.pick(mouse.x, mouse.y)); return; }
          if (!root.dragging) return;
          root.setTarget(Qt.rect(Math.min(mouse.x, root.pressAt.x), Math.min(mouse.y, root.pressAt.y),
                                Math.abs(mouse.x - root.pressAt.x), Math.abs(mouse.y - root.pressAt.y)));
        }
        onReleased: mouse => {
          if (mouse.button !== Qt.LeftButton) return;
          if (CaptureService.mode === "region") {
            root.dragging = false;
            if (root.target.width < 4 || root.target.height < 4) { root.setTarget(Qt.rect(0, 0, 0, 0)); return; }
          } else {
            root.setTarget(root.pick(mouse.x, mouse.y));
          }
          root.finish();
        }
      }

      // ---- toolbar -----------------------------------------------------------------
      CaptureToolbar {
        id: toolbar
        visible: root.toolbarHere && !root.dragging && !root.finishing
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barHeight + (root.live ? Theme.popupGap : 0)      // where the bar's popups open
        opacity: root.live ? 1 : 0

        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
      }
    }
  }
}
