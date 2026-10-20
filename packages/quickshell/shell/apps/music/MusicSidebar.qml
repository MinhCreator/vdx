import QtQuick
import qs.config
import qs.kit
import qs.modules.radio
import qs.modules.yandex

// The Music window's sidebar: the tabs of the sources installed (KitChoices, stretched),
// then the tab's own rows. Yandex Music: LIKES (Likes, Search) and PLAYLISTS with a row
// to make one. Files: FOLDERS, the folders of music.folders. Radio: ALL STATIONS and
// FAVOURITES (the starred ones).
Item {
  id: root

  required property var music   // the Music window's layout

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

      KitChoices {
        width: column.width
        stretch: true
        model: root.music.tabs
        current: root.music.tab
        onPicked: value => root.music.go(value)
      }

      KitSideCaption { text: "YANDEX MUSIC"; lead: Theme.gapMedium; visible: root.music.tab === "yandex" }

      KitSideRow {
        visible: root.music.tab === "yandex"
        icon: "heart"
        text: "Likes"
        hint: root.music.yandexOn ? YandexService.liked.length + "" : ""
        current: root.music.page === "likes"
        onClicked: root.music.go("likes")
      }

      KitSideRow {
        visible: root.music.tab === "yandex"
        icon: "search"
        text: "Search"
        current: root.music.page === "search"
        onClicked: root.music.go("search")
      }

      KitSideCaption { text: "PLAYLISTS"; lead: Theme.gapMedium; visible: root.music.tab === "yandex" }

      Repeater {
        model: root.music.tab === "yandex" && root.music.yandexOn ? YandexLibrary.playlists : []

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
        visible: root.music.tab === "yandex" && root.music.yandexOn && !root.creating
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
        visible: root.music.tab === "yandex" && root.music.yandexOn && root.creating
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
      KitSideCaption { text: "STATIONS"; lead: Theme.gapMedium; visible: root.music.tab === "radio" }

      KitSideRow {
        visible: root.music.tab === "radio" && root.music.radioOn
        icon: "radio"
        text: "All stations"
        hint: RadioService.stations.length + ""
        current: root.music.radioPage === "all"
        onClicked: root.music.radioPage = "all"
      }

      KitSideRow {
        visible: root.music.tab === "radio" && root.music.radioOn
        icon: "star"
        text: "Favourites"
        hint: RadioService.favoriteStations.length + ""
        current: root.music.radioPage === "favorites"
        onClicked: root.music.radioPage = "favorites"
      }

      // ---- files ----
      KitSideCaption { text: "FOLDERS"; lead: Theme.gapMedium; visible: root.music.tab === "files" }

      Repeater {
        model: root.music.tab === "files" ? root.music.folders : []

        KitSideRow {
          required property var modelData
          icon: "folder"
          text: root.music.nameOf(modelData)
          current: root.music.dir === modelData || root.music.dir.startsWith(modelData + "/")
          onClicked: {
            root.music.folder = modelData;
            root.music.go("files");
          }
        }
      }
    }
  }
}
