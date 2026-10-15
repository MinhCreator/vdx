import QtQuick
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

  // ---- header ----
  Column {
    id: top
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24; topMargin: 20 }
    spacing: 14

    KitHeader {
      icon: "search"
      title: "VirusTotal"
      subtitle: root.vs.busy ? (root.vs.uploading ? "UPLOADING AND ANALYSING…" : "LOOKING UP…")
              : root.vs.error !== "" ? "FAILED" : root.vs.verdictWord(root.vs.verdict)
    }

    Row {
      width: parent.width
      spacing: 12

      KitInput {
        id: field
        width: parent.width - scan.width - 12
        placeholder: "A hash, a URL or a file path"
        onAccepted: root.go()
      }

      KitButton {
        id: scan
        icon: "search"
        text: "Scan"
        busy: root.vs.busy
        onClicked: root.go()
      }
    }

    KitLine {}
  }

  // ---- body ----
  Flickable {
    id: list
    anchors { left: parent.left; right: parent.right; top: top.bottom; bottom: foot.top; leftMargin: 24; rightMargin: 24; topMargin: 14; bottomMargin: 14 }
    contentHeight: body.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    Column {
      id: body
      width: list.width
      spacing: 14

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
        hint: "Sends the file to VirusTotal, up to 32 MB"

        KitButton {
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
        spacing: 6

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
        spacing: 6

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
    }
  }

  // ---- foot ----
  Column {
    id: foot
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 24; bottomMargin: 18 }
    spacing: 12

    KitLine {}

    Item {
      width: parent.width
      height: report.height

      KitText {
        anchors { left: parent.left; right: report.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSize - 2
        color: Theme.muted
        text: root.r?.sha256 ? "SHA-256 " + root.r.sha256.slice(0, 16) + "…" : "Enter scans · Esc closes"
      }

      KitButton {
        id: report
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        icon: "external"
        text: "Report"
        disabled: !(root.r?.link)
        onClicked: root.vs.openLink()
      }
    }
  }
}
