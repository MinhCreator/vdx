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
// dropping it off the preview.
Rectangle {
  id: root

  property string screenName

  readonly property int iconStep: 24          // a 14px icon and its gap
  readonly property var children: BarLayout.barsOn(screenName)
  readonly property var center: BarLayout.visibleIn("center", screenName)
  // icons one side has room for: its half, less the centre's half and margins
  readonly property int perSide: Math.max(1, Math.floor((width / 2 - center.length * iconStep / 2 - 12 - 16) / iconStep))

  function shown(ids) { return ids.length <= perSide ? ids : ids.slice(0, perSide - 1); }
  function extra(ids) { return ids.length <= perSide ? 0 : ids.length - perSide + 1; }

  // filled, unlike the bands of chips under it
  height: 30
  radius: Theme.radiusCard
  color: Theme.island ? "transparent" : Theme.background1

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
    height: parent.height - 4
    radius: Math.min(height / 2, Theme.islandRadius)
    color: Theme.background1

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
    property string side
    property string place
    spacing: 4
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
      id: minis
      model: root.children.filter(b => b.side === minis.parent.side && b.place === minis.parent.place)
      // a child bar in small: its first icons, or a + while it is empty
      Rectangle {
        id: mini
        required property var modelData
        readonly property var bar: modelData
        readonly property var ids: BarLayout.barModules(root.screenName, bar.id)

        width: miniIcons.width + 2 * Theme.gapMedium
        height: root.height - 8
        radius: Theme.island ? Math.min(height / 2, Theme.islandRadius) : Theme.radiusControl
        color: area.containsMouse || root.dragId === bar.id ? Theme.background3 : Theme.background2
        opacity: root.dragId === bar.id ? 0.35 : 1

        BarPreviewIcons {
          id: miniIcons
          anchors.centerIn: parent
          spacing: Theme.gapSmall
          ids: mini.ids.length > 0 ? mini.ids.slice(0, 3) : ["plus"]
          more: Math.max(0, mini.ids.length - 3)
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
      }
    }
  }

  Group { id: edgeLeft; side: "left"; place: "edge"; x: root.spots[0].x }
  // no centre: the groups meant for it meet in the middle
  readonly property real join: besideLeft.width > 0 && besideRight.width > 0 ? gap : 0
  readonly property real meet: cx - (besideLeft.width + besideRight.width + join) / 2
  Group { id: besideLeft; side: "left"; place: "island"; x: root.centreGone ? root.meet : root.spots[1].x - width }
  Group { id: besideRight; side: "right"; place: "island"; x: root.centreGone ? root.meet + besideLeft.width + root.join : root.spots[2].x }
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

  // the spots, while a child bar is in the air: the one it would take lit
  Repeater {
    model: root.dragId !== "" ? root.spots : []

    Rectangle {
      required property var modelData
      required property int index
      x: modelData.x - width / 2
      anchors.verticalCenter: parent.verticalCenter
      width: 4
      height: root.height - 6
      radius: Theme.pill(width)
      color: root.target === index ? Theme.foreground0 : Theme.background3
    }
  }

  Rectangle {
    id: ghost
    property var ids: []
    visible: root.dragId !== ""
    height: root.height - 8
    radius: Theme.island ? Math.min(height / 2, Theme.islandRadius) : Theme.radiusControl
    color: Theme.background3
    border.width: root.target < 0 ? Theme.islandFrameWidth : 0
    border.color: Theme.red
    opacity: root.target < 0 ? 0.6 : 1

    BarPreviewIcons {
      anchors.centerIn: parent
      spacing: Theme.gapSmall
      ids: ghost.ids
    }
  }
}
