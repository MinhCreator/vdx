import QtQuick
import qs.config
import qs.kit

// Appearance › CURSOR: the selected cursor's shapes in the chosen colour
// beside the list, its colour and size.
KitColumn {
  id: root

  // short names: "Bibata-Modern-Classic" reads "Bibata Classic", "phinger-cursors-dark" "phinger dark"
  function cursorLabel(name) {
    return name.replace(/-/g, " ").replace("Modern ", "").replace(" cursors", "").replace("Original Classic", "Original");
  }
  readonly property var cursorRows: CursorService.cursors.map(c => ({ key: c.name, installed: c.installed, label: cursorLabel(c.name) }))

  // the cursor in the preview and its colour; Apply makes them the system's
  property string cursorSelected: CursorService.base
  property string cursorMode: CursorService.mode
  property string cursorCustom: CursorService.mode === "custom" ? CursorService.fill : "d8a657"
  readonly property var cursorRow: CursorService.cursors.find(c => c.name === cursorSelected) ?? null
  readonly property bool cursorCustomValid: /^[0-9a-f]{6}$/.test(cursorCustom)
  readonly property bool cursorChanged: cursorSelected !== CursorService.base || cursorMode !== CursorService.mode
                                        || (cursorMode === "custom" && cursorCustom !== CursorService.fill)
  // the preview follows the selection (a theme-coloured one, the theme too)
  readonly property string cursorPreviewKey: cursorRow && cursorRow.installed
    ? [cursorSelected, cursorMode, cursorCustomValid ? cursorCustom : "", CursorService.themeColours].join(" ") : ""
  onCursorPreviewKeyChanged: if (cursorPreviewKey !== "" && (cursorMode !== "custom" || cursorCustomValid))
    CursorService.preview(cursorSelected, cursorMode, cursorCustom)

  function resetCursor() {
    cursorSelected = CursorService.base;
    cursorMode = CursorService.mode;
    cursorCustom = CursorService.mode === "custom" ? CursorService.fill : "d8a657";
  }

  spacing: Theme.gapGroup

  KitLabel {
    id: cursorGroup
    text: "CURSOR"
    value: root.cursorLabel(CursorService.base).toUpperCase() + " · " + CursorService.mode.toUpperCase() + " · " + CursorService.size
  }

  // the main shapes of the selected cursor in the chosen colour, beside the list
  Row {
    width: parent.width
    spacing: Theme.gapGroup

    Rectangle {
      radius: Theme.radiusCard
      width: parent.width - cursorList.width - 14
      height: cursorList.height
      color: Theme.background1
      border.width: Theme.frameWidth
      border.color: Theme.gray

      readonly property bool ready: root.cursorRow !== null && root.cursorRow.installed
                                    && CursorService.shapesKey === CursorService.wantedKey

      Grid {
        anchors.centerIn: parent
        visible: parent.ready
        columns: 4
        columnSpacing: 26
        rowSpacing: 22

        Repeater {
          model: CursorService.shapes

          Image {
            required property var modelData
            width: 40
            height: 40
            source: "file://" + modelData.path + "?" + CursorService.shapesKey
            sourceSize: Qt.size(modelData.width, modelData.height)
            cache: false
            smooth: true
          }
        }
      }

      KitSpinner {
        anchors.centerIn: parent
        visible: root.cursorRow !== null && root.cursorRow.installed && !parent.ready
      }

      KitText {
        anchors.centerIn: parent
        width: parent.width - 40
        visible: root.cursorRow !== null && !root.cursorRow.installed
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.muted
        text: "Not installed yet.\nApply downloads it."
      }
    }

    Column {
      id: cursorList
      width: Theme.sideWidth
      height: 240
      spacing: Theme.gapMedium

      PickList {
        width: parent.width
        height: parent.height - cursorButtons.height - parent.spacing
        model: root.cursorRows
        selected: root.cursorSelected
        current: CursorService.base
        working: CursorService.working
        onPicked: row => root.cursorSelected = row.key
      }

      Row {
        id: cursorButtons
        width: parent.width
        spacing: Theme.gapSmall

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: "x"
          text: "Cancel"
          disabled: !root.cursorChanged || CursorService.busy
          onClicked: root.resetCursor()
        }

        KitButton {
          width: (parent.width - parent.spacing) / 2
          icon: root.cursorRow && !root.cursorRow.installed ? "download" : "check"
          text: "Apply"
          busy: CursorService.busy
          disabled: !root.cursorChanged || root.cursorRow === null
                    || (root.cursorMode === "custom" && !root.cursorCustomValid)
          onClicked: CursorService.apply(root.cursorRow, CursorService.size, root.cursorMode, root.cursorCustom)
        }
      }
    }
  }

  KitRow {
    wide: true
    label: "Colour"
    hint: root.cursorMode === "theme" ? "Follows the theme's colours"
        : root.cursorMode === "custom" ? "Your colour, outlined to stand out" : "As the cursor theme draws it"

    KitChoices {
      stretch: true
      model: [
        { label: "Original", value: "original" },
        { label: "Theme",    value: "theme" },
        { label: "Custom",   value: "custom" }
      ]
      current: root.cursorMode
      onPicked: value => root.cursorMode = value
    }
  }

  ColourRow {
    visible: root.cursorMode === "custom"
    value: "#" + root.cursorCustom
    onEdited: text => root.cursorCustom = text.trim().replace(/^#/, "").toLowerCase()
    onAccepted: colour => { if (root.cursorRow) CursorService.apply(root.cursorRow, CursorService.size, "custom", colour.slice(1)); }
  }

  KitRow {
    wide: true
    label: "Size"
    hint: "Pixels at scale 1, applied at once"

    KitChoices {
      stretch: true
      model: [20, 24, 28, 32, 40].map(n => ({ label: String(n), value: n }))
      current: CursorService.size
      onPicked: value => CursorService.setSize(value)
    }
  }

  KitText {
    width: parent.width
    visible: CursorService.error !== ""
    text: CursorService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
