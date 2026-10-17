import QtQuick
import qs.config
import qs.kit

// Chat options in the Shell Manager: which free opencode model answers (the
// list comes from `opencode models`), and opencode's background server.
Column {
  id: root
  spacing: Theme.gapGroup

  Component.onCompleted: ChatService.loadModels()

  KitLabel { text: "MODEL"; value: ChatService.models.length > 0 ? ChatService.models.length + " FREE" : "" }

  KitSelect {
    width: parent.width
    label: "Model"
    hint: "A new chat uses it"
    model: ChatService.models.length > 0 ? ChatService.models
         : [{ label: ChatService.nameOf(ChatService.model), value: ChatService.model }]
    current: ChatService.model
    onPicked: value => ModuleSettings.set("chat", "model", value)
  }

  KitLine {}

  KitLabel { text: "OPENCODE" }

  KitToggleRow {
    module: "chat"; key: "server"
    label: "Background server"
    hint: "Off: starts per message"
  }
}
