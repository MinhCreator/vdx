import QtQuick
import qs.config
import qs.kit

// Ollama tab of the AI popup: models on disk (size, in memory or not), unload,
// and a one-click download of the nvim coach's model.
Column {
  id: root

  spacing: 14

  KitText {
    width: parent.width
    visible: !OllamaService.running
    text: !OllamaService.installed ? "Ollama is not installed:  sudo pacman -S ollama"
                                   : "The server is stopped. Switch it on to manage models."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  Column {
    width: parent.width
    visible: OllamaService.running
    spacing: 8

    KitLabel {
      text: "MODELS (" + OllamaService.models.length + ")"
      value: OllamaService.loaded.length > 0 ? OllamaService.loaded.length + " IN MEMORY" : ""
      valueColor: Theme.green
    }

    Repeater {
      model: OllamaService.models

      Item {
        id: model

        required property var modelData

        readonly property real vram: OllamaService.vramOf(modelData.name)

        width: parent.width
        height: 30

        KitText {
          anchors { left: parent.left; right: info.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
          text: model.modelData.name
          elide: Text.ElideRight
          color: model.vram > 0 ? Theme.foreground0 : Theme.foreground2
          font.weight: model.vram > 0 ? Font.ExtraBold : Font.DemiBold
        }

        KitText {
          id: info
          anchors { right: unload.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
          text: Theme.humanSize(model.modelData.size) + (model.vram > 0 ? " · " + Theme.humanSize(model.vram) + " loaded" : "")
          color: model.vram > 0 ? Theme.green : Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }

        KitButton {
          id: unload
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          visible: model.vram > 0
          width: visible ? implicitWidth : 0
          icon: "eye-off"
          busy: OllamaService.busy === model.modelData.name
          onClicked: OllamaService.unload(model.modelData.name)
        }
      }
    }

    KitText {
      visible: OllamaService.models.length === 0
      text: "No models yet."
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }
  }

  KitLine { visible: OllamaService.running && !OllamaService.hasModel(Theme.ollamaCoachModel) }

  // The nvim habit coach needs this one.
  KitRow {
    visible: OllamaService.running && !OllamaService.hasModel(Theme.ollamaCoachModel)
    label: Theme.ollamaCoachModel
    hint: "model for the nvim coach"

    KitButton {
      icon: "download"
      text: "Pull"
      busy: OllamaService.busy === Theme.ollamaCoachModel
      onClicked: OllamaService.pull(Theme.ollamaCoachModel)
    }
  }

  KitText {
    width: parent.width
    visible: OllamaService.error !== ""
    text: OllamaService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
