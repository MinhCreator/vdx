import QtQuick
import qs.bar
import qs.config
import qs.kit

// A glance at one monitor's bar on the Bar page: icons left, centre and right
// as on screen — a side that runs out of room ends in +N. Island style: the
// resting pill (LEFT, the clock, RIGHT) on an empty strip.
//
// Its child bars show where they sit; one is placed by dragging it to one of
// four spots (at either edge, on either side of the centre) and removed by
// its corner cross or by dropping it off the preview; a thin line marks the
// spot it lands on. An empty framed bar right of the centre adds
// one there (while none is still empty).
Rectangle {
  id: root

  property string screenName

  // child bars already on show, by spot: one that is new there (added, or
  // dropped on another spot) grows in
  property KitSeen seen: KitSeen {}
  onScreenNameChanged: seen.reset()

  readonly property int iconStep: 24          // a 14px icon and its gap
  readonly property var children: BarLayout.barsOn(screenName)
  readonly property var center: BarLayout.visibleIn("center", screenName)
  // icons one side has room for: its half, less the centre's half and margins
  readonly property int perSide: Math.max(1, Math.floor((width / 2 - center.length * iconStep / 2 - 12 - 16) / iconStep))

  function shown(ids) { return ids.length <= perSide ? ids : ids.slice(0, perSide - 1); }
  function extra(ids) { return ids.length <= perSide ? 0 : ids.length - perSide + 1; }

  // filled, unlike the bands of chips under it; the box it sits in is filled
  // in material, so the bar takes the page's colour there
  height: 30
  radius: Theme.radiusCard
  // the island's pill and every bar beside it: one height
  readonly property int pillHeight: Theme.island ? height - 4 : height - 8
  readonly property color surface: Theme.material ? Theme.background0 : Theme.background1
  color: Theme.island ? "transparent" : surface

  // ---- the main bar ----
  BarPreviewIcons {
    id: leftIcons
    visible: !Theme.island
    anchors.verticalCenter: parent.verticalCenter
    x: 12
    ids: Theme.island ? [] : root.shown(BarLayout.visibleIn("left", root.screenName))
    more: Theme.island ? 0 : root.extra(BarLayout.visibleIn("left", root.screenName))
  }

  BarPreviewIcons {
    id: centreIcons
    visible: !Theme.island
    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
    ids: Theme.island ? [] : root.center
  }

  BarPreviewIcons {
    id: rightIcons
    visible: !Theme.island
    anchors.verticalCenter: parent.verticalCenter
    x: root.width - width - 12
    ids: Theme.island ? [] : root.shown(BarLayout.visibleIn("right", root.screenName))
    more: Theme.island ? 0 : root.extra(BarLayout.visibleIn("right", root.screenName))
  }

  Rectangle {
    id: islandPill
    visible: Theme.island && pillIcons.width > 0
    anchors.centerIn: parent
    width: pillIcons.width + 2 * Theme.gapWide
    height: root.pillHeight
    radius: Math.min(height / 2, Theme.islandRadius)
    color: root.surface

    BarPreviewIcons {
      id: pillIcons
      anchors.centerIn: parent
      ids: Theme.island ? BarLayout.islandIn("start", root.screenName)
        .concat(BarLayout.islandClock(root.screenName) ? ["clock"] : [], BarLayout.islandIn("end", root.screenName)) : []
    }
  }

  // ---- child bars ----
  // the centre they stick to, and the four spots, as Bar.qml lays them out
  readonly property bool centreGone: Theme.island ? !islandPill.visible : centreIcons.width === 0
  readonly property real cx: centreGone ? width / 2 : Theme.island ? islandPill.x : centreIcons.x
  readonly property real cw: centreGone ? 0 : Theme.island ? islandPill.width : centreIcons.width
  readonly property int gap: 6
  readonly property var spots: [
    { side: "left",  place: "edge",   x: Theme.island || leftIcons.width === 0 ? 8 : leftIcons.x + leftIcons.width + gap },
    { side: "left",  place: "island", x: cx - gap },
    { side: "right", place: "island", x: cx + cw + gap },
    { side: "right", place: "edge",   x: Theme.island || rightIcons.width === 0 ? width - 8 : rightIcons.x - gap }
  ]

  component Group: Row {
    id: group
    property string side
    property string place
    property bool adds: false                  // ends in the empty bar that adds one
    spacing: 4
    anchors.verticalCenter: parent.verticalCenter
    // the groups make room for a bar that comes or goes
    Behavior on x { enabled: Motion.controls && root.seen.ready; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

    Repeater {
      id: minis
      model: root.children.filter(b => b.side === minis.parent.side && b.place === minis.parent.place)
      // a child bar in small: its first icons, or its name while it has none
      Rectangle {
        id: mini
        required property var modelData
        readonly property var bar: modelData
        readonly property var ids: BarLayout.barModules(root.screenName, bar.id)

        width: (mini.ids.length > 0 ? miniIcons.width : emptyText.implicitWidth) + 2 * Theme.gapMedium
        height: root.pillHeight
        radius: Theme.island ? Math.min(height / 2, Theme.islandRadius) : Theme.radiusControl
        color: area.containsMouse || root.dragId === bar.id ? Theme.background3 : Theme.background2
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
        // grown: 0 → 1 as it comes in; dim: lifted while it is dragged
        property real grown: 1
        property real dim: root.dragId === bar.id ? 0.35 : 1
        Behavior on dim { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
        Behavior on width { enabled: Motion.controls && root.seen.ready; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
        opacity: dim * grown
        scale: 0.7 + 0.3 * grown

        NumberAnimation { id: growIn; target: mini; property: "grown"; from: 0; to: 1; duration: Motion.normal; easing.type: Motion.easing }
        Component.onCompleted: if (root.seen.arrived(bar.id + "/" + bar.side + "/" + bar.place)) growIn.start()

        BarPreviewIcons {
          id: miniIcons
          anchors.centerIn: parent
          spacing: Theme.gapSmall
          visible: mini.ids.length > 0
          ids: mini.ids.slice(0, 3)
          more: Math.max(0, mini.ids.length - 3)
        }

        KitText {
          id: emptyText
          anchors.centerIn: parent
          visible: mini.ids.length === 0
          // as its band below is called
          text: "Bar " + (root.children.findIndex(b => b.id === mini.bar.id) + 2)
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          preventStealing: true
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
          property real grab: 0
          onPressed: mouse => {
            grab = mouse.x;
            root.dragId = mini.bar.id;
            ghost.width = mini.width;
            ghost.ids = miniIcons.ids;
            root.follow(mapToItem(root, mouse.x, mouse.y), grab);
          }
          onPositionChanged: mouse => { if (pressed) root.follow(mapToItem(root, mouse.x, mouse.y), grab); }
          onReleased: root.land()
        }

        // a cross in the corner while the pointer is on it: removes the bar
        Rectangle {
          visible: (area.containsMouse || closeArea.containsMouse) && root.dragId === ""
          anchors { right: parent.right; top: parent.top; rightMargin: -6; topMargin: -6 }
          width: 18
          height: 18
          radius: Theme.pill(height)
          color: closeArea.containsMouse ? Theme.red : Theme.background3
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
          border.width: Theme.islandFrameWidth
          border.color: Theme.background0

          KitIcon {
            anchors.centerIn: parent
            name: "x"
            size: 12
            tint: closeArea.containsMouse ? Theme.background0 : Theme.foreground0
          }

          MouseArea {
            id: closeArea
            anchors { fill: parent; margins: -3 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: BarLayout.removeBar(root.screenName, mini.bar.id)
          }
        }
      }
    }

    // a bar still to come, where a new one lands: a click adds it
    Rectangle {
      // one empty child bar at a time: fill it first
      readonly property bool wanted: group.adds && root.dragId === "" && !root.children.some(b => BarLayout.barModules(root.screenName, b.id).length === 0)
      opacity: wanted ? 1 : 0
      visible: opacity > 0
      Behavior on opacity { enabled: Motion.controls && root.seen.ready; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
      anchors.verticalCenter: parent.verticalCenter
      width: addIcon.width + 2 * Theme.gapMedium + 8
      height: root.pillHeight
      radius: Theme.island ? Math.min(height / 2, Theme.islandRadius) : Theme.radiusControl
      color: addArea.containsMouse ? Theme.background2 : Theme.clear
      border.width: Theme.islandFrameWidth
      border.color: addArea.containsMouse ? Theme.foreground2 : Theme.background3
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

      KitIcon {
        id: addIcon
        anchors.centerIn: parent
        name: "plus"
        size: Theme.iconSmall
        tint: addArea.containsMouse ? Theme.foreground0 : Theme.muted
      }

      MouseArea {
        id: addArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: BarLayout.addBar(root.screenName)
      }
    }
  }

  Group { id: edgeLeft; side: "left"; place: "edge"; x: root.spots[0].x }
  // no centre: the groups meant for it meet in the middle
  readonly property real join: besideLeft.width > 0 && besideRight.width > 0 ? gap : 0
  readonly property real meet: cx - (besideLeft.width + besideRight.width + join) / 2
  Group { id: besideLeft; side: "left"; place: "island"; x: root.centreGone ? root.meet : root.spots[1].x - width }
  Group { id: besideRight; side: "right"; place: "island"; adds: true; x: root.centreGone ? root.meet + besideLeft.width + root.join : root.spots[2].x }
  Group { id: edgeRight; side: "right"; place: "edge"; x: root.spots[3].x - width }

  // ---- dragging one ----
  property string dragId: ""
  property int target: -1                      // the nearest spot, -1 off the preview
  property real dropY: 0

  function follow(p, grab) {
    ghost.x = p.x - grab;
    ghost.y = p.y - ghost.height / 2;
    dropY = p.y;
    const centre = ghost.x + ghost.width / 2;
    if (Math.abs(p.y - height / 2) > height * 1.5) { target = -1; return; }
    let best = 0;
    for (let i = 1; i < spots.length; i++)
      if (Math.abs(spots[i].x - centre) < Math.abs(spots[best].x - centre)) best = i;
    target = best;
  }

  function land() {
    const id = dragId;
    dragId = "";
    if (target < 0) BarLayout.removeBar(screenName, id);
    else BarLayout.updateBar(screenName, id, { side: spots[target].side, place: spots[target].place });
    target = -1;
  }

  // where a child bar in the air lands: a thin line, as between chips below
  Rectangle {
    visible: root.dragId !== "" && root.target >= 0
    x: root.target >= 0 ? root.spots[root.target].x - width / 2 : 0
    Behavior on x { enabled: Motion.controls && root.dragId !== ""; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    anchors.verticalCenter: parent.verticalCenter
    width: 2
    height: root.pillHeight
    color: Theme.foreground0
  }

  Rectangle {
    id: ghost
    property var ids: []
    visible: root.dragId !== ""
    height: root.pillHeight
    radius: Theme.island ? Math.min(height / 2, Theme.islandRadius) : Theme.radiusControl
    color: Theme.background3
    border.width: root.target < 0 ? Theme.islandFrameWidth : 0
    border.color: Theme.red
    opacity: root.target < 0 ? 0.6 : 1
    Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }

    BarPreviewIcons {
      anchors.centerIn: parent
      spacing: Theme.gapSmall
      ids: ghost.ids
    }
  }
}
