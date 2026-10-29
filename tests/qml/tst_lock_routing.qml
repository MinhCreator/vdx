import QtQuick
import QtTest
import qs.config
import qs.kit

TestCase {
  name: "LockRouting"
  Component { id: factory; TestLockRouting {} }
  function init() { ModuleSettings.values = ({}); }

  function test_solid_locks_immediately_without_snapshots() {
    const lock = createTemporaryObject(factory, this);
    lock.lock();
    verify(lock.session.locked);
    compare(lock.snapshots.calls.length, 0);
    lock.lock();
    compare(lock.snapshots.calls.length, 0);
  }

  function test_blur_waits_for_one_preparation() {
    ModuleSettings.values = {"lock/background": "blur"};
    const lock = createTemporaryObject(factory, this);
    lock.lock();
    verify(!lock.session.locked); verify(lock.snapshots.busy);
    compare(lock.snapshots.calls.length, 1);
    compare(lock.snapshots.calls[0].screens, ["HDMI-A-1", "eDP-1"]);
    lock.lock();
    compare(lock.snapshots.calls.length, 1);
    lock.snapshots.busy = false;
    lock.session.locked = true;
    lock.lock(); compare(lock.snapshots.calls.length, 1);
  }

  function test_screen_selection_falls_back_when_target_is_missing() {
    const lock = createTemporaryObject(factory, this);
    verify(lock.shows("HDMI-A-1")); verify(lock.shows("eDP-1"));
    ModuleSettings.values = {"lock/screen": "focused"};
    verify(lock.shows("HDMI-A-1")); verify(!lock.shows("eDP-1"));
    lock.focusedScreen = "disconnected";
    verify(lock.shows("HDMI-A-1")); verify(lock.shows("eDP-1"));
    ModuleSettings.values = {"lock/screen": "eDP-1"};
    verify(!lock.shows("HDMI-A-1")); verify(lock.shows("eDP-1"));
    ModuleSettings.values = {"lock/screen": "missing"};
    verify(lock.shows("HDMI-A-1")); verify(lock.shows("eDP-1"));
  }
}
