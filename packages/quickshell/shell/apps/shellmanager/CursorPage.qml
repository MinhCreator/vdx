import QtQuick
import qs.config
import qs.kit
import "../../kit/colour.js" as Colour

// Cursor: the picked cursor's shapes large, in the chosen colour; its colour and
// size; then a card per cursor theme. A pick (or a colour) is previewed and waits
// for Apply (it may download the theme); the size applies at once.
KitColumn {
  id: root

  // short names: "Bibata-Modern-Classic" reads "Bibata Classic", "phinger-cursors-dark" "phinger dark"
  function cursorLabel(name) {
    return name.replace(/-/g, " ").replace("Modern ", "").replace(" cursors", "").replace("Original Classic", "Original");
  }

  // the cursor in the preview and its colour; Apply makes them the system's
  property string cursorSelected: CursorService.base
  property string cursorMode: CursorService.mode
  property int cursorSize: CursorService.size
  property string cursorCustom: CursorService.mode === "custom" ? CursorService.fill : "d8a657"
  readonly property var cursorRow: CursorService.cursors.find(c => c.name === cursorSelected) ?? null
  readonly property bool cursorCustomValid: /^[0-9a-f]{6}$/.test(cursorCustom)
  readonly property bool cursorChanged: cursorSelected !== CursorService.base || cursorMode !== CursorService.mode || cursorSize !== CursorService.size
                                        || (cursorMode === "custom" && cursorCustom !== CursorService.fill)
  // the preview follows the selection (a theme-coloured one, the theme too)
  readonly property string cursorPreviewKey: cursorRow && cursorRow.installed
    ? [cursorSelected, cursorMode, cursorCustomValid ? cursorCustom : "", CursorService.themeColours].join(" ") : ""
  onCursorPreviewKeyChanged: if (cursorPreviewKey !== "" && (cursorMode !== "custom" || cursorCustomValid))
    CursorService.preview(cursorSelected, cursorMode, cursorCustom)

  function resetCursor() {
    cursorSelected = CursorService.base;
    cursorMode = CursorService.mode;
    cursorSize = CursorService.size;
    cursorCustom = CursorService.mode === "custom" ? CursorService.fill : "d8a657";
  }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "cursor"
  readonly property string title: "Cursor"
  readonly property string description: "The pointer's theme, colour and size."
  readonly property var jumps: [
    { key: "preview", label: "Preview", y: previewLabel.y },
    { key: "style", label: "Style", y: styleLabel.y },
    { key: "themes", label: "Cursor themes", y: themesLabel.y }
  ]
  property string query: ""
  property string scope: "all"
  readonly property var shown: CursorService.cursors.filter(c => (scope !== "installed" || c.installed) && cursorLabel(c.name).toLowerCase().includes(query.trim().toLowerCase()))

  readonly property int columns: width >= 720 ? 3 : width >= 440 ? 2 : 1
  readonly property int gap: Theme.gapGroup

  // ---- the picked cursor: its shapes, Apply when changed ----
  KitLabel { id: previewLabel; text: "PREVIEW"; value: root.cursorChanged ? "NOT APPLIED" : "IN USE" }

  Rectangle {
    id: well

    readonly property bool ready: root.cursorRow !== null && root.cursorRow.installed
                                  && CursorService.shapesKey === CursorService.wantedKey

    width: parent.width
    height: Math.max(80, cursorShapes.implicitHeight + 2 * Theme.gapWide)
    radius: Theme.radiusControl
    color: Theme.background0

    Flow {
      id: cursorShapes
      width: Math.min(parent.width - 24, CursorService.shapes.length * (root.cursorSize * 1.5 + Theme.gapWide))
      anchors.centerIn: parent
      visible: well.ready
      spacing: Theme.gapWide

      Repeater {
        model: CursorService.shapes

        Image {
          required property var modelData
          width: root.cursorSize * 1.5
          height: width
          source: "file://" + modelData.path + "?" + CursorService.shapesKey
          sourceSize: Qt.size(modelData.width, modelData.height)
          cache: false
          smooth: true
        }
      }
    }

    KitSpinner {
      anchors.centerIn: parent
      visible: root.cursorRow !== null && root.cursorRow.installed && !well.ready
    }

    KitText {
      anchors.centerIn: parent
      visible: root.cursorRow !== null && !root.cursorRow.installed
      color: Theme.muted
      text: "Not installed yet: Apply downloads it"
    }
  }

  KitRow {
    visible: root.cursorChanged
    label: "Use " + (root.cursorRow ? root.cursorLabel(root.cursorRow.name) : "")
    hint: root.cursorRow && !root.cursorRow.installed ? "Downloads it first" : "For every app"

    KitButton {
      text: "Cancel"
      disabled: CursorService.busy
      onClicked: root.resetCursor()
    }

    KitButton {
      icon: root.cursorRow && !root.cursorRow.installed ? "download" : "check"
      iconTint: root.cursorRow && !root.cursorRow.installed ? Theme.foreground0 : Theme.green
      text: "Apply"
      busy: CursorService.busy
      disabled: root.cursorRow === null || (root.cursorMode === "custom" && !root.cursorCustomValid)
      onClicked: CursorService.apply(root.cursorRow, root.cursorSize, root.cursorMode, root.cursorCustom)
    }
  }

  // ---- its look ----
  KitLabel { id: styleLabel; text: "STYLE" }

  KitRow {
    wide: true
    label: "Colour"
    hint: root.cursorMode === "theme" ? "Follows the theme's colours"
        : root.cursorMode === "custom" ? "Choose a colour from the palette" : "As the cursor theme draws it"

    KitSegments {
      model: [
        { label: "Original", value: "original" },
        { label: "Theme",    value: "theme" },
        { label: "Colour",   value: "custom" }
      ]
      current: root.cursorMode
      onPicked: value => root.cursorMode = value
    }
  }

  KitColourPicker {
    visible: root.cursorMode === "custom"
    width: parent.width
    palette: ["red", "orange", "yellow", "green", "aqua", "blue", "purple"]
    picked: palette.find(name => Colour.hexOfColour(Theme.accentColour(name)).slice(1) === root.cursorCustom) ?? ""
    colours: name => [Theme.accentColour(name), Theme.accentColour(name)]
    onChosen: name => root.cursorCustom = Colour.hexOfColour(Theme.accentColour(name)).slice(1)
  }

  KitRow {
    wide: true
    label: "Size"
    hint: "Pixels at scale 1; Apply to use"

    KitSegments {
      model: [20, 24, 28, 32, 40].map(n => ({ label: String(n), value: n }))
      current: root.cursorSize
      onPicked: value => root.cursorSize = value
    }
  }

  // ---- the cursor themes ----
  KitLabel {
    id: themesLabel
    text: "CURSOR THEMES"
    value: CursorService.cursors.filter(c => c.installed).length + " OF " + CursorService.cursors.length + " INSTALLED"
  }

  Row {
    property bool kitUnboxed: true
    width: parent.width
    spacing: Theme.gapMedium
    KitInput { width: Math.max(100, parent.width - cursorFilter.width - parent.spacing); icon: "search"; placeholder: "Search cursor themes"; onTextEdited: root.query = text }
    KitButton {
      id: cursorFilter
      width: 156
      text: root.scope === "installed" ? "Installed" : "All cursors"
      icon: root.scope === "installed" ? "check" : "list"
      selected: root.scope === "installed"
      Accessible.name: text
      Accessible.description: root.scope === "installed" ? "Click to show all" : "Click to show installed only"
      onClicked: root.scope = root.scope === "all" ? "installed" : "all"
    }
  }

  Column {
    property bool kitUnboxed: true          // KitGrouper: the cards stand on the page

    width: parent.width
    spacing: Theme.gapHair

    Repeater {
      model: root.shown

      Rectangle {
        id: card

        required property var modelData
        readonly property bool inUse: modelData.name === CursorService.base
        readonly property bool picked: modelData.name === root.cursorSelected
        readonly property bool working: CursorService.working === modelData.name

        width: parent.width
        height: 52
        radius: Theme.radiusCard
        color: picked ? Theme.pickFill : area.containsMouse ? Theme.controlHover : Theme.groupFill
        border.width: activeFocus ? Theme.focusWidth : Theme.frameWidth
        border.color: activeFocus ? Theme.focusRing : Theme.controlLine
        activeFocusOnTab: true
        Accessible.role: Accessible.RadioButton
        Accessible.name: root.cursorLabel(modelData.name)
        Accessible.checkable: true
        Accessible.checked: picked
        function choose() { root.cursorSelected = modelData.name; }
        Accessible.onPressAction: choose()
        Keys.onSpacePressed: choose()
        Keys.onReturnPressed: choose()
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

        Column {
          anchors { left: parent.left; leftMargin: Theme.gapGroup; right: mark.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
          spacing: Theme.gapTight

          KitText {
            width: parent.width
            elide: Text.ElideRight
            text: root.cursorLabel(card.modelData.name)
            font.weight: card.picked ? Theme.pickWeight : Font.Normal
          }

          KitText {
            text: card.working ? "Installing…" : card.inUse ? "In use" : card.modelData.installed ? "Installed" : "Not installed"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 1
          }
        }

        Item {
          id: mark
          anchors { right: parent.right; rightMargin: Theme.gapWide; verticalCenter: parent.verticalCenter }
          width: 16
          height: 16

          KitSpinner { anchors.centerIn: parent; visible: card.working }
          KitIcon {
            anchors.centerIn: parent
            visible: !card.working && (card.inUse || !card.modelData.installed)
            name: card.inUse ? "check" : "download"
            tint: card.inUse ? Theme.green : Theme.foreground2
            size: Theme.iconSmall
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: card.choose()
        }
      }
    }
  }

  KitEmptyState {
    visible: root.shown.length === 0
    icon: "cursor"
    title: "No matching cursor themes"
    hint: "Try a shorter search"
  }

  KitText {
    width: parent.width
    visible: CursorService.error !== ""
    text: CursorService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  KitGrouper {}
}
