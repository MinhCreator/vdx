import QtQuick
import QtTest
import qs.kit

TestCase {
  name: "WifiRow"
  when: windowShown
  width: 360
  height: 100
  visible: true

  TestNetworkRow {
    id: row
    width: 300
    modelData: ({ssid: "fixture-network", secure: true, signal: 80, saved: false})
  }

  function init() {
    TestWifiService.connected = false;
    TestWifiService.radioOn = true;
    TestWifiService.ssid = "";
    TestWifiService.connectingSsid = "";
    TestWifiService.calls = [];
    row.forceActiveFocus();
  }

  function test_keyboard_and_mouse_activate_network() {
    verify(row.activeFocus);
    verify(row.Accessible.name.indexOf("secured network") >= 0);
    keyClick(Qt.Key_Space);
    keyClick(Qt.Key_Return);
    mouseClick(row, 20, 15);
    compare(TestWifiService.calls.length, 3);
    compare(TestWifiService.calls[0], "fixture-network");
  }

  function test_current_connecting_or_off_network_cannot_activate() {
    TestWifiService.connected = true;
    TestWifiService.ssid = "fixture-network";
    compare(row.enabled, false);
    row.activate();
    TestWifiService.connected = false;
    TestWifiService.connectingSsid = "another-network";
    compare(row.enabled, false);
    row.activate();
    TestWifiService.connectingSsid = "";
    TestWifiService.radioOn = false;
    row.activate();
    compare(TestWifiService.calls.length, 0);
  }
}
