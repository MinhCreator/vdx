import QtQuick
import qs.config
import qs.kit
import qs.modules.mpd

// Radio: what's on air and the station list; click a station to tune in.
KitFrame {
  id: root

  // ---- header ----
  KitHeader {
    icon: "radio"
    iconColor: RadioService.active ? Theme.foreground0 : Theme.muted
    title: "Radio"
    subtitle: RadioService.active ? "ON AIR · " + MpdService.player.station.toUpperCase() : "OFF"

    KitSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: RadioService.active
      disabled: RadioService.stations.length === 0
      onToggled: RadioService.setActive(!RadioService.active)
    }
  }

  KitLine {}

  // ---- now playing ----
  Column {
    width: parent.width
    visible: RadioService.active
    spacing: Theme.gapSmall

    KitLabel { text: "NOW PLAYING" }

    KitText {
      width: parent.width
      text: MpdService.player.title || "—"
      wrapMode: Text.Wrap
      font.weight: Font.ExtraBold
    }
  }

  KitLine { visible: RadioService.active }

  // ---- stations ----
  Column {
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel { text: "STATIONS (" + RadioService.stations.length + ")" }

    KitText {
      visible: RadioService.stations.length === 0
      text: "No stations configured."
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }

    Flickable {
      width: parent.width
      height: Math.min(contentHeight, 30 * Theme.visibleRows)
      contentHeight: stations.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: stations
        width: parent.width

        Repeater {
          model: RadioService.stations

          Rectangle {
            radius: Theme.radiusControl
            id: station

            required property var modelData

            readonly property bool current: RadioService.active && RadioService.stationKey === modelData.key

            width: stations.width
            height: 30
            color: current ? Theme.background3 : area.containsMouse ? Theme.background1 : "transparent"

            KitText {
              anchors { left: parent.left; leftMargin: Theme.gapLoose; right: mark.left; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
              text: station.modelData.name
              elide: Text.ElideRight
              color: station.current || area.containsMouse ? Theme.foreground0 : Theme.foreground2
              font.weight: station.current ? Font.ExtraBold : Font.DemiBold
            }

            Item {
              id: mark
              anchors { right: parent.right; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
              width: 14
              height: 14

              KitSpinner {
                anchors.centerIn: parent
                visible: MpdService.busy === station.modelData.key
              }

              KitIcon {
                anchors.centerIn: parent
                visible: station.current && MpdService.busy !== station.modelData.key
                name: "check"
                tint: Theme.green
                size: Theme.iconSmall
              }
            }

            MouseArea {
              id: area
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: station.current ? Qt.ArrowCursor : Qt.PointingHandCursor
              onClicked: if (!station.current) RadioService.play(station.modelData.key)
            }
          }
        }
      }
    }
  }

  KitText {
    width: parent.width
    visible: MpdService.error !== ""
    text: MpdService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
