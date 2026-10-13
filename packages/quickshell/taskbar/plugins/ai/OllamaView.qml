import QtQuick
import qs.components
import qs.config

// Ollama tab of the AI popup: models on disk (size, in memory or not), unload,
// and a one-click download of the nvim coach's model.
Column {
  id: root

  spacing: 6

  ThemeText {
    width: parent.width
    visible: !OllamaService.installed
    text: "Ollama is not installed:  sudo pacman -S ollama"
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 2
  }

  ThemeText {
    visible: OllamaService.installed && !OllamaService.running
    text: "SERVER IS STOPPED"
    color: Theme.muted
    font.letterSpacing: 1
  }

  Column {
    width: parent.width
    visible: OllamaService.running
    spacing: 6

    PopupSectionTitle {
      width: parent.width
      text: "MODELS · " + OllamaService.models.length
    }

    Repeater {
      model: OllamaService.models

      Item {
        id: model

        required property var modelData

        readonly property real vram: OllamaService.vramOf(modelData.name)

        width: parent.width
        height: Theme.rowHeight

        ThemeText {
          anchors { left: parent.left; right: info.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
          text: model.modelData.name
          elide: Text.ElideRight
          color: model.vram > 0 ? Theme.green : Theme.foreground0
        }

        ThemeText {
          id: info
          anchors { right: unload.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
          text: Theme.humanSize(model.modelData.size) + (model.vram > 0 ? " · " + Theme.humanSize(model.vram) + " in memory" : "")
          color: Theme.dim
          font.pixelSize: Theme.fontSize - 2
        }

        PopupButton {
          id: unload
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          visible: model.vram > 0
          width: visible ? implicitWidth : 0
          glyph: Theme.iconEyeOff
          tint: Theme.foreground2
          frameless: true
          hoverBackground: false
          busy: OllamaService.busy === model.modelData.name
          onClicked: OllamaService.unload(model.modelData.name)
        }
      }
    }

    ThemeText {
      visible: OllamaService.models.length === 0
      text: "No models yet"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }

    // The nvim habit coach needs this one.
    Item {
      width: parent.width
      height: pull.implicitHeight
      visible: !OllamaService.hasModel(Theme.ollamaCoachModel)

      ThemeText {
        anchors { left: parent.left; right: pull.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: Theme.ollamaCoachModel + " — for the nvim coach"
        elide: Text.ElideRight
        color: Theme.foreground2
        font.pixelSize: Theme.fontSize - 1
      }

      PopupButton {
        id: pull
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        label: "PULL"
        tint: Theme.foreground0
        busy: OllamaService.busy === Theme.ollamaCoachModel
        onClicked: OllamaService.pull(Theme.ollamaCoachModel)
      }
    }
  }

  PopupError { text: OllamaService.error }
}
