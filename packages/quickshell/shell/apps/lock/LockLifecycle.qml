import QtQuick

// Serialize marker writes and cleanup around the Wayland lock. Storage is an
// adapter; keeping decisions here makes startup races testable without locking.
QtObject {
  required property var context
  required property var storage
  property bool marking: false
  property bool cleaning: false
  property bool unlocking: false
  property bool cleanupPending: false
  property bool waitingLock: false
  property int generation: 0
  property int reading: -1

  signal retryLock()
  signal failed(string message)

  function requestLock() {
    generation++;
    if (cleaning || cleanupPending) { waitingLock = true; return false; }
    return true;
  }

  function restore() {
    reading = generation;
    storage.readMarker();
  }

  function restored(found) {
    const current = reading === generation;
    reading = -1;
    // A new lock request supersedes this startup read, even while its
    // background is still being prepared. Never clear its new marker.
    if (!current) return;
    // A live-reloaded surface may already be locked even if an interrupted
    // cleanup removed its marker. Preserve the lock and repair the marker.
    if (context.locked) { if (!marking) locked(); return; }
    if (found) context.locked = true;
    else cleanup();
  }

  function locked() {
    generation++;
    marking = true;
    storage.writeMarker();
  }

  function marked() {
    marking = false;
    if (cleanupPending) cleanup();
  }

  function cleanup() {
    if (cleaning) return;
    if (marking) { cleanupPending = true; return; }
    cleanupPending = false;
    cleaning = true;
    storage.clearMarker();
  }

  function verified() {
    if (!context.locked || unlocking) return;
    generation++;
    unlocking = true;
    cleanup();
  }

  function cleared(ok) {
    if (!cleaning) return;
    cleaning = false;
    const release = unlocking;
    unlocking = false;
    if (release) {
      if (ok) context.locked = false;
      else failed("Could not clear lock state. Try unlocking again.");
    }
    const retry = waitingLock;
    waitingLock = false;
    if (retry) retryLock();
  }
}
