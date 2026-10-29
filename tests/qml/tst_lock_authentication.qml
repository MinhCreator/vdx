import QtQuick
import QtTest
import qs.kit

TestCase {
  name: "LockAuthentication"

  QtObject {
    id: context
    property bool canStart: true
    property bool responseRequired: true
    property int starts: 0
    property int aborts: 0
    property var responses: []
    function start() { starts++; return canStart; }
    function abort() { aborts++; }
    function respond(password) { responses = responses.concat([password]); }
  }
  LockAuthentication { id: auth; context: context }
  SignalSpy { id: verified; target: auth; signalName: "verified" }

  function init() {
    auth.locked = false;
    auth.clear();
    context.canStart = true;
    context.responseRequired = true;
    context.starts = context.aborts = 0;
    context.responses = [];
    verified.clear();
  }

  function test_only_locked_nonempty_nonbusy_attempt_can_start() {
    verify(!auth.tryUnlock("sample"));
    auth.locked = true;
    verify(!auth.tryUnlock(""));
    auth.typed = "sample";
    verify(auth.tryUnlock(auth.typed));
    compare(context.starts, 1); verify(auth.busy);
    compare(auth.typed, ""); compare(auth.pending, "sample");
    verify(!auth.tryUnlock("other"));
    compare(context.starts, 1); compare(auth.pending, "sample");
  }

  function test_password_is_consumed_before_responding() {
    auth.locked = true;
    auth.tryUnlock("sample");
    context.responseRequired = false;
    auth.answer(); compare(auth.pending, "sample");
    context.responseRequired = true;
    auth.answer();
    compare(auth.pending, ""); compare(context.responses, ["sample"]);
    auth.answer(); compare(context.responses, ["sample", ""]);
  }

  function test_start_failure_clears_password_and_allows_retry() {
    auth.locked = true;
    context.canStart = false;
    verify(auth.tryUnlock("sample"));
    verify(!auth.busy); compare(auth.pending, ""); compare(auth.typed, "");
    compare(auth.error, "PAM error"); compare(verified.count, 0);
    context.canStart = true;
    verify(auth.tryUnlock("retry"));
    compare(auth.error, ""); verify(auth.busy);
  }

  function test_pam_error_before_prompt_clears_password() {
    auth.locked = true;
    auth.tryUnlock("sample");
    auth.fail();
    verify(!auth.busy); compare(auth.pending, ""); compare(auth.typed, "");
    compare(auth.error, "PAM error"); compare(verified.count, 0);
  }

  function test_failed_completion_clears_password_without_verifying() {
    auth.locked = true;
    auth.tryUnlock("sample");
    auth.complete(false);
    verify(!auth.busy); compare(auth.pending, ""); compare(auth.typed, "");
    compare(auth.error, "Wrong password"); compare(verified.count, 0);
    auth.complete(true); compare(verified.count, 0);
  }

  function test_success_verifies_once_and_clears_password() {
    auth.locked = true;
    auth.tryUnlock("sample");
    auth.complete(true);
    verify(!auth.busy); compare(auth.pending, ""); compare(auth.typed, "");
    compare(auth.error, ""); compare(verified.count, 1);
    auth.complete(true); compare(verified.count, 1);
    auth.fail(); compare(auth.error, "");
  }

  function test_unlock_aborts_attempt_and_ignores_late_callbacks() {
    auth.locked = true;
    auth.tryUnlock("sample");
    auth.locked = false;
    compare(context.aborts, 1); verify(!auth.busy);
    compare(auth.pending, ""); compare(auth.typed, "");
    auth.answer(); compare(context.responses, []);
    auth.complete(true); auth.fail();
    compare(verified.count, 0); compare(auth.error, "");
    auth.locked = true;
    verify(auth.tryUnlock("new attempt"));
  }
}
