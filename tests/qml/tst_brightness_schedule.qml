import QtQuick
import QtTest
import qs.kit

TestCase {
  name: "BrightnessSchedule"
  Component { id: factory; TestBrightnessSchedule {} }
  function at(hour) { return new Date(2026, 0, 1, hour, 0); }

  function test_overnight_boundaries_preserve_manual_override_between_them() {
    const state = createTemporaryObject(factory, this);
    state.checkSchedule(at(22)); verify(state.night);
    state.night = false;
    state.checkSchedule(at(23)); verify(!state.night);
    state.checkSchedule(at(7)); verify(!state.night);
    state.checkSchedule(at(21)); verify(state.night);
  }

  function test_disabling_and_reenabling_rechecks_current_window() {
    const state = createTemporaryObject(factory, this);
    state.checkSchedule(at(22)); verify(state.night);
    state.schedule = {enabled: false, start: "21:00", end: "07:00"};
    state.checkSchedule(at(22)); compare(state.inSchedule, null);
    state.night = false;
    state.schedule = {enabled: true, start: "21:00", end: "07:00"};
    state.checkSchedule(at(22)); verify(state.night);
  }
}
