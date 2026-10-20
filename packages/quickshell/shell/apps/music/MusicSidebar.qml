import QtQuick
import qs.config
import qs.kit
import qs.modules.player
import qs.modules.radio
import qs.modules.yandex

// The Music window's sidebar, in sections as Files': LISTEN (Now playing), YANDEX
// MUSIC (Likes, Search) and its PLAYLISTS with a row to make one, RADIO (Stations).
// A section shows only while its component is installed (`yandexOn`, `radioOn`).
Item {
  id: root

  required property var music   // the Music window's layout
  property bool yandexOn: false
  property bool radioOn: false
  property bool creating: false   // the New playlist row is a field

  Flickable {
    id: side
    anchors.fill: parent
    contentHeight: column.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      width: side.width
      spacing: Theme.gapTight

      KitSideCaption { text: "LISTEN" }

      KitSideRow {
        icon: "play"
        text: "Now playing"
        hint: PlayerService.hasMedia ? PlayerService.name : ""
        current: root.music.page === "playing"
        onClicked: root.music.go("playing")
      }

      // ---- Yandex Music ----
      KitSideCaption { text: "YANDEX MUSIC"; lead: Theme.gapMedium; visible: root.yandexOn }

      KitSideRow {
        visible: root.yandexOn
        icon: "heart"
        text: "Likes"
        hint: root.yandexOn ? YandexService.liked.length + "" : ""
        current: root.music.page === "likes"
        onClicked: root.music.go("likes")
      }

      KitSideRow {
        visible: root.yandexOn
        icon: "search"
        text: "Search"
        current: root.music.page === "search"
        onClicked: root.music.go("search")
      }

      KitSideCaption { text: "PLAYLISTS"; lead: Theme.gapMedium; visible: root.yandexOn }

      Repeater {
        model: root.yandexOn ? YandexLibrary.playlists : []

        KitSideRow {
          required property var modelData
          icon: "list"
          text: modelData.title
          hint: modelData.count + ""
          current: root.music.page === "playlist" && root.music.playlistKind === modelData.kind
          onClicked: root.music.openPlaylist(modelData)
        }
      }

      KitSideRow {
        visible: root.yandexOn && !root.creating
        icon: "plus"
        text: "New playlist"
        onClicked: {
          root.creating = true;
          Qt.callLater(() => field.input.forceActiveFocus());
        }
      }

      // the new playlist's name: Enter makes it, Escape gives up
      KitInput {
        id: field
        visible: root.yandexOn && root.creating
        width: parent.width
        placeholder: "name, Enter"
        passKeys: [Qt.Key_Escape]
        onAccepted: {
          YandexLibrary.createPlaylist(text);
          text = "";
          root.creating = false;
        }
        onKeyPassed: {
          text = "";
          root.creating = false;
        }
      }

      // ---- radio ----
      KitSideCaption { text: "RADIO"; lead: Theme.gapMedium; visible: root.radioOn }

      KitSideRow {
        visible: root.radioOn
        icon: "radio"
        text: "Stations"
        hint: root.radioOn && RadioService.active ? "playing" : ""
        current: root.music.page === "radio"
        onClicked: root.music.go("radio")
      }
    }
  }
}
