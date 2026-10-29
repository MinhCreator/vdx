import QtQuick
import qs.config
import qs.kit

// The modal's contents, independent of its layer-shell window. The controller
// keeps errors and pending work so a failed save remains editable here.
KitFrame {
  id: root
  required property var controller
  required property string home
  readonly property bool video: controller.pending?.kind === "video"
  readonly property string suggestedPath: controller.pending?.path ?? ""
  implicitWidth: 480

  function displayPath(value) {
    return home && (value === home || value.startsWith(home + "/")) ? "~" + value.slice(home.length) : value;
  }
  function dismiss() {
    if (controller.saveBusy) return;
    if (video) path.text = displayPath(suggestedPath);
    controller.dismissSave();
  }
  Keys.onEscapePressed: dismiss()

  KitHeader {
    icon: root.video ? "video" : "camera"
    title: root.video ? "Save recording" : "Save screenshot"
    subtitle: root.video ? "esc · save to the default folder" : "esc · keep it on the clipboard only"
  }

  KitLine {}

  KitInput {
    id: path
    width: parent.width
    text: root.displayPath(root.suggestedPath)
    placeholder: "path"
    enabled: !root.controller.saveBusy
    input.Accessible.name: "Capture file path"
    onTextEdited: root.controller.editSave()
    onAccepted: root.controller.confirmSave(text)
    Component.onCompleted: { input.forceActiveFocus(); input.cursorPosition = input.text.length; }
    input.Keys.onEscapePressed: root.dismiss()
  }

  KitText {
    width: parent.width
    visible: root.controller.saveError !== ""
    text: root.controller.saveError
    color: Theme.red
    font.pixelSize: Theme.fontSize - 1
    wrapMode: Text.WordWrap
  }

  Row {
    anchors.right: parent.right
    spacing: Theme.gapSmall

    KitButton {
      icon: "x"
      text: root.video ? "Default folder" : "Skip"
      disabled: root.controller.saveBusy
      onClicked: root.dismiss()
    }

    KitButton {
      icon: "check"
      text: root.controller.replaceSave ? "Replace" : "Save"
      busy: root.controller.saveBusy
      selected: true
      onClicked: root.controller.confirmSave(path.text)
    }
  }
}
