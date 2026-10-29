"""Exercise brightness queues with a fake backend and isolated settings."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import shlex
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class BrightnessService(unittest.TestCase):
    def actions(self, setup):
        with tempfile.TemporaryDirectory(prefix="shell-brightness-") as tmp:
            root = Path(tmp)
            for folder in ("modules/brightness", "config", "scripts", "kit"):
                (root / folder).mkdir(parents=True)
            source = (SHELL / "modules/brightness/BrightnessService.qml").read_text()
            # Suppress periodic polling; all actions still use the production processes.
            source = source.replace("running: true", "running: false")
            (root / "modules/brightness/BrightnessService.qml").write_text(source)
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            (root / "config/Paths.qml").write_text(
                'pragma Singleton\nimport QtQuick\nQtObject { readonly property string scriptsDir: '
                + json.dumps(str(root / "scripts")) + ' }\n')
            (root / "modules/brightness/night_light.json").write_text(
                '{"schedule":{"enabled":false,"start":"21:00","end":"07:00"},"presets":[]}')
            log = root / "calls"
            (root / "scripts/brightness.sh").write_text(
                'printf "%s\\n" "$*" >> ' + shlex.quote(str(log)) + '\nsleep 0.06\nprintf \'{"ok":true,"brightness":40}\\n\'\n')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "modules/brightness"
Scope {
  property bool submitted: false
  property int quiet: 0
  Timer {
    interval: 10; running: true; repeat: true
    onTriggered: {
      if (!BrightnessService.ready || BrightnessService.backlightBusy || BrightnessService.applyBusy) return;
      if (!submitted) {
        submitted = true;
        ''' + setup + '''
      } else if (++quiet === 10) {
        console.warn("BRIGHTNESS_DONE"); Qt.quit();
      }
    }
  }
  Timer { interval: 5000; running: true; onTriggered: Qt.quit() }
}
''')
            output = run_quickshell(root)
            self.assertIn("BRIGHTNESS_DONE", output)
            return log.read_text().splitlines()

    def test_latest_absolute_value_supersedes_queued_wheel_steps(self):
        calls = self.actions('''
          BrightnessService.setBrightness(20);
          BrightnessService.stepBrightness(5);
          BrightnessService.setBrightness(80);
        ''')
        self.assertEqual([c for c in calls if not c.startswith("--apply")], ["--set 20", "--set 80"])

    def test_wheel_after_queued_absolute_value_adjusts_that_value(self):
        calls = self.actions('''
          BrightnessService.setBrightness(20);
          BrightnessService.setBrightness(80);
          BrightnessService.stepBrightness(5);
        ''')
        self.assertEqual([c for c in calls if not c.startswith("--apply")], ["--set 20", "--set 85"])

    def test_wheel_steps_are_accumulated_while_process_starts(self):
        calls = self.actions('''
          BrightnessService.stepBrightness(5);
          BrightnessService.stepBrightness(5);
          BrightnessService.stepBrightness(-2);
        ''')
        self.assertEqual([c for c in calls if not c.startswith("--apply")], ["--step +5", "--step +3"])

    def test_apply_runs_again_with_latest_values(self):
        calls = self.actions('''
          BrightnessService.apply();
          BrightnessService.setNight(true);
          BrightnessService.setTemperature(3000);
          BrightnessService.setGamma(75);
          BrightnessService.apply();
        ''')
        self.assertEqual(calls[-1], "--apply 3000 75")
        self.assertEqual(calls.count("--apply 3000 75"), 1)
