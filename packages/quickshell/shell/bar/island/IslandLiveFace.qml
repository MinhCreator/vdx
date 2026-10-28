import QtQuick
import QtQuick.Effects
import qs.apps.backup
import qs.apps.capture
import qs.config
import qs.kit
import qs.modules.equalizer

// One face of the pill's live slot (IslandLive): what the activity `kind` shows.
Row {
  id: face

  property string kind: ""
  property bool full: false                    // the whole activity, not just its mark

  anchors.verticalCenter: parent.verticalCenter
  spacing: 8
  visible: kind !== ""

  // recording
  Rectangle {
    visible: face.kind === "recording"
    anchors.verticalCenter: parent.verticalCenter
    width: 8
    height: 8
    radius: 4
    color: Theme.red
  }
  KitText {
    visible: face.kind === "recording" && face.full
    text: "Recording"
    color: Theme.foreground2
  }
  KitText {
    visible: face.kind === "recording"
    text: CaptureService.elapsedText
    color: Theme.foreground1
  }

  // update
  KitIcon { visible: face.kind === "update"; name: "download"; tint: Theme.blue; size: 14; anchors.verticalCenter: parent.verticalCenter }
  KitText { visible: face.kind === "update"; text: face.full ? "Updating packages" : "Updating"; color: Theme.blue }

  // backup: BKP and its progress
  KitText { visible: face.kind === "backup"; text: "BKP"; color: Theme.foreground1; font.letterSpacing: 1 }
  Rectangle {
    visible: face.kind === "backup"
    anchors.verticalCenter: parent.verticalCenter
    width: 70
    height: 4
    radius: 2
    color: Theme.background3
    Rectangle {
      width: parent.width * Math.max(0, BackupService.progress) / 100
      height: parent.height
      radius: 2
      color: Theme.green
    }
  }

  KitText {
    visible: face.kind === "backup" && face.full
    text: Math.max(0, Math.round(BackupService.progress)) + "%"
    color: Theme.foreground2
  }

  // music: the cover, in full the track too, and the sound
  Item {
    visible: face.kind === "music"
    anchors.verticalCenter: parent.verticalCenter
    width: 22
    height: 22

    Image {
      id: cover
      anchors.fill: parent
      visible: false
      source: IslandService.cover
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
    Item {
      id: round
      anchors.fill: parent
      visible: false
      layer.enabled: true
      Rectangle { anchors.fill: parent; radius: width / 2 }
    }
    // a circle: the cover's corners cut by the mask
    MultiEffect {
      anchors.fill: parent
      source: cover
      maskEnabled: true
      maskSource: round
    }
    Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.background3; z: -1 }
  }
  KitText {
    visible: face.kind === "music" && face.full
    anchors.verticalCenter: parent.verticalCenter
    width: Math.min(implicitWidth, 260)
    elide: Text.ElideRight
    text: IslandService.title + (IslandService.artist !== "" ? " · " + IslandService.artist : "")
    color: Theme.foreground1
  }
  EqualizerBars {
    visible: face.kind === "music"
    anchors.verticalCenter: parent.verticalCenter
    barCount: 4
    tone: Theme.green
    height: 14
  }
}
