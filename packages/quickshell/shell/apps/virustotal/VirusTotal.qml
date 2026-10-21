import QtQuick
import QtQuick.Dialogs
import qs.config
import qs.kit

// The VirusTotal window's content: a field for a hash, a URL or a file path,
// the counts of the verdict, the engines that flagged it, and the report on
// the web. A file VirusTotal has never seen goes up only on the Upload row.
Rectangle {
  id: root

  color: Theme.background0

  readonly property var vs: VirusTotalService
  readonly property var r: vs.result

  function go() { vs.scan(field.text); }

  // a file of this machine: its path goes in the field and it is looked up
  // (only its hash is read; Upload sends the file, and only then)
  FileDialog {
    id: picker
    title: "Choose a file to check"
    fileMode: FileDialog.OpenFile
    onAccepted: {
      field.text = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
      root.go();
    }
  }

  // ---- header ----
  Column {
    id: head
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.windowPadding; topMargin: Theme.windowPadding - Theme.headerInset }
    spacing: Theme.gapGroup

    KitHeader {
      icon: "scan"
      title: "VirusTotal"
      subtitle: root.vs.busy ? (root.vs.uploading ? "UPLOADING AND ANALYSING…" : "LOOKING UP…")
              : root.vs.error !== "" ? "FAILED" : root.vs.verdictWord(root.vs.verdict)
    }

    Row {
      width: parent.width
      spacing: Theme.gapWide

      KitInput {
        id: field
        width: parent.width - scan.width - pick.width - 24
        placeholder: "A hash, a URL or a file path"
        onAccepted: root.go()
      }

      KitButton {
        id: pick
        icon: "folder"
        text: "File"
        disabled: root.vs.busy
        onClicked: picker.open()
      }

      KitButton {
        id: scan
        text: "Scan"
        busy: root.vs.busy && !root.vs.uploading
        disabled: root.vs.busy
        onClicked: root.go()
      }
    }

    KitLine {}
  }

  // ---- body ----
  Flickable {
    id: list
    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; leftMargin: Theme.windowPadding; rightMargin: Theme.windowPadding; topMargin: 14; bottomMargin: 14 }
    contentHeight: body.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: body
      width: list.width
      spacing: Theme.gapGroup

      KitText {
        visible: root.vs.error !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.red
        text: root.vs.error
      }

      KitText {
        visible: !root.r && root.vs.error === ""
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: "A SHA-256 hash, a link, or a file on this machine. The file is read for its hash only; its contents go up only when you press Upload."
      }

      KitText {
        visible: root.r && !root.r.known
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: root.vs.canUpload ? "VirusTotal has not seen this file." : "VirusTotal has not seen this hash."
      }

      KitRow {
        visible: root.vs.canUpload
        label: "Upload"
        hint: "Uploads the file, up to 32 MB"

        KitButton {
          width: Theme.buttonWidth
          anchors.verticalCenter: parent.verticalCenter
          icon: "download"
          text: "Upload"
          busy: root.vs.uploading
          onClicked: root.vs.upload()
        }
      }

      // ---- known: the counts ----
      KitText {
        visible: root.r?.known === true
        width: parent.width
        elide: Text.ElideMiddle
        font.weight: Font.ExtraBold
        text: root.r?.name ?? ""
      }

      Column {
        visible: root.r?.known === true
        width: parent.width
        spacing: Theme.gapSmall

        KitLabel { text: "VERDICT"; value: root.vs.verdictWord(root.vs.verdict) }

        Repeater {
          model: [
            { label: "Malicious", key: "malicious", tint: Theme.red },
            { label: "Suspicious", key: "suspicious", tint: Theme.yellow },
            { label: "Harmless", key: "harmless", tint: Theme.foreground2 },
            { label: "Undetected", key: "undetected", tint: Theme.foreground2 }
          ]

          KitRow {
            required property var modelData

            label: modelData.label

            KitText {
              anchors.verticalCenter: parent.verticalCenter
              width: 80
              horizontalAlignment: Text.AlignRight
              text: root.vs.count(modelData.key)
              color: root.vs.count(modelData.key) > 0 ? modelData.tint : Theme.muted
            }
          }
        }
      }

      // ---- known: the engines that flagged it ----
      Column {
        visible: root.r?.known === true && root.r.detections.length > 0
        width: parent.width
        spacing: Theme.gapSmall

        KitLabel { text: "FLAGGED BY"; value: (root.r?.detections?.length ?? 0) + " ENGINES" }

        Repeater {
          model: root.r?.detections ?? []

          KitRow {
            required property var modelData

            label: modelData.engine
            hint: modelData.result
            labelColor: modelData.category === "malicious" ? Theme.red : Theme.yellow

            KitText {
              anchors.verticalCenter: parent.verticalCenter
              width: 90
              horizontalAlignment: Text.AlignRight
              text: modelData.category
              color: Theme.muted
            }
          }
        }
      }

      // ---- recent: the last lookups, by the history option ----
      Column {
        visible: !root.r && root.vs.history.length > 0
        width: parent.width
        spacing: Theme.gapSmall

        KitLabel { text: "RECENT"; value: root.vs.history.length + "" }

        Repeater {
          model: root.vs.history

          KitRow {
            required property var modelData

            label: modelData.target
            hint: root.vs.verdictWord(modelData.verdict)

            KitButton {
              width: Theme.buttonWidth
              anchors.verticalCenter: parent.verticalCenter
              text: "Scan"
              onClicked: { field.text = modelData.target; root.go(); }
            }
          }
        }
      }
    }
  }

  // ---- foot ----
  Column {
    id: foot
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.windowPadding; bottomMargin: Theme.windowPadding }
    spacing: Theme.gapWide

    KitLine {}

    Item {
      width: parent.width
      height: report.height

      KitText {
        anchors { left: parent.left; right: report.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize - 2
        color: Theme.muted
        text: root.r?.sha256 ? "SHA-256 " + root.r.sha256.slice(0, 16) + "…" : "enter scans · esc close"
      }

      KitButton {
        id: report
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        icon: root.vs.reportAction === "copy" ? "clipboard" : "external"
        text: root.vs.reportAction === "copy" ? "Copy link" : "Report"
        disabled: !(root.r?.link)
        onClicked: root.vs.openLink()
      }
    }
  }
}
