import QtQuick
import qs.config

// The pill's live slot: the running activity (IslandService.live), only while
// something runs. The wheel pages through them: the shown one slides up and
// fades while the next comes in from below (back: the other way), inside the
// pill's height.
Item {
  id: root

  readonly property string kind: IslandService.live
  readonly property real travel: Theme.islandHeight * 0.6

  // two faces take turns: `front` is the shown one; `t` runs 0 → 1 while a step slides
  property int front: 0
  property real t: 0
  property bool sliding: false
  readonly property Item frontFace: front === 0 ? faceA : faceB
  readonly property Item backFace: front === 0 ? faceB : faceA

  clip: true
  // the activity sits in a chip of its own, folded or open: concentric with the
  // pill — the same gap (`edge`) to the pill's rim above and below, its corners
  // the pill's less that gap; a cover inside sits `inset` from the chip's rim
  readonly property int edge: 4
  readonly property int inset: 3
  readonly property int chipHeight: Theme.islandHeight - 2 * edge
  readonly property int chipRadius: Math.max(0, Math.min(Theme.barRadiusFor(Theme.islandHeight), Theme.islandRadius) - edge)
  readonly property int coverSize: chipHeight - 2 * inset
  readonly property bool covered: (sliding ? backFace : frontFace).kind === "music" || (sliding ? backFace : frontFace).kind === "track"
  // a cover starts at the inset, text and marks a little further in
  readonly property int padLeft: covered ? inset : Theme.gapLoose
  readonly property int padRight: Theme.gapLoose
  // the slot's width is moving: the island follows it as it goes, without a glide of its own
  readonly property bool moving: targetAnim.running
  implicitWidth: kind === "" ? 0 : target + padLeft + padRight
  implicitHeight: Theme.islandHeight
  visible: kind !== ""
  property real target: (sliding ? backFace : frontFace).implicitWidth
  Behavior on target { enabled: Motion.island; NumberAnimation { id: targetAnim; duration: Motion.normal; easing.type: Motion.easing } }

  function place() {
    const dir = IslandService.liveDir;
    if (!sliding) {
      frontFace.x = padLeft;
      frontFace.anchors.verticalCenterOffset = 0; frontFace.opacity = 1;
      backFace.opacity = 0;
      return;
    }
    frontFace.x = padLeft; backFace.x = padLeft;
    frontFace.anchors.verticalCenterOffset = -dir * travel * t; frontFace.opacity = 1 - t;
    backFace.anchors.verticalCenterOffset = dir * travel * (1 - t); backFace.opacity = t;
  }
  onTChanged: place()
  onPadLeftChanged: place()

  onKindChanged: {
    slide.stop();
    sliding = false;
    // nothing before or nothing after: no slide, the face just is
    if (kind === "" || frontFace.kind === "" || !Motion.island) {
      frontFace.kind = kind;
      backFace.kind = "";
      place();
      return;
    }
    backFace.kind = kind;
    t = 0;
    sliding = true;
    slide.start();
  }

  NumberAnimation {
    id: slide
    target: root
    property: "t"
    from: 0
    to: 1
    duration: Motion.normal
    easing.type: Motion.easing
    onFinished: {
      root.sliding = false;
      root.frontFace.kind = "";
      root.front = 1 - root.front;
      root.place();
    }
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root.chipHeight
    radius: root.chipRadius
    color: Theme.background2
  }

  IslandLiveFace { id: faceA; full: IslandService.liveOpen; coverSize: root.coverSize }
  IslandLiveFace { id: faceB; full: IslandService.liveOpen; coverSize: root.coverSize }

  Component.onCompleted: { faceA.kind = kind; place(); }

  // a hover opens the slot in place (IslandService.liveHeld)
  HoverHandler {
    enabled: root.kind !== "" && ShellSettings.liveHover
    onHoveredChanged: IslandService.liveHeld = hovered
  }

  // the wheel pages; a click unfolds the card (music: the media view)
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: w => IslandService.liveStep(w.angleDelta.y < 0 ? 1 : -1)
  }
}
