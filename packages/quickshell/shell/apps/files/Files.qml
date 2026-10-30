import QtQuick
import Quickshell
import qs.config
import qs.kit

// The file manager, laid out as Shell Manager: the sidebar is a pane of its own (the window's header,
// the places, devices and storage); the page has the folder's header, the path as
// crumbs and the search, then the folder (or the search result, or the trash) as a list (folders as
// tiles, files as a table), a grid or columns, and a preview of the selection on the right. While
// a portal asks for files (svc.picker) the same window picks them: a
// file name field for save, Cancel and the accept button below.
// Keys: arrows move (grid: all four), shift extends, enter opens (picks), backspace
// goes up, alt+arrows go back and forward, ctrl+c/x/v copy, cut, paste, ctrl+a all,
// delete trashes, shift+delete removes for good, F2 renames, ctrl+n a new folder,
// ctrl+d pins the folder, ctrl+s stars the selection, a letter jumps to a name, ctrl+h hidden files, ctrl+g the view, ctrl+l the
// path, ctrl+f the search. A right click opens FilesMenu; files dropped on the
// list are copied in.
Item {
  id: root

  required property var svc          // the FilesState it shows: the browser's, or the picker's own

  signal closeRequested()

  readonly property int padding: Theme.windowPadding
  // the panes and columns: dragged by their strips, kept in the options
  property int sideW: svc.opt("sideWidth", 190)
  property int previewW: svc.opt("previewWidth", 240)
  property int sizeWidth: svc.opt("sizeWidth", 84)
  property int dateWidth: svc.opt("dateWidth", 124)
  readonly property int kindWidth: 72
  // the table's columns from the right edge, as Settings › Columns shows them: ⋮, the date, the size,
  // the type; the name takes the rest. Each {x, w}; seps: a separator in the middle of each gap
  function cols(w) {
    let r = w - Theme.gapWide - (svc.rowActions ? 28 : 0);
    const c = { seps: [] };
    const take = (key, width) => { c[key] = { x: r - width, w: width }; r -= width + Theme.gapWide; c.seps.push(r + Theme.gapWide / 2); };
    if (svc.showDate) take("date", dateWidth);
    if (svc.showSize) take("size", sizeWidth);
    if (svc.showKind) take("kind", kindWidth);
    c.nameEnd = r;
    return c;
  }
  // where a row's icon starts: after the box to tick
  readonly property int nameX: Theme.gapWide + (svc.checkboxes && !picker ? 16 + Theme.gapWide : 0)
  // the list view shows the folders as tiles above the files (not in a search, the trash or a picker)
  readonly property bool tiles: svc.folderTiles && !grid && !columnsView && !svc.searching
                                && !svc.virtual && svc.groupBy === "none"
  readonly property bool grid: svc.shownView === "grid"
  readonly property bool columnsView: svc.shownView === "columns"
  readonly property bool selectedDir: svc.selected.length === 1 && svc.selected[0].kind === "dir"
  readonly property var picker: svc.picker

  // what is being typed in the footer or over a row: a folder or a file to
  // create, a path to rename; a delete or an empty waiting for its second press
  property string creating: ""           // "" | folder | file
  property string renaming: ""           // a path
  property bool sure: false
  property bool emptySure: false
  property bool helpOpen: false          // F1: the keys
  property bool trashSure: false         // a move to the trash waiting for its second press
  property int parentW: svc.parentWidth    // the Columns view's side columns, dragged
  property int childW: svc.childWidth
  readonly property bool markdown: previewed !== null && previewed.name.toLowerCase().endsWith(".md")

  readonly property var previewed: svc.selected.length === 1 ? svc.selected[0] : null
  // folders have no preview: only a file's
  readonly property bool previewing: svc.showPreview && previewed !== null && previewed.kind !== "dir"

  focus: true
  Keys.onPressed: event => handleKey(event)

  Connections {
    target: svc
    // a new folder starts at its top, not where the last one was scrolled to
    function onPathChanged() {
      root.sure = false; root.emptySure = false;
      // the top is the header (Up, the tiles), above the first row
      Qt.callLater(() => { listFrame.listView.contentY = listFrame.listView.originY; listFrame.gridView.contentY = listFrame.gridView.originY; });
    }
    function onSelectionChanged() { root.sure = false; root.trashSure = false; }
    function onPickerChanged() { saveField.text = svc.picker ? svc.picker.name : ""; }
    function onQueryChanged() { if (searchField.text !== svc.query) searchField.text = svc.query; }
    // the keys move the selection: the view follows it
    function onAnchorChanged() {
      if (root.grid) {
        const i = svc.shown.findIndex(e => e.path === svc.anchor);
        if (i >= 0) listFrame.gridView.positionViewAtIndex(i, GridView.Contain);
        return;
      }
      const i = listFrame.listModel.findIndex(e => e.path === svc.anchor);
      // a folder's tile sits in the list's header
      if (i < 0) listFrame.listView.contentY = listFrame.listView.originY;
      else listFrame.listView.positionViewAtIndex(i, ListView.Contain);
    }
  }

  // typing a name jumps to it (Settings › Type to find): the letters typed in a short while
  property string typed: ""
  Timer { id: typedTimer; interval: 900; onTriggered: root.typed = "" }
  function typeAhead(text) {
    typed += text.toLowerCase();
    typedTimer.restart();
    const hit = svc.rows.find(e => e.name.toLowerCase().startsWith(typed));
    if (hit) svc.select(hit.path, "single");
  }

  function handleKey(event) {
    const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
    const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
    const alt = (event.modifiers & Qt.AltModifier) !== 0;
    if (event.key === Qt.Key_Escape) {
      if (menu.visible) menu.close();
      else if (helpOpen) helpOpen = false;
      else if (svc.job !== null) svc.cancelJob();
      else if (svc.panel !== null) svc.closeInfo();
      else if (picker) svc.finishPick([], 1);
      else if (svc.dupes) svc.leaveDupes();
      else if (svc.everywhere) svc.toggleEverywhere();
      else if (svc.query !== "") svc.setQuery("");
      else if (svc.selection.length > 0) svc.selection = [];
      else root.closeRequested();
      return;
    }
    if (ctrl) {
      switch (event.key) {
        case Qt.Key_A: svc.selectAll(); return;
        case Qt.Key_C: svc.copySelection(); return;
        case Qt.Key_X: if (!svc.inTrash && !picker) svc.cutSelection(); return;
        case Qt.Key_V: if (picker) return; if (svc.canPaste) svc.paste(); else svc.pasteFromSystem(); return;
        case Qt.Key_T: svc.openTerminal(root.folderForTerminal()); return;
        case Qt.Key_R: if (svc.inTrash) svc.restoreSelection(); return;
        case Qt.Key_N: if (svc.writable && !picker) startCreate("folder"); return;
        case Qt.Key_D: if (svc.writable) svc.pin(svc.path); return;
        case Qt.Key_S: if (svc.selection.length > 0) svc.toggleStar(svc.selection); return;
        case Qt.Key_H: svc.setOption("hidden", !svc.hidden); return;
        case Qt.Key_G: svc.cycleView(); return;
        case Qt.Key_Z: if (picker) return; if (shift) svc.redo(); else svc.undo(); return;
        case Qt.Key_Y: if (!picker) svc.redo(); return;
        case Qt.Key_K: svc.toggleEverywhere(); searchField.input.forceActiveFocus(); return;
        case Qt.Key_L: crumbs.edit(); return;
        case Qt.Key_F: searchField.input.forceActiveFocus(); return;
      }
      return;
    }
    if (alt && event.key === Qt.Key_Left) { svc.back(); return; }
    if (alt && event.key === Qt.Key_Right) { svc.forward(); return; }
    const cols = root.grid ? svc.columns : 1;
    switch (event.key) {
      case Qt.Key_Up: svc.step(-cols, shift); return;
      case Qt.Key_Down: svc.step(cols, shift); return;
      case Qt.Key_Left: if (root.grid) svc.step(-1, shift); return;
      case Qt.Key_Right: if (root.grid) svc.step(1, shift); return;
      case Qt.Key_Return:
      case Qt.Key_Enter:
        if (picker) accept();
        else if (svc.selected.length === 1) open(svc.selected[0]);
        return;
      case Qt.Key_Backspace: svc.up(); return;
      case Qt.Key_F2:
        if (svc.inTrash || picker) return;
        if (svc.selected.length === 1) renaming = svc.selected[0].path;
        else if (svc.selected.length > 1) startCreate("batch");
        return;
      case Qt.Key_F5: svc.refresh(); return;
      case Qt.Key_F1: helpOpen = !helpOpen; return;
      case Qt.Key_Space: svc.setOption("preview", !svc.showPreview); return;
      case Qt.Key_Delete: remove(shift); return;
    }
    if (svc.typeAhead && !alt && event.text.length === 1 && event.text > " ") { typeAhead(event.text); event.accepted = true; }
  }

  // a folder opens inside the window, a file with its default program; in a picker a file is picked
  function open(entry) {
    if (picker && entry.kind !== "dir") {
      svc.select(entry.path, "single");
      accept();
    } else if (entry.kind === "dir" && !svc.inTrash) {
      svc.go(entry.path);
    } else {
      svc.openExternal(entry.path);
    }
  }

  // a click: ctrl toggles, shift takes the range; in a save picker a file's name goes to the field
  function click(entry, mouse) {
    root.forceActiveFocus();
    // Settings › Behaviour: one click opens, unless a modifier selects
    if (svc.singleClick && !(mouse.modifiers & (Qt.ShiftModifier | Qt.ControlModifier))) {
      svc.select(entry.path, "single");
      open(entry);
      return;
    }
    if (mouse.modifiers & Qt.ShiftModifier) svc.select(entry.path, "range");
    else if (mouse.modifiers & Qt.ControlModifier) svc.select(entry.path, "toggle");
    else svc.select(entry.path, "single");
    if (picker && picker.mode === "save" && entry.kind !== "dir") saveField.text = entry.name;
  }

  function contextMenu(entry, at) {
    if (!svc.selection.includes(entry.path)) svc.select(entry.path, "single");
    menu.open(at.x, at.y, menuFor(entry));
  }

  // to the trash (asked once when Settings › Safety says so); a permanent delete (shift, or anything in the trash) asks once when confirm is on
  function remove(permanent) {
    if (svc.selection.length === 0 || picker) return;
    if (svc.inTrash || permanent) {
      if (svc.confirmDelete && !sure) { sure = true; return; }
      sure = false;
      svc.deleteSelection();
    } else {
      if (svc.confirmTrash && !trashSure) { trashSure = true; return; }
      trashSure = false;
      svc.trashSelection();
    }
  }

  // ctrl + t: the folder selected, or the one shown
  function folderForTerminal() {
    const one = svc.selected.length === 1 && svc.selected[0].kind === "dir";
    return one ? svc.selected[0].path : svc.path;
  }

  function emptyTrash() {
    if (svc.confirmDelete && !emptySure) { emptySure = true; return; }
    emptySure = false;
    svc.emptyTrash();
  }

  function startCreate(kind) {
    creating = kind;
    creatingField.text = "";
    creatingField.input.forceActiveFocus();
  }

  function finishCreate() {
    const name = creatingField.text.trim();
    if (name !== "") {
      if (creating === "folder") svc.createFolder(name);
      else if (creating === "batch") svc.batchRename(name);
      else svc.createFile(name);
    }
    creating = "";
    root.forceActiveFocus();
  }

  function finishRename(entry, name) {
    renaming = "";
    if (name.trim() !== "" && name.trim() !== entry.name) svc.rename(entry.path, name);
    root.forceActiveFocus();
  }

  // the picker's accept: the selected files (or the folder, for a folder picker, or the save name)
  function accept() {
    if (!picker) return;
    if (picker.mode === "save") {
      const name = saveField.text.trim();
      if (!svc.validName(name)) return;
      if (svc.entries.some(e => e.name === name)) {
        svc.error = "\"" + name + "\" is here already";
        return;
      }
      svc.finishPick([svc.path + "/" + name], 0);
      return;
    }
    const picked = svc.selected
      .filter(e => picker.directory ? e.kind === "dir" : e.kind !== "dir")
      .map(e => e.path);
    if (picked.length === 0) {
      if (picker.directory) svc.finishPick([svc.path], 0);
      return;
    }
    svc.finishPick(picker.multiple ? picked : picked.slice(0, 1), 0);
  }

  // a drop from another app: the files are copied into the folder (the one shown, or a folder's tile or
  // card), not ones already there and not a folder into itself
  function dropped(urls, dest) {
    const paths = urls.map(u => svc.pathFromUri(u.toString()))
                      .filter(p => p !== "" && p !== dest && svc.parentOf(p) !== dest);
    const writable = dest !== svc.path || svc.writable;
    if (paths.length > 0 && writable && !picker)
      svc.act({ done: "pasted" }, ["paste", "copy", dest].concat(paths));
  }

  function when(time) {
    const d = new Date(time * 1000);
    if (svc.dateFormat === "iso") return Qt.formatDateTime(d, "yyyy-MM-dd HH:mm");
    const today = d.toDateString() === new Date().toDateString();
    return Qt.formatDateTime(d, today ? "HH:mm" : "dd.MM.yy HH:mm");
  }

  function iconFor(kind) {
    return { dir: "folder", image: "image", video: "video", audio: "music", text: "file", archive: "package" }[kind] ?? "file";
  }

  function placeIcon(name) {
    return { Home: "home", Desktop: "monitor", Documents: "file", Downloads: "download", Music: "music",
             Pictures: "image", Videos: "video", Root: "server", Trash: "trash" }[name] ?? "folder";
  }
  // the header's icon for a path: a place's own, else a folder
  function placeIconFor(p) {
    if (p === svc.computerPath) return "monitor";
    if (p === svc.trashPath) return "trash";
    if (p === svc.recentPath) return "history";
    if (p === svc.starredPath) return "star";
    if (p === svc.home) return "home";
    const place = svc.places.find(x => x.path === p);
    return place ? placeIcon(place.name) : "folder";
  }

  // the header's subtitle: what is here, then what is selected
  function counts() {
    const rows = svc.rows;
    const dirs = rows.filter(e => e.kind === "dir").length;
    const parts = [];
    if (dirs > 0) parts.push(dirs + (dirs === 1 ? " FOLDER" : " FOLDERS"));
    if (rows.length - dirs > 0 || dirs === 0) parts.push((rows.length - dirs) + (rows.length - dirs === 1 ? " FILE" : " FILES"));
    if (svc.selection.length > 0) parts.push(svc.selection.length + " SELECTED");
    return parts.join(" · ");
  }

  // the type column: a folder, or the file's extension
  function kindLabel(e) {
    if (e.kind === "dir") return "Folder";
    const i = e.name.lastIndexOf(".");
    if (i > 0 && e.name.length - i <= 6) return e.name.slice(i + 1).toUpperCase();
    return e.kind.charAt(0).toUpperCase() + e.kind.slice(1);
  }

  // the size column: a file's size, a folder's items (Settings › Folder sizes)
  function sizeLabel(e) {
    if (e.kind !== "dir") return Format.humanSize(e.size);
    if (e.count === undefined || e.count < 0) return "--";
    return e.count === 1 ? "1 item" : e.count + " items";
  }

  // a path as a URL the image loader reads
  function fileUrl(p) { return svc.fileUri(p); }

  // the menu of a right click: what an entry can do now (a dimmed row can't)
  function menuFor(entry) {
    const one = svc.selection.length === 1;
    const sep = { separator: true };
    if (svc.inTrash) return [
      { label: "Open", tone: "primary", run: () => root.open(entry) },
      { label: "Restore", hint: "Ctrl + R", run: () => svc.restoreSelection() },
      sep,
      { label: "Delete for good", hint: "Delete", tone: "danger", run: () => root.remove(true) },
    ];
    const custom = picker !== null ? [] : svc.actions.map(a => ({
      label: a.label, run: () => svc.runAction(a, svc.selection),
    }));
    return [
      { label: "Open", tone: "primary", run: () => root.open(entry) },
      { label: "Open the folder it is in", disabled: !svc.virtual && !svc.searching, run: () => svc.reveal(entry.path) },
      sep,
      { label: "Copy", hint: "Ctrl + C", run: () => svc.copySelection() },
      { label: "Cut", hint: "Ctrl + X", disabled: picker !== null, run: () => svc.cutSelection() },
      { label: "Paste", hint: "Ctrl + V", disabled: !svc.canPaste || picker !== null, run: () => svc.paste() },
      { label: "Copy path", run: () => Quickshell.execDetached(["wl-copy", entry.path]) },
      sep,
      { label: "Rename", hint: "F2", disabled: !one || picker !== null, run: () => root.renaming = entry.path },
      { label: svc.isStarred(entry.path) ? "Unstar" : "Star", hint: "Ctrl + S", run: () => svc.toggleStar(svc.selection) },
      { label: "Pin to sidebar", disabled: entry.kind !== "dir" || svc.isPinned(entry.path), run: () => svc.pin(entry.path) },
      { label: "Properties", run: () => svc.inspect(entry.path) },
      sep,
      { label: "Terminal here", disabled: entry.kind !== "dir", run: () => svc.openTerminal(entry.path) },
      { label: "Find duplicates here", disabled: entry.kind !== "dir", run: () => svc.findDuplicates(entry.path) },
    ].concat(custom.length ? [sep].concat(custom) : [], [
      sep,
      { label: "Move to trash", hint: "Delete", tone: "danger", disabled: picker !== null, run: () => root.remove(false) },
      { label: "Delete for good", hint: "Shift + Delete", tone: "danger", disabled: picker !== null, run: () => root.remove(true) },
    ]);
  }

  // ---- the sidebar: its own pane, as in Shell Manager: the window's header, the places, the storage ----
  Rectangle {
    id: sidePane
    visible: root.picker === null
    // the list's width plus the window's frame on each side, as Shell Manager's
    width: visible ? root.sideW + root.padding : 0
    height: parent.height
    color: Theme.sideFill

    // the header sits centred between the window's top and its line, which is level with the page's
    KitLine {
      id: brandLine
      x: root.padding
      y: headerLine.y
      width: parent.width - root.padding
    }

    KitHeader {
      id: brandHead
      x: root.padding
      y: (brandLine.y - height) / 2
      width: brandLine.width
      icon: "folder"
      title: "Files"
      subtitle: svc.selection.length > 0 ? svc.selection.length + " SELECTED"
              : svc.clip.length > 0 ? svc.clip.length + (svc.clipMode === "move" ? " TO MOVE" : " TO COPY")
              : "SUPER + E"
    }

    FilesSidebar {
      id: sideFrame
      files: root
      x: root.padding
      y: brandLine.y + brandLine.height + Theme.gapGroup
      width: root.sideW - root.padding
      height: parent.height - root.padding - y
    }
  }

  // the line between the panes, and the strip on it: drag it to resize the sidebar
  KitLine {
    visible: sidePane.visible
    anchors { left: sidePane.right; top: parent.top; bottom: parent.bottom }
    vertical: true
  }
  FilesSplit {
    visible: sidePane.visible
    x: sidePane.width - width / 2
    y: 0
    height: root.height
    reference: root
    onDragged: x => root.sideW = Math.max(170, Math.min(380, x - root.padding))
    onFinished: svc.setOption("sideWidth", root.sideW)
  }

  // ---- the page: the folder's header, the path and the search, the list, the preview ----
  Item {
    id: page
    anchors { left: sidePane.right; right: parent.right; top: parent.top; bottom: parent.bottom
              leftMargin: (sidePane.visible ? 1 : 0) + root.padding; rightMargin: root.padding }

    KitHeader {
      id: header
      anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: root.padding - Theme.headerInset }
      icon: root.picker ? "folder" : root.placeIconFor(svc.path)
      title: root.picker ? root.picker.title : svc.title
      subtitle: svc.dupes ? "DUPLICATES · " + svc.rows.length + " FILES IN " + svc.dupGroups + " GROUPS"
              : root.picker ? (root.picker.mode === "save" ? "SAVE" : root.picker.directory ? "CHOOSE A FOLDER" : "CHOOSE")
                              + (svc.selection.length > 0 ? " · " + svc.selection.length + " SELECTED" : "")
              : svc.atComputer ? svc.volumes.length + " STORAGE"
              : svc.searching ? "SEARCH · " + svc.shown.length + " FOUND"
              : root.counts()

      KitButton {
        icon: "arrow-left"
        disabled: !svc.canBack
        onClicked: svc.back()
      }
      KitButton {
        icon: "arrow-right"
        disabled: !svc.canForward
        onClicked: svc.forward()
      }
      KitButton {
        icon: "arrow-up"
        disabled: !svc.canUp
        onClicked: svc.up()
      }
      // the views, side by side: the one shown is selected
      Repeater {
        model: svc.atComputer ? ["list", "grid"] : ["list", "grid", "columns"]
        KitButton {
          required property string modelData
          icon: modelData
          selected: svc.shownView === modelData
          onClicked: svc.setOption(svc.atComputer ? "computerView" : "view", modelData)
        }
      }
      KitButton {
        icon: "sliders"
        text: svc.sortLabel + (svc.atComputer ? " ↑" : svc.sortDesc ? " ↓" : " ↑")
        visible: !root.picker && (root.grid || svc.atComputer)
        onClicked: svc.sortNext()
      }
      KitButton {
        icon: "plus"
        text: "New"
        visible: svc.writable && !root.picker
        onClicked: root.startCreate("folder")
      }
      KitButton {
        icon: "trash"
        text: root.emptySure ? "Sure?" : "Empty"
        visible: svc.inTrash
        disabled: svc.entries.length === 0
        onClicked: root.emptyTrash()
      }
    }

    KitLine {
      id: headerLine
      anchors { top: header.bottom; topMargin: Theme.gapGroup }
      width: parent.width
    }

    // ---- the path and the search ----
    Row {
      id: fields
      anchors { top: headerLine.bottom; left: parent.left; right: parent.right; topMargin: Theme.gapGroup }
      spacing: Theme.gapMedium

      FilesCrumbs {
        id: crumbs
        svc: root.svc
        width: parent.width - searchField.width - parent.spacing
        onDone: root.forceActiveFocus()
      }

      KitInput {
        id: searchField
        width: Math.min(260, parent.width * 0.32)
        placeholder: svc.everywhere ? "Search all of Home…" : svc.virtual ? "filter" : "Search here and below…"
        passKeys: [Qt.Key_Escape]
        text: svc.query
        onTextEdited: svc.setQuery(text)
        onKeyPassed: { if (svc.everywhere) svc.toggleEverywhere(); else svc.setQuery(""); root.forceActiveFocus(); }
        onAccepted: root.forceActiveFocus()
      }
    }

    // ---- body: the list or grid (or the storage), the preview beside it ----
    Item {
      id: body
      anchors { top: fields.bottom; bottom: footer.top; left: parent.left; right: parent.right
                topMargin: Theme.gapGroup; bottomMargin: footer.height > 0 ? Theme.gapMedium : 0 }

      FilesList {
        id: listFrame
        files: root
        visible: !svc.atComputer
        x: 0
        y: 0
        width: body.width - (root.previewing ? previewSplit.width + root.previewW : 0)
        height: body.height
      }

      // This computer: the storage, in the list's place
      FilesComputer {
        visible: svc.atComputer
        files: root
        x: 0
        y: 0
        width: body.width
        height: body.height
      }

      // the strip between the list and the preview: drag it to resize the preview
      FilesSplit {
        id: previewSplit
        visible: root.previewing
        x: listFrame.width
        y: 0
        height: body.height
        reference: body
        onDragged: x => root.previewW = Math.max(180, Math.min(480, body.width - x - width / 2))
        onFinished: svc.setOption("previewWidth", root.previewW)
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
      anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: root.padding }
      // only while there is something to say or type: the list takes the room otherwise
      height: root.picker !== null || root.creating !== "" || statusLine.text !== "" ? 32 : 0

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
          onKeyPassed: svc.finishPick([], 1)
        }

        KitText {
          width: parent.width - cancelButton.width - acceptButton.width - 2 * parent.spacing
          visible: root.picker !== null && root.picker.mode !== "save"
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          text: svc.error !== "" ? svc.error : "enter " + (root.picker && root.picker.directory ? "selects the folder" : "opens") + " · esc cancel"
          color: svc.error !== "" ? Theme.red : Theme.muted
          font.pixelSize: Theme.fontSize - 1
        }

        KitButton {
          id: cancelButton
          text: "Cancel"
          onClicked: svc.finishPick([], 1)
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
        id: statusLine
        anchors.fill: parent
        visible: root.creating === "" && root.picker === null
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        text: svc.error !== "" ? svc.error
            : svc.job !== null ? svc.job.label + " " + svc.job.name + (svc.job.of > 0 ? " · " + svc.job.progress + " of " + svc.job.of : "") + " · esc cancel"
            : root.trashSure ? "Move to trash? Press delete again"
            : root.sure ? "Delete for good? Press delete again"
            : root.emptySure ? "Empty the trash? Press Empty again"
            : svc.clip.length > 0 && !svc.inTrash
              ? svc.clip.length + (svc.clipMode === "move" ? " to move" : " to copy") + " · ctrl + v paste"
            : ""
        color: svc.error !== "" || root.sure || root.emptySure || root.trashSure ? Theme.red : Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }
    }
  }

  // the menus open where they were asked for (scene coordinates = the window's)
  function menuAt(at, items) { menu.open(at.x, at.y, items); }

  // a group header's menu: fold it, or trash the copies in every group
  function groupMenu(group) {
    return [
      { label: svc.isCollapsed(group.group) ? "Unfold" : "Fold", run: () => svc.toggleGroup(group.group) },
      { label: "Trash the copies", hint: "keeps one per group", run: () => svc.trashCopies() },
    ];
  }

  // a click off the panels closes them
  MouseArea {
    anchors.fill: parent
    visible: svc.panel !== null || root.helpOpen
    z: 27
    acceptedButtons: Qt.AllButtons
    onPressed: { svc.closeInfo(); root.helpOpen = false; }
  }

  FilesInfoCard {
    svc: root.svc
    z: 28
    width: 380
    anchors.centerIn: parent
    visible: svc.panel !== null
  }

  FilesKeysCard {
    z: 28
    width: 400
    anchors.centerIn: parent
    visible: root.helpOpen
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
    host: root
  }
}
