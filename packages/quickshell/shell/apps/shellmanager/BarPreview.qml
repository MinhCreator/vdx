import QtQuick
import qs.bar
import qs.config
import qs.kit

// A glance at one monitor's bar on the Bar page: icons left, centre and right
// as on screen. Not for dragging — a side that runs out of room ends in +N.
// Island style: the resting pill — LEFT, the clock, RIGHT — on an empty strip.
Rectangle {
  radius: Theme.radiusCard
  id: root

  property string screenName

  readonly property int iconStep: 24          // a 14px icon and its gap
  readonly property var center: BarLayout.visibleIn("center", screenName)
  // icons one side has room for: its half, less the centre's half and margins
  readonly property int perSide: Math.max(1, Math.floor((width / 2 - center.length * iconStep / 2 - 12 - 16) / iconStep))

  function shown(ids) { return ids.length <= perSide ? ids : ids.slice(0, perSide - 1); }
  function extra(ids) { return ids.length <= perSide ? 0 : ids.length - perSide + 1; }

  // filled, unlike the bands of chips under it
  height: 30
  color: Theme.island ? "transparent" : Theme.background1

  Rectangle {
    visible: Theme.island
    anchors.centerIn: parent
    width: pill.width + 2 * Theme.gapWide
    height: parent.height - 4
    radius: Theme.pill(height)
    color: Theme.background1

    Row {
      id: pill
      anchors.centerIn: parent
      spacing: Theme.gapLoose

      Repeater {
        model: Theme.island ? BarLayout.islandIn("start", root.screenName).concat(["clock"], BarLayout.islandIn("end", root.screenName)) : []

        KitIcon {
          required property string modelData
          anchors.verticalCenter: parent.verticalCenter
          name: BarLayout.icon(modelData)
          tint: modelData === "clock" ? Theme.foreground0 : Theme.foreground2
          size: Theme.iconSmall
        }
      }
    }
  }

  Repeater {
    model: Theme.island ? [] : BarLayout.zones

    Row {
      id: group

      required property string modelData

      readonly property var ids: BarLayout.visibleIn(modelData, root.screenName)

      anchors.verticalCenter: parent.verticalCenter
      x: modelData === "left" ? 12 : modelData === "center" ? (root.width - width) / 2 : root.width - width - 12
      spacing: Theme.gapLoose

      Repeater {
        model: group.modelData === "center" ? group.ids : root.shown(group.ids)

        KitIcon {
          required property string modelData
          anchors.verticalCenter: parent.verticalCenter
          name: BarLayout.icon(modelData)
          tint: Theme.foreground2
          size: Theme.iconSmall
        }
      }

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        visible: group.modelData !== "center" && root.extra(group.ids) > 0
        text: "+" + root.extra(group.ids)
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }
  }
}
