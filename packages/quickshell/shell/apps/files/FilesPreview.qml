import QtQuick
import qs.config
import qs.kit

// The preview, framed: a picture, the first lines of a text, or the icon; then the facts.
Rectangle {
  id: root

  required property var files   // the Files window

  radius: Theme.radiusCard
  color: Theme.background1
  border.width: Theme.frameWidth
  border.color: Theme.background2
  clip: true

  Item {
    id: previewBox
    anchors { fill: parent; margins: Theme.gapWide }

    Column {
      id: facts
      width: parent.width
      anchors.bottom: parent.bottom
      spacing: Theme.gapTight

      KitText {
        width: parent.width
        text: files.previewed ? files.previewed.name : ""
        wrapMode: Text.WrapAnywhere
        maximumLineCount: 2
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
      }

      KitText {
        width: parent.width
        text: files.previewed ? files.previewed.kind.toUpperCase() + " · " + Format.humanSize(files.previewed.size) : ""
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
        font.letterSpacing: 1
      }

      KitText {
        width: parent.width
        text: files.previewed ? files.when(files.previewed.mtime) : ""
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }

    Item {
      id: shownPreview
      anchors { top: parent.top; left: parent.left; right: parent.right; bottom: facts.top; bottomMargin: Theme.gapLoose }
      clip: true

      Image {
        anchors.fill: parent
        visible: files.previewed !== null && files.previewed.kind === "image"
        source: visible ? files.fileUrl(files.previewed.path) : ""
        sourceSize: Qt.size(480, 480)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      // a video's frame or a PDF's first page: made by the backend, see Settings
      Image {
        anchors.fill: parent
        visible: files.svc.thumbPath !== "" && files.previewed !== null && (files.previewed.kind === "video" || files.previewed.kind === "pdf")
        source: files.svc.thumbPath
        sourceSize: Qt.size(480, 480)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      KitText {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        visible: files.svc.thumbError !== "" && files.svc.thumbPath === ""
        text: files.svc.thumbError
        color: Theme.muted
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSize - 2
      }

      KitIcon {
        anchors.centerIn: parent
        visible: files.previewed !== null && files.previewed.kind !== "image" && files.previewed.kind !== "text"
                 && files.svc.thumbPath === "" && files.svc.thumbError === ""
        name: files.previewed ? files.iconFor(files.previewed.kind) : "file"
        size: 48
        tint: Theme.muted
      }

      // a Markdown file is rendered (Qt reads the markup); any other text as it is
      Text {
        anchors.fill: parent
        visible: files.markdown && files.svc.previewText !== ""
        // no pictures: a Markdown picture would be fetched from wherever it points
        text: files.svc.previewText.replace(/!\[[^\]]*\]\([^)]*\)/g, "").replace(/<img[^>]*>/gi, "")
        textFormat: Text.MarkdownText
        color: Theme.foreground1
        linkColor: Theme.foreground2
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        wrapMode: Text.Wrap
        clip: true
        verticalAlignment: Text.AlignTop
      }

      Text {
        anchors.fill: parent
        visible: files.previewed !== null && files.previewed.kind === "text" && !files.markdown
        text: files.svc.previewText !== "" ? files.svc.previewText : "No preview."
        textFormat: Text.PlainText
        color: files.svc.previewText !== "" ? Theme.foreground1 : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 3
        wrapMode: Text.NoWrap
        clip: true
        verticalAlignment: Text.AlignTop
      }
    }
  }
}
