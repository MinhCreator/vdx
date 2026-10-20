import QtQuick
import Quickshell
import qs.config
import qs.kit

// The file manager: places, bookmarks and devices on the left; the folder (or
// the search result, or the trash) as a list or a grid in the middle; a preview
// of the selection on the right. A path field and a search field above. While
// a portal asks for files (FilesService.picker) the same window picks them: a
// file name field for save, Cancel and the accept button below.
// Keys: arrows move (grid: all four), shift extends, enter opens (picks), backspace
// goes up, alt+arrows go back and forward, ctrl+c/x/v copy, cut, paste, ctrl+a all,
// delete trashes, shift+delete removes for good, F2 renames, ctrl+n a new folder,
// ctrl+d bookmarks the folder, ctrl+h hidden files, ctrl+g the view, ctrl+l the
// path, ctrl+f the search. A right click opens FilesMenu; files dropped on the
// list are copied in.
Item {
  id: root

  signal closeRequested()

  readonly property int padding: Theme.windowPadding
  // the panes and columns: dragged by their strips, kept in the options
  property int sideW: FilesService.opt("sideWidth", 190)
  property int previewW: FilesService.opt("previewWidth", 240)
  property int sizeWidth: FilesService.opt("sizeWidth", 84)
  property int dateWidth: FilesService.opt("dateWidth", 124)
  // the columns from the right edge: the date column, then a gap, then the size column. Size and date
  // are right-aligned in their columns (captions too); a separator sits in the middle of each gap
  function sepDateX(w) { return w - Theme.gapLoose - dateWidth - Theme.gapMedium / 2; }
  function sepSizeX(w) { return w - Theme.gapLoose - dateWidth - Theme.gapMedium - sizeWidth - Theme.gapMedium / 2; }
  readonly property int cellWidth: 112
  readonly property int cellHeight: 112
  readonly property bool grid: FilesService.shownView === "grid"
  readonly property bool columnsView: FilesService.shownView === "columns"
  readonly property bool selectedDir: FilesService.selected.length === 1 && FilesService.selected[0].kind === "dir"
  readonly property var picker: FilesService.picker

  // what is being typed in the footer or over a row: a folder or a file to
  // create, a path to rename; a delete or an empty waiting for its second press
  property string creating: ""           // "" | folder | file
  property string renaming: ""           // a path
  property bool sure: false
  property bool emptySure: false
  property bool helpOpen: false          // F1: the keys
  property bool trashSure: false         // a move to the trash waiting for its second press
  property int parentW: FilesService.parentWidth    // the Columns view's side columns, dragged
  property int childW: FilesService.childWidth
  readonly property bool markdown: previewed !== null && previewed.name.toLowerCase().endsWith(".md")

  readonly property var previewed: FilesService.selected.length === 1 ? FilesService.selected[0] : null
  // folders have no preview: only a file's
  readonly property bool previewing: FilesService.showPreview && previewed !== null && previewed.kind !== "dir"

  focus: true
  Keys.onPressed: event => handleKey(event)

  Connections {
    target: FilesService
    // a new folder starts at its top, not where the last one was scrolled to
    function onPathChanged() {
      pathField.text = FilesService.atComputer ? "" : FilesService.path; root.sure = false; root.emptySure = false;
      listFrame.listView.positionViewAtBeginning();
      listFrame.gridView.positionViewAtBeginning();
    }
    function onSelectionChanged() { root.sure = false; root.trashSure = false; }
    function onPickerChanged() { saveField.text = FilesService.picker ? FilesService.picker.name : ""; }
    function onQueryChanged() { if (searchField.text !== FilesService.query) searchField.text = FilesService.query; }
    // the keys move the selection: the view follows it
    function onAnchorChanged() {
      const i = FilesService.shown.findIndex(e => e.path === FilesService.anchor);
      if (i < 0) return;
      if (root.grid) listFrame.gridView.positionViewAtIndex(i, GridView.Contain);
      else listFrame.listView.positionViewAtIndex(i, ListView.Contain);
    }
  }

  Component.onCompleted: pathField.text = FilesService.atComputer ? "" : FilesService.path

  function handleKey(event) {
    const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
    const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
    const alt = (event.modifiers & Qt.AltModifier) !== 0;
    if (event.key === Qt.Key_Escape) {
      if (menu.visible) menu.close();
      else if (helpOpen) helpOpen = false;
      else if (FilesService.job !== null) FilesService.cancelJob();
      else if (FilesService.panel !== null) FilesService.closeInfo();
      else if (picker) FilesService.finishPick([], 1);
      else if (FilesService.dupes) FilesService.leaveDupes();
      else if (FilesService.everywhere) FilesService.toggleEverywhere();
      else if (FilesService.query !== "") FilesService.setQuery("");
      else if (FilesService.selection.length > 0) FilesService.selection = [];
      else root.closeRequested();
      return;
    }
    if (ctrl) {
      switch (event.key) {
        case Qt.Key_A: FilesService.selectAll(); return;
        case Qt.Key_C: FilesService.copySelection(); return;
        case Qt.Key_X: if (!FilesService.inTrash && !picker) FilesService.cutSelection(); return;
        case Qt.Key_V: if (picker) return; if (FilesService.canPaste) FilesService.paste(); else FilesService.pasteFromSystem(); return;
        case Qt.Key_T: FilesService.openTerminal(root.folderForTerminal()); return;
        case Qt.Key_R: if (FilesService.inTrash) FilesService.restoreSelection(); return;
        case Qt.Key_N: if (!FilesService.inTrash && !FilesService.atComputer && !picker) startCreate("folder"); return;
        case Qt.Key_D: if (!FilesService.inTrash && !FilesService.atComputer) FilesService.pin(FilesService.path); return;
        case Qt.Key_H: FilesService.setOption("hidden", !FilesService.hidden); return;
        case Qt.Key_G: FilesService.cycleView(); return;
        case Qt.Key_Z: if (picker) return; if (shift) FilesService.redo(); else FilesService.undo(); return;
        case Qt.Key_Y: if (!picker) FilesService.redo(); return;
        case Qt.Key_K: FilesService.toggleEverywhere(); searchField.input.forceActiveFocus(); return;
        case Qt.Key_L: pathField.input.forceActiveFocus(); return;
        case Qt.Key_F: searchField.input.forceActiveFocus(); return;
      }
      return;
    }
    if (alt && event.key === Qt.Key_Left) { FilesService.back(); return; }
    if (alt && event.key === Qt.Key_Right) { FilesService.forward(); return; }
    const cols = root.grid ? FilesService.columns : 1;
    switch (event.key) {
      case Qt.Key_Up: FilesService.step(-cols, shift); return;
      case Qt.Key_Down: FilesService.step(cols, shift); return;
      case Qt.Key_Left: if (root.grid) FilesService.step(-1, shift); return;
      case Qt.Key_Right: if (root.grid) FilesService.step(1, shift); return;
      case Qt.Key_Return:
      case Qt.Key_Enter:
        if (picker) accept();
        else if (FilesService.selected.length === 1) open(FilesService.selected[0]);
        return;
      case Qt.Key_Backspace: FilesService.up(); return;
      case Qt.Key_F2:
        if (FilesService.inTrash || picker) return;
        if (FilesService.selected.length === 1) renaming = FilesService.selected[0].path;
        else if (FilesService.selected.length > 1) startCreate("batch");
        return;
      case Qt.Key_F5: FilesService.refresh(); return;
      case Qt.Key_F1: helpOpen = !helpOpen; return;
      case Qt.Key_Space: FilesService.setOption("preview", !FilesService.showPreview); return;
      case Qt.Key_Delete: remove(shift); return;
    }
  }

  // a folder opens inside the window, a file with its default program; in a picker a file is picked
  function open(entry) {
    if (picker && entry.kind !== "dir") {
      FilesService.select(entry.path, "single");
      accept();
    } else if (entry.kind === "dir" && !FilesService.inTrash) {
      FilesService.go(entry.path);
    } else {
      FilesService.openExternal(entry.path);
    }
  }

  // a click: ctrl toggles, shift takes the range; in a save picker a file's name goes to the field
  function click(entry, mouse) {
    root.forceActiveFocus();
    // Settings › Behaviour: one click opens, unless a modifier selects
    if (FilesService.singleClick && !(mouse.modifiers & (Qt.ShiftModifier | Qt.ControlModifier))) {
      FilesService.select(entry.path, "single");
      open(entry);
      return;
    }
    if (mouse.modifiers & Qt.ShiftModifier) FilesService.select(entry.path, "range");
    else if (mouse.modifiers & Qt.ControlModifier) FilesService.select(entry.path, "toggle");
    else FilesService.select(entry.path, "single");
    if (picker && picker.mode === "save" && entry.kind !== "dir") saveField.text = entry.name;
  }

  function contextMenu(entry, at) {
    if (!FilesService.selection.includes(entry.path)) FilesService.select(entry.path, "single");
    menu.open(at.x, at.y, menuFor(entry));
  }

  // to the trash (asked once when Settings › Safety says so); a permanent delete (shift, or anything in the trash) asks once when confirm is on
  function remove(permanent) {
    if (FilesService.selection.length === 0 || picker) return;
    if (FilesService.inTrash || permanent) {
      if (FilesService.confirmDelete && !sure) { sure = true; return; }
      sure = false;
      FilesService.deleteSelection();
    } else {
      if (FilesService.confirmTrash && !trashSure) { trashSure = true; return; }
      trashSure = false;
      FilesService.trashSelection();
    }
  }

  // ctrl + t: the folder selected, or the one shown
  function folderForTerminal() {
    const one = FilesService.selected.length === 1 && FilesService.selected[0].kind === "dir";
    return one ? FilesService.selected[0].path : FilesService.path;
  }

  function emptyTrash() {
    if (FilesService.confirmDelete && !emptySure) { emptySure = true; return; }
    emptySure = false;
    FilesService.emptyTrash();
  }

  function startCreate(kind) {
    creating = kind;
    creatingField.text = "";
    creatingField.input.forceActiveFocus();
  }

  function finishCreate() {
    const name = creatingField.text.trim();
    if (name !== "") {
      if (creating === "folder") FilesService.createFolder(name);
      else if (creating === "batch") FilesService.batchRename(name);
      else FilesService.createFile(name);
    }
    creating = "";
    root.forceActiveFocus();
  }

  function finishRename(entry, name) {
    renaming = "";
    if (name.trim() !== "" && name.trim() !== entry.name) FilesService.rename(entry.path, name);
    root.forceActiveFocus();
  }

  // the picker's accept: the selected files (or the folder, for a folder picker, or the save name)
  function accept() {
    if (!picker) return;
    if (picker.mode === "save") {
      const name = saveField.text.trim();
      if (!FilesService.validName(name)) return;
      if (FilesService.entries.some(e => e.name === name)) {
        FilesService.error = "\"" + name + "\" is here already";
        return;
      }
      FilesService.finishPick([FilesService.path + "/" + name], 0);
      return;
    }
    const picked = FilesService.selected
      .filter(e => picker.directory ? e.kind === "dir" : e.kind !== "dir")
      .map(e => e.path);
    if (picked.length === 0) {
      if (picker.directory) FilesService.finishPick([FilesService.path], 0);
      return;
    }
    FilesService.finishPick(picker.multiple ? picked : picked.slice(0, 1), 0);
  }

  // a drop from another app: the files are copied into the folder shown (not ones already here)
  function dropped(urls) {
    const paths = urls.map(u => FilesService.pathFromUri(u.toString()))
                      .filter(p => p !== "" && p.replace(/\/[^/]*$/, "") !== FilesService.path);
    if (paths.length > 0 && !FilesService.inTrash && !picker)
      FilesService.act({ done: "pasted" }, ["paste", "copy", FilesService.path].concat(paths));
  }

  function when(time) {
    const d = new Date(time * 1000);
    if (FilesService.dateFormat === "iso") return Qt.formatDateTime(d, "yyyy-MM-dd HH:mm");
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM.yy HH:mm");
  }

  function iconFor(kind) {
    return { dir: "folder", image: "image", video: "video", audio: "music", text: "file", archive: "package" }[kind] ?? "file";
  }

  function placeIcon(name) {
    return { Home: "folder", Desktop: "monitor", Documents: "file", Downloads: "download", Music: "music",
             Pictures: "image", Videos: "video", Root: "server", Trash: "trash" }[name] ?? "folder";
  }

  // a path as a URL the image loader reads
  function fileUrl(p) { return FilesService.fileUri(p); }

  // the menu of a right click: what an entry can do now (a dimmed row can't)
  function menuFor(entry) {
    const one = FilesService.selection.length === 1;
    if (FilesService.inTrash) return [
      { label: "Open", run: () => root.open(entry) },
      { label: "Restore", hint: "ctrl + r", run: () => FilesService.restoreSelection() },
      { label: "Delete for good", hint: "del", run: () => root.remove(true) },
    ];
    return [
      { label: "Open", run: () => root.open(entry) },
      { label: "Rename", hint: "F2", disabled: !one || picker !== null, run: () => root.renaming = entry.path },
      { label: "Copy", hint: "ctrl + c", run: () => FilesService.copySelection() },
      { label: "Cut", hint: "ctrl + x", disabled: picker !== null, run: () => FilesService.cutSelection() },
      { label: "Paste", hint: "ctrl + v", disabled: !FilesService.canPaste || picker !== null, run: () => FilesService.paste() },
      { label: "Bookmark", hint: "ctrl + d", disabled: entry.kind !== "dir", run: () => FilesService.bookmark(entry.path) },
      { label: "Properties", run: () => FilesService.inspect(entry.path) },
      { label: "Terminal here", disabled: entry.kind !== "dir", run: () => FilesService.openTerminal(entry.path) },
      { label: "Find duplicates here", disabled: entry.kind !== "dir", run: () => FilesService.findDuplicates(entry.path) },
      { label: "Pin to sidebar", disabled: entry.kind !== "dir" || FilesService.isPinned(entry.path), run: () => FilesService.pin(entry.path) },
      { label: "Copy path", run: () => Quickshell.execDetached(["wl-copy", entry.path]) },
      { label: "Move to trash", hint: "del", disabled: picker !== null, run: () => root.remove(false) },
      { label: "Delete for good", hint: "shift + del", disabled: picker !== null, run: () => root.remove(true) },
    ].concat(picker !== null ? [] : FilesService.actions.map(a => ({
      label: a.label, run: () => FilesService.runAction(a, FilesService.selection),
    })));
  }

  // ---- header ----
  KitHeader {
    id: header
    anchors { top: parent.top; left: parent.left; right: parent.right
              topMargin: root.padding - Theme.headerInset; leftMargin: root.padding; rightMargin: root.padding }
    icon: root.picker ? "folder" : FilesService.inTrash ? "trash" : "folder"
    title: root.picker ? root.picker.title : FilesService.title
    subtitle: FilesService.dupes ? "DUPLICATES · " + FilesService.rows.length + " FILES IN " + FilesService.dupGroups + " GROUPS"
            : root.picker ? (root.picker.mode === "save" ? "SAVE" : root.picker.directory ? "CHOOSE A FOLDER" : "CHOOSE")
                            + (FilesService.selection.length > 0 ? " · " + FilesService.selection.length + " SELECTED" : "")
            : FilesService.atComputer ? FilesService.volumes.length + " STORAGE"
            : FilesService.inTrash ? "TRASH · " + FilesService.entries.length + " ITEMS"
            : FilesService.searching ? "SEARCH · " + FilesService.shown.length + " FOUND"
            : FilesService.shown.length + " ITEMS" + (FilesService.selection.length > 0 ? " · " + FilesService.selection.length + " SELECTED" : "")

    KitButton {
      icon: "arrow-left"
      disabled: !FilesService.canBack
      onClicked: FilesService.back()
    }
    KitButton {
      icon: "arrow-right"
      disabled: !FilesService.canForward
      onClicked: FilesService.forward()
    }
    KitButton {
      icon: "arrow-up"
      disabled: !FilesService.canUp
      onClicked: FilesService.up()
    }
    KitButton {
      icon: root.grid ? "grid" : root.columnsView ? "columns" : "list"
      onClicked: FilesService.cycleView()
    }
    KitButton {
      icon: "sliders"
      text: FilesService.sortLabel + (FilesService.atComputer ? " ↑" : FilesService.sortDesc ? " ↓" : " ↑")
      visible: !root.picker
      onClicked: FilesService.sortNext()
    }
    KitButton {
      icon: "plus"
      text: "New"
      visible: !FilesService.inTrash && !FilesService.atComputer && !root.picker
      onClicked: root.startCreate("folder")
    }
    KitButton {
      icon: "trash"
      text: root.emptySure ? "Sure?" : "Empty"
      visible: FilesService.inTrash
      disabled: FilesService.entries.length === 0
      onClicked: root.emptyTrash()
    }
  }

  // ---- the path and the search ----
  Row {
    id: fields
    anchors { top: header.bottom; left: parent.left; right: parent.right
              topMargin: Theme.gapLoose; leftMargin: root.padding; rightMargin: root.padding }
    spacing: Theme.gapMedium

    KitInput {
      id: pathField
      width: parent.width - searchField.width - parent.spacing
      placeholder: "path"
      passKeys: [Qt.Key_Escape]
      onAccepted: {
        const typed = text.trim().replace(/^~(?=\/|$)/, FilesService.home);
        if (typed.startsWith("/")) FilesService.go(typed);
        root.forceActiveFocus();
      }
      onKeyPassed: root.forceActiveFocus()
    }

    KitInput {
      id: searchField
      width: 220
      placeholder: FilesService.everywhere ? "search all of Home" : "search here and below"
      passKeys: [Qt.Key_Escape]
      text: FilesService.query
      onTextEdited: FilesService.setQuery(text)
      onKeyPassed: { if (FilesService.everywhere) FilesService.toggleEverywhere(); else FilesService.setQuery(""); root.forceActiveFocus(); }
      onAccepted: root.forceActiveFocus()
    }
  }

  // ---- body: the sidebar, the list or grid, the preview: framed panes, dragged apart by the strips between ----
  Item {
    id: body
    anchors { top: fields.bottom; bottom: footer.top; left: parent.left; right: parent.right
              topMargin: Theme.gapGroup; bottomMargin: Theme.gapTight; leftMargin: root.padding; rightMargin: root.padding }

    FilesSidebar {
      id: sideFrame
      files: root
      visible: root.picker === null
      x: 0
      y: 0
      width: root.sideW
      height: body.height
    }
    // the strip between the sidebar and the list: drag it to resize the sidebar
    FilesSplit {
      id: sideSplit
      visible: root.picker === null
      x: sideFrame.width
      y: 0
      height: body.height
      reference: body
      onDragged: x => root.sideW = Math.max(140, Math.min(360, x - stripCenter))
      onFinished: FilesService.setOption("sideWidth", root.sideW)
      readonly property real stripCenter: width / 2
    }

    // the list or the grid, framed
    FilesList {
      id: listFrame
      files: root
      visible: !FilesService.atComputer
      x: root.picker ? 0 : root.sideW + sideSplit.width
      y: 0
      width: body.width - x - (root.previewing ? previewSplit.width + root.previewW : 0)
      height: body.height
    }

    // This computer: the storage, in the list's place
    FilesComputer {
      visible: FilesService.atComputer
      files: root
      x: listFrame.x
      y: 0
      width: body.width - x
      height: body.height
    }

    // the strip between the list and the preview: drag it to resize the preview
    FilesSplit {
      id: previewSplit
      visible: root.previewing
      x: listFrame.x + listFrame.width
      y: 0
      height: body.height
      reference: body
      onDragged: x => root.previewW = Math.max(180, Math.min(480, body.width - x - width / 2))
      onFinished: FilesService.setOption("previewWidth", root.previewW)
    }

    FilesPreview {
      id: previewFrame
      files: root
      visible: root.previewing
      x: body.width - root.previewW
      y: 0
      width: root.previewW
      height: body.height
    }
  }

  // ---- footer: the picker's buttons, a name being typed, the error, or the keys ----
  Item {
    id: footer
    anchors { bottom: parent.bottom; left: parent.left; right: parent.right
              bottomMargin: root.padding; leftMargin: root.padding; rightMargin: root.padding }
    height: 32

    Row {
      visible: root.picker !== null
      anchors.fill: parent
      spacing: Theme.gapMedium

      KitInput {
        id: saveField
        width: parent.width - cancelButton.width - acceptButton.width - 2 * parent.spacing
        visible: root.picker !== null && root.picker.mode === "save"
        placeholder: "file name"
        text: root.picker ? root.picker.name : ""
        passKeys: [Qt.Key_Escape]
        onAccepted: root.accept()
        onKeyPassed: FilesService.finishPick([], 1)
      }

      KitText {
        width: parent.width - cancelButton.width - acceptButton.width - 2 * parent.spacing
        visible: root.picker !== null && root.picker.mode !== "save"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: FilesService.error !== "" ? FilesService.error : "enter " + (root.picker && root.picker.directory ? "selects the folder" : "opens") + " · esc cancels"
        color: FilesService.error !== "" ? Theme.red : Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      KitButton {
        id: cancelButton
        text: "Cancel"
        onClicked: FilesService.finishPick([], 1)
      }

      KitButton {
        id: acceptButton
        text: root.picker ? (root.picker.mode === "save" ? "Save" : root.picker.directory ? "Select" : "Open") : ""
        onClicked: root.accept()
      }
    }

    KitInput {
      id: creatingField
      width: parent.width
      visible: root.creating !== "" && root.picker === null
      placeholder: root.creating === "folder" ? "new folder name" : root.creating === "batch" ? "pattern: photo_{n}{ext}  ({n} number, {name} stem)" : "new file name"
      passKeys: [Qt.Key_Escape]
      onAccepted: root.finishCreate()
      onKeyPassed: { root.creating = ""; root.forceActiveFocus(); }
    }

    KitText {
      anchors.fill: parent
      visible: root.creating === "" && root.picker === null
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      text: FilesService.error !== "" ? FilesService.error
          : FilesService.job !== null ? FilesService.job.label + " " + FilesService.job.name + (FilesService.job.of > 0 ? " · " + FilesService.job.progress + " of " + FilesService.job.of : "") + " · esc cancels"
          : root.trashSure ? "Move to the trash? Press delete again"
          : root.sure ? "Delete for good? Press delete again"
          : root.emptySure ? "Empty the trash? Press Empty again"
          : FilesService.clip.length > 0 && !FilesService.inTrash
            ? FilesService.clip.length + (FilesService.clipMode === "move" ? " to move" : " to copy") + " · ctrl + v paste"
          : !FilesService.hints ? ""
          : FilesService.dupes ? "click a group folds it · right click trashes its copies · esc leaves"
          : FilesService.inTrash ? "enter open · ctrl + r restore · del delete for good · f1 keys"
          : "enter open · ctrl + c copy · ctrl + x cut · del trash · f1 keys"
      color: FilesService.error !== "" || root.sure || root.emptySure || root.trashSure ? Theme.red : Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }
  }

  // the menus open where they were asked for (scene coordinates = the window's)
  function menuAt(at, items) { menu.open(at.x, at.y, items); }

  // a group header's menu: fold it, or trash the copies in every group
  function groupMenu(group) {
    return [
      { label: FilesService.isCollapsed(group.group) ? "Unfold" : "Fold", run: () => FilesService.toggleGroup(group.group) },
      { label: "Trash the copies", hint: "keeps one per group", run: () => FilesService.trashCopies() },
    ];
  }

  // ---- properties of a file: the panel (Menu › Properties) ----
  // the keys, for F1
  readonly property var keyRows: [
    { key: "enter", action: "open, or pick in a picker" },
    { key: "backspace", action: "the folder above" },
    { key: "alt + ← →", action: "back and forward" },
    { key: "↑ ↓ (grid: ← →)", action: "move; with shift, extend" },
    { key: "ctrl + a c x v", action: "select all, copy, cut, paste" },
    { key: "ctrl + z / shift + z", action: "undo, redo" },
    { key: "del", action: "move to the trash" },
    { key: "shift + del", action: "delete for good" },
    { key: "f2", action: "rename" },
    { key: "ctrl + n / d", action: "new folder, bookmark this folder" },
    { key: "ctrl + f", action: "focus the search" },
    { key: "ctrl + k", action: "search all of Home, or this folder" },
    { key: "ctrl + h / g", action: "hidden files, grid view" },
    { key: "ctrl + l", action: "type a path" },
    { key: "space", action: "show or hide the preview" },
    { key: "f5", action: "read the folder again" },
    { key: "esc", action: "clear, close" },
  ]

  // a click off the panels closes them
  MouseArea {
    anchors.fill: parent
    visible: FilesService.panel !== null || root.helpOpen
    z: 27
    acceptedButtons: Qt.AllButtons
    onPressed: { FilesService.closeInfo(); root.helpOpen = false; }
  }

  KitFrame {
    id: infoCard
    z: 28
    width: 380
    anchors.centerIn: parent
    visible: FilesService.panel !== null

    KitHeader {
      icon: "info"
      title: FilesService.panel ? FilesService.panel.title : ""
      subtitle: FilesService.panel ? FilesService.panel.subtitle : ""
    }

    KitLine {}

    Repeater {
      model: FilesService.panel ? FilesService.panel.rows : []

      Row {
        required property var modelData
        width: infoCard.width - 2 * infoCard.padding
        spacing: Theme.gapMedium

        KitText {
          width: 96
          text: modelData.label
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          width: parent.width - 96 - parent.spacing
          text: modelData.value
          wrapMode: Text.WrapAnywhere
          font.pixelSize: Theme.fontSize - 1
        }
      }
    }
  }

  // ---- the keys (F1) ----
  KitFrame {
    id: helpCard
    z: 28
    width: 400
    anchors.centerIn: parent
    visible: root.helpOpen

    KitHeader { icon: "keyboard"; title: "Keys" }

    KitLine {}

    Repeater {
      model: root.keyRows

      Row {
        required property var modelData
        width: helpCard.width - 2 * helpCard.padding
        spacing: Theme.gapMedium

        KitText {
          width: 150
          text: modelData.key
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          width: parent.width - 150 - parent.spacing
          text: modelData.action
          color: Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }
      }
    }
  }

  // a click off the menu closes it
  MouseArea {
    anchors.fill: parent
    visible: menu.visible
    z: 19
    acceptedButtons: Qt.AllButtons
    onPressed: menu.close()
  }

  FilesMenu {
    id: menu
    z: 20
  }
}
