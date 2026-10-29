import QtQuick
import qs.apps.auth
import qs.apps.packages
import qs.config
import qs.kit

// A root action of the shell (RootService) as a view of the island, in three
// looks: confirm (each step in words with its command, Run / Cancel), password
// (polkit asks for our action), running (the package download's progress or
// "running…", Cancel). Once it runs the island folds into the live chip; a
// click on the chip brings this view back as the running look.
KitFrame {
  id: root

  inIsland: true

  readonly property bool staged: PackagesService.stage !== ""
  readonly property var flow: RootService.flow

  signal closeAsked()

  function focusInput() { password.text = ""; password.input.forceActiveFocus(); }

  function submit() {
    if (!flow || !flow.isResponseRequired) return;
    flow.submit(password.text);
    password.text = "";
  }

  onFlowChanged: if (flow) focusLater.restart()
  Connections {
    target: root.flow
    ignoreUnknownSignals: true
    function onIsResponseRequiredChanged() { if (root.flow.isResponseRequired) focusLater.restart(); }
  }
  Timer { id: focusLater; interval: 30; onTriggered: root.focusInput() }

  KitHeader {
    icon: RootService.running ? "download" : "lock"
    title: RootService.title
    subtitle: RootService.source.toUpperCase() + " · AS ROOT · " + RootService.steps.length
              + (RootService.steps.length === 1 ? " STEP" : " STEPS")
  }

  KitLine {}

  // ---- what happens ----
  Column {
    visible: !RootService.running && !RootService.asking
    width: parent.width
    spacing: Theme.gapWide

    Repeater {
      model: RootService.steps

      Column {
        required property var modelData
        required property int index

        width: parent.width
        spacing: 3

        KitText {
          width: parent.width
          text: (index + 1) + ". " + modelData.label
          font.weight: Font.ExtraBold
        }

        KitText {
          width: parent.width
          text: modelData.what
          wrapMode: Text.WordWrap
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          width: parent.width
          text: "# " + modelData.command
          elide: Text.ElideRight
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 2
        }
      }
    }
  }

  // ---- the password ----
  KitInput {
    id: password
    visible: RootService.asking
    width: parent.width
    placeholder: (root.flow?.inputPrompt ?? "Password").replace(/:\s*$/, "").toLowerCase()
    echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
    centerMasked: false
    onAccepted: root.submit()
    Keys.onEscapePressed: root.closeAsked()
  }

  KitText {
    width: parent.width
    visible: RootService.asking && text !== ""
    wrapMode: Text.WordWrap
    text: root.flow?.supplementaryMessage ?? ""
    color: root.flow?.supplementaryIsError ? Theme.red : Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- the progress ----
  Column {
    visible: RootService.running && !RootService.asking
    width: parent.width
    spacing: Theme.gapSmall

    Item {
      width: parent.width
      height: Math.max(label.implicitHeight, percent.implicitHeight)

      KitText {
        id: label
        anchors { left: parent.left; right: percent.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
        text: PackagesService.stage === "downloading" ? "Downloading " + PackagesService.stageList.length + " packages"
            : PackagesService.stage === "installing" ? "Installing " + PackagesService.stageList.length + " packages"
            : RootService.stopped ? "Stopping…" : "Running…"
      }

      KitText {
        id: percent
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: PackagesService.stage === "downloading"
        text: Math.round(PackagesService.stagePercent * 100) + "%"
        color: Theme.blue
      }
    }

    KitText {
      width: parent.width
      visible: PackagesService.stage === "downloading"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: (PackagesService.stageDone / 1048576).toFixed(0) + " / " + (PackagesService.stageBytes / 1048576).toFixed(0) + " MB"
    }

    Rectangle {
      width: parent.width
      height: 4
      radius: Theme.pill(height)
      color: Theme.background3

      Rectangle {
        width: parent.width * (PackagesService.stage === "downloading" ? PackagesService.stagePercent : root.staged ? 1 : 0)
        height: parent.height
        radius: Theme.pill(height)
        color: Theme.blue
      }
    }
  }

  // ---- foot ----
  Item {
    width: parent.width
    height: buttons.height

    KitText {
      anchors { left: parent.left; right: buttons.left; rightMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
      visible: !RootService.running && !RootService.asking
      wrapMode: Text.WordWrap
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: "first time with your password, then for 5 min just this"
    }

    Row {
      id: buttons
      anchors.right: parent.right
      spacing: Theme.gapSmall

      KitButton {
        icon: "x"
        text: "Cancel"
        disabled: RootService.stopped
        onClicked: RootService.running || RootService.asking ? RootService.stop() : RootService.cancel()
      }

      KitButton {
        visible: RootService.asking
        icon: "check"
        text: "Unlock"
        disabled: !(root.flow?.isResponseRequired ?? false)
        onClicked: root.submit()
      }

      KitButton {
        visible: !RootService.running && !RootService.asking
        icon: "lock"
        text: "Run"
        onClicked: RootService.run()
      }
    }
  }
}
