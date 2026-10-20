import QtQuick
import Quickshell
import qs.components
import qs.apps.virustotal
import qs.config
import qs.kit

// The scanner in brief: a field for a hash, URL or file path, the verdict and
// its counts, the Upload row for a file VirusTotal has never seen, and a
// button to the full window.
KitFrame {
  id: root

  readonly property var vs: VirusTotalService
  readonly property var r: vs.result

  signal openWindow()

  // the clipboard's hash or URL, from VirusTotalService.readClipboard
  function prefill(t) { field.text = t; }

  KitHeader {
    icon: "scan"
    title: "VirusTotal"
    subtitle: root.vs.busy ? "LOOKING UP…" : root.vs.verdictWord(root.vs.verdict)

    KitButton {
      icon: "external"
      onClicked: {
        root.openWindow();
        ShellIpc.call("virustotal", "open");
      }
    }
  }

  KitLine {}

  KitInput {
    id: field
    width: parent.width
    placeholder: "A hash, a URL or a file path"
    onAccepted: root.vs.scan(text)
  }

  Column {
    width: parent.width
    spacing: Theme.gapSmall

    KitText {
      visible: root.vs.error !== ""
      width: parent.width
      wrapMode: Text.WordWrap
      color: Theme.red
      text: root.vs.error
    }

    KitText {
      visible: root.r?.known === true
      width: parent.width
      elide: Text.ElideMiddle
      text: root.r?.name ?? ""
    }

    KitText {
      visible: root.r?.known === true
      width: parent.width
      color: root.vs.count("malicious") > 0 ? Theme.red : Theme.foreground2
      text: root.vs.count("malicious") + " malicious · " + root.vs.count("suspicious") + " suspicious · "
          + root.vs.count("harmless") + " harmless"
    }

    KitText {
      visible: root.r && !root.r.known
      width: parent.width
      color: Theme.muted
      text: "Not seen before by VirusTotal."
    }
  }

  KitLine {}

  Item {
    width: parent.width
    height: upload.height

    KitText {
      anchors { left: parent.left; right: upload.left; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
      elide: Text.ElideRight
      color: Theme.muted
      text: root.vs.canUpload ? "Upload sends the file to VirusTotal" : "Enter scans"
    }

    KitButton {
      id: upload
      anchors { right: parent.right; verticalCenter: parent.verticalCenter }
      icon: "download"
      text: "Upload"
      visible: root.vs.canUpload
      busy: root.vs.uploading
      onClicked: root.vs.upload()
    }
  }
}
