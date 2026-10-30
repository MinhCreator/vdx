import QtQuick
import QtTest
import qs.kit

TestCase {
  name: "LockLifecycle"
  QtObject { id: session; property bool locked: false }
  QtObject {
    id: disk
    property var calls: []
    function readMarker() { calls = calls.concat(["read"]); }
    function writeMarker() { calls = calls.concat(["write"]); }
    function clearMarker() { calls = calls.concat(["clear"]); }
  }
  Component { id: factory; LockLifecycle { context: session; storage: disk } }
  SignalSpy { id: retries; signalName: "retryLock" }
  SignalSpy { id: failures; signalName: "failed" }
  function init() { session.locked = false; disk.calls = []; }
  function lifecycle() {
    const state = createTemporaryObject(factory, this);
    retries.target = failures.target = state;
    retries.clear(); failures.clear();
    return state;
  }

  function test_matching_marker_restores_without_cleanup() {
    const state = lifecycle();
    state.restore(); state.restored(true);
    verify(session.locked); compare(disk.calls, ["read"]);
  }

  function test_missing_marker_cleans_stale_state_once() {
    const state = lifecycle();
    state.restore(); state.restored(false);
    verify(!session.locked); verify(state.cleaning);
    state.cleanup(); compare(disk.calls, ["read", "clear"]);
    state.cleared(true); verify(!state.cleaning);
  }

  function test_reloaded_locked_surface_repairs_missing_marker() {
    const state = lifecycle();
    state.restore(); session.locked = true;
    state.restored(false);
    verify(session.locked); verify(state.marking);
    compare(disk.calls, ["read", "write"]);
    state.marked(true); verify(!state.cleaning);
  }

  function test_new_lock_supersedes_both_results_of_startup_read() {
    for (const found of [false, true]) {
      const state = lifecycle();
      disk.calls = [];
      state.restore(); verify(state.requestLock());
      state.restored(found);
      verify(!session.locked); compare(disk.calls, ["read"]);
      session.locked = true; state.locked(); state.marked(true);
      compare(disk.calls, ["read", "write"]);
      session.locked = false;
    }
  }

  function test_cleanup_defers_new_lock_until_it_has_finished() {
    const state = lifecycle();
    state.cleanup();
    verify(!state.requestLock()); verify(!state.requestLock());
    compare(retries.count, 0); compare(disk.calls, ["clear"]);
    state.cleared(true);
    compare(retries.count, 1); verify(state.requestLock());
  }

  function test_unlock_waits_for_marker_write_and_cleanup() {
    const state = lifecycle();
    session.locked = true;
    state.locked(); state.verified();
    verify(session.locked); verify(state.unlocking);
    compare(disk.calls, ["write"]);
    state.marked(true); compare(disk.calls, ["write", "clear"]);
    verify(session.locked);
    state.cleared(true);
    verify(!session.locked); verify(!state.unlocking);
    compare(failures.count, 0);
    // The next lock writes only after the old cleanup has completed.
    verify(state.requestLock()); session.locked = true; state.locked();
    compare(disk.calls, ["write", "clear", "write"]);
  }

  function test_cleanup_failure_keeps_lock_and_allows_retry() {
    const state = lifecycle();
    session.locked = true;
    state.verified(); state.cleared(false);
    verify(session.locked); verify(!state.unlocking);
    compare(failures.count, 1);
    state.verified(); state.cleared(true);
    verify(!session.locked);
  }

  function test_marker_write_failure_reports_error_and_keeps_lock() {
    const state = lifecycle();
    session.locked = true;
    state.locked(); state.marked(false);
    verify(session.locked); verify(!state.marking);
    compare(failures.count, 1);
    compare(failures.signalArguments[0][0], "Could not save lock recovery state. The session remains locked.");
  }

  function test_verification_invalidates_stale_restore_and_ignores_duplicates() {
    const state = lifecycle();
    state.restore(); session.locked = true;
    state.verified(); state.verified();
    compare(disk.calls, ["read", "clear"]);
    state.cleared(true);
    state.restored(true);
    verify(!session.locked);
    state.cleared(true); state.verified();
    compare(disk.calls, ["read", "clear"]);
  }
}
