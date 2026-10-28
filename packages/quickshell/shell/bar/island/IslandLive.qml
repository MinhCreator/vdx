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
  // folded, the activity sits in a chip of its own; in full the pill is its background
  readonly property bool chip: !IslandService.liveFull
  property real pad: chip ? 18 : 0
  Behavior on pad { enabled: Motion.island; NumberAnimation { id: padAnim; duration: Motion.normal; easing.type: Motion.easing } }
  // the slot's width is moving: the island follows it as it goes, without a glide of its own
  readonly property bool moving: targetAnim.running || padAnim.running
  implicitWidth: kind === "" ? 0 : target + pad
  implicitHeight: Theme.islandHeight
  visible: kind !== ""
  property real target: (sliding ? backFace : frontFace).implicitWidth
  Behavior on target { enabled: Motion.island; NumberAnimation { id: targetAnim; duration: Motion.normal; easing.type: Motion.easing } }

  function place() {
    const dir = IslandService.liveDir;
    if (!sliding) {
      frontFace.x = pad * 0.45;
      frontFace.anchors.verticalCenterOffset = 0; frontFace.opacity = 1;
      backFace.opacity = 0;
      return;
    }
    frontFace.x = pad * 0.45; backFace.x = pad * 0.45;
    frontFace.anchors.verticalCenterOffset = -dir * travel * t; frontFace.opacity = 1 - t;
    backFace.anchors.verticalCenterOffset = dir * travel * (1 - t); backFace.opacity = t;
  }
  onTChanged: place()
  onPadChanged: place()

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
    height: 26
    radius: 13
    color: Theme.background2
    opacity: root.chip ? 1 : 0
    Behavior on opacity { enabled: Motion.island; NumberAnimation { duration: Motion.normal } }
  }

  IslandLiveFace { id: faceA; full: IslandService.liveOpen }
  IslandLiveFace { id: faceB; full: IslandService.liveOpen }

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
