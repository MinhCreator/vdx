import QtQuick
import qs.bar
import qs.config
import qs.kit

// Themes: a gallery of cards, each a live miniature of the desktop in that
// theme's colours; the search field narrows it once there are many.
Column {
  id: root

  property string query: ""

  readonly property var shown: ThemeService.themes.filter(t => t.toLowerCase().includes(query.trim().toLowerCase()))

  spacing: 14

  KitHeader {
    icon: "sun"
    title: "Themes"
    subtitle: ThemeService.themes.length + " INSTALLED · " + (ThemeService.current || "—").toUpperCase() + " ACTIVE"
  }

  KitInput {
    visible: ThemeService.themes.length > 6
    placeholder: "search themes"
    text: root.query
    onTextEdited: root.query = text
  }

  KitLine {}

  // one card per theme: a live miniature in its colours and its name; click
  // to switch (nothing moves, nothing opens)
  Column {
    width: parent.width
    spacing: 6

    Row {
      id: cards
      width: parent.width
      spacing: 8

      readonly property real cardWidth: Math.floor((width - 16) / 3)

      Repeater {
        model: root.shown

        Rectangle {
          id: card

          required property string modelData

          readonly property bool active: modelData === ThemeService.current

          width: cards.cardWidth
          height: preview.height + caption.height + 12
          color: active ? Theme.background3 : cardArea.containsMouse ? Theme.background1 : "transparent"
          border.width: Theme.frameWidth
          border.color: active || cardArea.containsMouse ? Theme.foreground2 : Theme.gray

          ThemePreview {
            id: preview
            x: 5
            y: 5
            width: parent.width - 10
            height: Math.round(width * 0.62)
            palette: ThemeService.palettes[card.modelData] ?? ({})
          }

          Item {
            id: caption
            anchors { left: parent.left; right: parent.right; top: preview.bottom; topMargin: 2 }
            height: 26

            KitText {
              anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
              text: card.modelData
              color: card.active ? Theme.foreground0 : Theme.foreground2
              font.weight: card.active ? Font.ExtraBold : Font.DemiBold
            }

            Item {
              anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
              width: 14
              height: 14

              KitSpinner {
                anchors.centerIn: parent
                visible: ThemeService.applying === card.modelData
              }

              KitIcon {
                anchors.centerIn: parent
                visible: card.active && ThemeService.applying !== card.modelData
                name: "check"
                size: 14
              }
            }
          }

          MouseArea {
            id: cardArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: card.active ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: ThemeService.apply(card.modelData)
          }
        }
      }
    }

    KitText {
      width: parent.width
      visible: ThemeService.error !== ""
      text: ThemeService.error
      color: Theme.red
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }
  }

  KitText {
    visible: root.shown.length === 0
    text: "No theme matches \"" + root.query + "\"."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }
}
