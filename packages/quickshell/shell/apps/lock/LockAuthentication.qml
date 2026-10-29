import QtQuick

// Password and attempt state shared by every lock surface. The PAM adapter
// supplies start/abort/respond; tests use a context that never authenticates.
QtObject {
  required property var context
  property bool locked: false
  property bool busy: false
  property string error: ""
  property string pending: ""
  property string typed: ""

  signal verified()

  onLockedChanged: {
    const wasBusy = busy;
    clear();
    if (wasBusy) context.abort();
  }

  function clear() {
    pending = "";
    typed = "";
    error = "";
    busy = false;
  }

  function tryUnlock(password) {
    if (!locked || busy || password === "") return false;
    pending = password;
    typed = "";
    error = "";
    busy = true;
    if (!context.start()) fail();
    return true;
  }

  function answer() {
    if (!busy || !context.responseRequired) return;
    const password = pending;
    pending = "";
    context.respond(password);
  }

  function complete(success) {
    if (!busy) return;
    pending = "";
    typed = "";
    error = success ? "" : "Wrong password";
    busy = false;
    if (success) verified();
  }

  function fail() {
    if (!busy) return;
    pending = "";
    typed = "";
    error = "PAM error";
    busy = false;
  }
}
