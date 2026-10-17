import QtQuick
import qs.config
import qs.kit

// Files options in the Shell Manager (Shell apps › Files, ModuleSettings
// "files"), by what they change: the view, the list's order, the search, what
// a click does, the file chooser's size, what asks first, and the actions of
// the right click's menu.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "VIEW" }

  KitRow {
    wide: true
    label: "Show as"
    hint: "Ctrl + G in the window"

    KitChoices {
      stretch: true
      model: [{ label: "List", value: "list" }, { label: "Grid", value: "grid" }, { label: "Columns", value: "columns" }]
      current: FilesService.view
      onPicked: value => FilesService.setOption("view", value)
    }
  }

  KitToggleRow { module: "files"; key: "preview"; label: "Show preview"; hint: "The selected file, at right" }

  KitRow {
    visible: FilesService.showPreview
    wide: true
    label: "Preview lines"
    hint: "Of a text file"

    KitChoices {
      stretch: true
      model: [{ label: "20", value: 20 }, { label: "40", value: 40 }, { label: "80", value: 80 }]
      current: FilesService.previewLines
      onPicked: value => FilesService.setOption("previewLines", value)
    }
  }

  KitToggleRow { module: "files"; key: "frames"; fallback: true; label: "Show frames"; hint: "Off: no lines" }

  KitToggleRow { module: "files"; key: "hints"; fallback: true; label: "Show key hints"; hint: "Off: no line under the list" }

  KitLine {}

  KitLabel { text: "LIST" }

  KitToggleRow { module: "files"; key: "hidden"; fallback: false; label: "Show hidden files"; hint: "Ctrl + H in the window" }

  KitToggleRow { module: "files"; key: "thumbnails"; fallback: true; label: "Show thumbnails"; hint: "Off: an icon" }

  KitRow {
    wide: true
    label: "Dates"
    hint: "Today shows the time only"

    KitChoices {
      stretch: true
      model: [{ label: "Short", value: "short" }, { label: "ISO", value: "iso" }]
      current: FilesService.dateFormat
      onPicked: value => FilesService.setOption("dateFormat", value)
    }
  }

  KitLine {}

  KitLabel { text: "SORT" }

  KitRow {
    wide: true
    label: "Sort by"
    hint: "Trash: the newest first"

    KitChoices {
      stretch: true
      model: [{ label: "Name", value: "name" }, { label: "Size", value: "size" }, { label: "Modified", value: "mtime" }]
      current: FilesService.sortBy
      onPicked: value => FilesService.setOption("sortBy", value)
    }
  }

  KitToggleRow { module: "files"; key: "sortDesc"; fallback: false; label: "Descending"; hint: "Click a caption to flip it" }

  KitToggleRow { module: "files"; key: "foldersFirst"; label: "Folders first" }

  KitRow {
    wide: true
    label: "Group by"
    hint: "Type: the kinds one after another"

    KitChoices {
      stretch: true
      model: [{ label: "None", value: "none" }, { label: "Type", value: "type" }]
      current: FilesService.groupBy
      onPicked: value => FilesService.setOption("groupBy", value)
    }
  }

  KitLine {}

  KitLabel { text: "SEARCH" }

  KitRow {
    wide: true
    label: "Results kept"
    hint: "Then the search stops"

    KitChoices {
      stretch: true
      model: [{ label: "100", value: 100 }, { label: "300", value: 300 }, { label: "1000", value: 1000 }]
      current: FilesService.searchLimit
      onPicked: value => FilesService.setOption("searchLimit", value)
    }
  }

  KitRow {
    wide: true
    label: "Time limit"
    hint: "Then the results so far"

    KitChoices {
      stretch: true
      model: [{ label: "3 s", value: 3 }, { label: "5 s", value: 5 }, { label: "15 s", value: 15 }]
      current: FilesService.searchSeconds
      onPicked: value => FilesService.setOption("searchSeconds", value)
    }
  }

  KitLine {}

  KitLabel { text: "BEHAVIOUR" }

  KitToggleRow { module: "files"; key: "singleClick"; fallback: false; label: "Open on one click"; hint: "Ctrl and shift still select" }

  KitRow {
    wide: true
    label: "Open at"
    hint: "Last folder, or a fixed one"

    KitChoices {
      stretch: true
      model: [{ label: "Last folder", value: "last" }, { label: "Fixed", value: "fixed" }]
      current: FilesService.startMode
      onPicked: value => FilesService.setOption("startMode", value)
    }
  }

  // the fixed folder: a path, or ~ for home; Enter keeps it
  KitInput {
    visible: FilesService.startMode === "fixed"
    text: FilesService.startPath
    placeholder: "~/Documents"
    onAccepted: {
      const typed = text.trim();
      if (typed.startsWith("/") || typed === "~" || typed.startsWith("~/")) FilesService.setOption("startPath", typed);
    }
  }

  KitLine {}

  KitLabel { text: "TERMINAL"; value: FilesService.terminal.split(" ")[0] }

  // the command that opens a folder: the path is added after it, quoted
  KitInput {
    text: FilesService.terminal
    placeholder: "kitty --directory"
    onAccepted: { if (text.trim() !== "") FilesService.setOption("terminal", text.trim()); }
  }

  KitLine {}

  KitLabel { text: "PICKER"; value: FilesService.pickerSize.toUpperCase() }

  // the file chooser the portal opens: a preset, or the sizes typed (no live preview to drag by)
  KitRow {
    wide: true
    label: "Size"
    hint: "Custom: sizes below"

    KitChoices {
      stretch: true
      model: [{ label: "Small", value: "small" }, { label: "Medium", value: "medium" },
              { label: "Large", value: "large" }, { label: "Custom", value: "custom" }]
      current: FilesService.pickerSize
      onPicked: value => FilesService.setOption("pickerSize", value)
    }
  }

  KitRow {
    visible: FilesService.pickerSize === "custom"
    wide: true
    label: "Width"
    hint: "480 to 1400 px"

    KitInput {
      width: 120
      text: FilesService.pickerWidth + ""
      onAccepted: {
        const v = parseInt(text);
        if (v >= 480 && v <= 1400) FilesService.setOption("pickerWidth", v);
        else text = FilesService.pickerWidth + "";
      }
    }
  }

  KitRow {
    visible: FilesService.pickerSize === "custom"
    wide: true
    label: "Height"
    hint: "360 to 1000 px"

    KitInput {
      width: 120
      text: FilesService.pickerHeight + ""
      onAccepted: {
        const v = parseInt(text);
        if (v >= 360 && v <= 1000) FilesService.setOption("pickerHeight", v);
        else text = FilesService.pickerHeight + "";
      }
    }
  }

  KitLine {}

  KitLabel { text: "SAFETY" }

  KitToggleRow { module: "files"; key: "confirmDelete"; label: "Ask before deleting"; hint: "Delete for good asks once" }

  KitToggleRow { module: "files"; key: "confirmTrash"; fallback: false; label: "Ask before trashing"; hint: "Delete asks once" }

  KitLine {}

  KitLabel { text: "ACTIONS"; value: FilesService.actions.length + " IN THE MENU" }

  // a command for the right click's menu: %f is replaced by the selected paths
  Repeater {
    model: FilesService.actions

    KitRow {
      required property var modelData
      required property int index
      wide: true
      label: modelData.label
      hint: modelData.command

      KitButton {
        icon: "x"
        onClicked: FilesService.removeAction(index)
      }
    }
  }

  KitInput {
    id: actionLabel
    placeholder: "label, e.g. Open in terminal"
    onAccepted: actionCommand.input.forceActiveFocus()
  }

  KitInput {
    id: actionCommand
    placeholder: "command, %f is the selection, e.g. kitty --directory %f"
    onAccepted: { FilesService.addAction(actionLabel.text, actionCommand.text); actionLabel.text = ""; actionCommand.text = ""; }
  }

  KitButton {
    text: "Add action"
    icon: "plus"
    onClicked: { FilesService.addAction(actionLabel.text, actionCommand.text); actionLabel.text = ""; actionCommand.text = ""; }
  }
}
