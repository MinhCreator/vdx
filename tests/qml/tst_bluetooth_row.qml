import QtQuick
import QtTest
import qs.kit

TestCase {
  name: "BluetoothRow"
  when: windowShown
  width: 360
  height: 100
  visible: true

  TestBluetoothRow {
    id: row
    width: 300
    modelData: ({mac: "fixture-device", name: "Test headset", icon: "audio-headset",
                 connected: false, paired: true, battery: null})
  }

  function init() {
    TestBluetoothService.powered = true;
    TestBluetoothService.busyMac = "";
    TestBluetoothService.calls = [];
    row.forceActiveFocus();
  }

  function test_keyboard_and_mouse_activate_device() {
    verify(row.activeFocus);
    keyClick(Qt.Key_Space);
    keyClick(Qt.Key_Return);
    mouseClick(row, 20, 15);
    compare(TestBluetoothService.calls.length, 3);
    compare(TestBluetoothService.calls[0], "fixture-device");
  }

  function test_other_device_busy_or_power_off_prevents_activation() {
    TestBluetoothService.busyMac = "other-fixture-device";
    compare(row.enabled, false);
    row.activate();
    mouseClick(row, 20, 15);
    compare(TestBluetoothService.calls.length, 0);
    TestBluetoothService.busyMac = "";
    TestBluetoothService.powered = false;
    row.activate();
    compare(TestBluetoothService.calls.length, 0);
  }
}
