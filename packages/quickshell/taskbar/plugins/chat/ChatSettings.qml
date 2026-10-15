import QtQuick
import qs.config
import qs.kit

// Chat options in the Shell Manager: which free opencode model answers (the
// list comes from `opencode models`), and opencode's background server.
Column {
  id: root
  spacing: 14

  Component.onCompleted: ChatService.loadModels()

  KitLabel { text: "MODEL"; value: ChatService.models.length > 0 ? ChatService.models.length + " FREE" : "" }

  KitSelect {
    width: parent.width
    label: "Model"
    hint: "A new chat uses it"
    model: ChatService.models.length > 0 ? ChatService.models
         : [{ label: ChatService.nameOf(ChatService.model), value: ChatService.model }]
    current: ChatService.model
    onPicked: value => PluginSettings.set("chat", "model", value)
  }

  KitLine {}

  KitLabel { text: "OPENCODE" }

  KitToggleRow {
    plugin: "chat"; key: "server"
    label: "Background server"
    hint: "Quicker answers; off: one per message"
  }
}
