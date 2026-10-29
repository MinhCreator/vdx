import QtQuick

// Borrow visual content without taking ownership of the popup's lifecycle.
// Restore before this host disappears, including during a bar/style rebuild.
Item {
  id: root

  property bool available: true
  onAvailableChanged: if (!available) dismiss()

  readonly property var popup: borrowedPopup
  readonly property Item content: borrowedItems[0] ?? null
  property var borrowedPopup: null
  property Item home: null
  property var borrowedItems: []

  function attach(p) {
    if (!available || borrowedPopup === p) return;
    release();
    if (!p?.contentItem) return;
    home = p.contentItem;
    const items = [];
    for (let i = 0; i < home.children.length; i++) items.push(home.children[i]);
    borrowedPopup = p;
    borrowedItems = items;
    items.forEach(item => item.parent = root);
    if (content && content.inIsland !== undefined) content.inIsland = true;
  }

  function release() {
    if (content && content.inIsland !== undefined) content.inIsland = false;
    borrowedItems.forEach(item => {
      if (item && item.parent === root) item.parent = home;
    });
    borrowedItems = [];
    borrowedPopup = null;
    home = null;
  }

  function dismiss() {
    if (borrowedPopup?.visible) borrowedPopup.visible = false;
    release();
  }

  Component.onDestruction: dismiss()
}
