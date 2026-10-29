#!/usr/bin/env python3
"""Run the kit's keyboard/layout tests without opening desktop windows.

Requires qt6-declarative (qmltestrunner). Quickshell embeds its plugins, so
this harness supplies a plain clipped rectangle for ClippingRectangle and
replaces the Motion singleton's container. It tests interaction and tokens;
live Quickshell is still needed to verify GPU clipping and window behaviour.
Layout functions use a memory-only store. No real settings or desktop state
are accessed.
"""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
SHELL = ROOT / "packages/quickshell/shell"


def qml_function(source, name):
    """Extract a production function for a host without system side effects."""
    start = source.index("  function " + name + "(")
    brace = source.index("{", start)
    depth, end = 1, brace + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


def main():
    runner = shutil.which("qmltestrunner") or "/usr/lib/qt6/bin/qmltestrunner"
    with tempfile.TemporaryDirectory(prefix="shell-ui-") as tmp:
        work = Path(tmp)
        config = work / "qs/config"
        config.mkdir(parents=True)
        shutil.copytree(SHELL / "kit", work / "qs/kit")
        shutil.copy(SHELL / "apps/shellmanager/EntryList.qml", work / "qs/kit/EntryList.qml")
        shutil.copy(SHELL / "apps/shellmanager/BarArrangement.qml", work / "qs/kit/BarArrangement.qml")
        for name in ("Theme.qml", "Motion.qml"):
            text = (SHELL / "config" / name).read_text()
            text = text.replace("import Quickshell\n", "").replace("Singleton {", "QtObject {")
            (config / name).write_text(text)
        shutil.copy(ROOT / "themes/gruvbox/quickshell/shell/config/Colors.qml", config / "Colors.qml")
        settings = (SHELL / "config/ShellState.qml").read_text()
        settings = settings.replace("import Quickshell.Io", "").replace("JsonAdapter {", "QtObject {")
        # Exercise the production named-shape accessors against isolated settings.
        source = (SHELL / "config/ShellSettings.qml").read_text()
        start = source.index("  readonly property var lookDefaults:")
        end = source.index("\n  // animations", start)
        look_defaults = source[start:end]
        settings = settings.replace("QtObject {", "QtObject {\n  id: state\n" + look_defaults + "\n" + qml_function(source, "look") + "\n" + qml_function(source, "setLook"), 1)
        (config / "ShellSettings.qml").write_text("pragma Singleton\n" + settings)
        # The real selection model has no portal, filesystem or process dependencies.
        shutil.copy(SHELL / "apps/files/FilesSelection.qml", work / "qs/kit/FilesSelection.qml")
        shutil.copy(SHELL / "apps/files/FilesHistory.qml", work / "qs/kit/FilesHistory.qml")
        files = (SHELL / "apps/files/FilesService.qml").read_text()
        (work / "qs/kit/TestFileCreation.qml").write_text(
            'import QtQuick\nQtObject {\nproperty var calls: []\nproperty var history: []\n'
            'function act(request, args) { calls = calls.concat([{request: request, args: args}]); }\n'
            'function record(entry) { history = history.concat([entry]); }\n'
            + qml_function(files, "createNew") + '\n}\n')
        # Layout logic uses its production functions with a memory-only store.
        bar = work / "qs/bar"
        bar.mkdir()
        layout = (SHELL / "bar/BarLayout.qml").read_text().split("  // written by `./install.py link`;")[0]
        layout = layout.replace("import Quickshell\n", "import TestQuickshell\n").replace("import Quickshell.Io\n", "").replace("Singleton {", "QtObject {")
        # Popup IPC is outside these memory-only layout tests.
        layout = layout.replace("import qs.components\n", "")
        layout += """  property QtObject store: QtObject {
          id: state
          property var zones: null
          property var hidden: []
          property var screens: ({})
          property bool shared: false
          property string main: ""
        }
        }
"""
        (bar / "BarLayout.qml").write_text(layout)
        fake = work / "TestQuickshell"
        fake.mkdir()
        (fake / "qmldir").write_text("module TestQuickshell\nsingleton Quickshell 1.0 Quickshell.qml\n")
        (fake / "Quickshell.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject { property var screens: [{name: "HDMI-A-1"}, {name: "eDP-1"}] }\n')
        (config / "ModuleSettings.qml").write_text('pragma Singleton\nimport QtQuick\nQtObject { function get(module, key, fallback) { return fallback; } }\n')
        state_file = config / "ShellSettings.qml"
        state_file.write_text(state_file.read_text().replace("id: state", "id: state\n  function set(key, value) { state[key] = value; }", 1))
        for folder in (config, work / "qs/kit", bar):
            entries = ["module qs." + folder.name]
            for file in sorted(folder.glob("*.qml")):
                prefix = "singleton " if "pragma Singleton" in file.read_text() else ""
                entries.append(f"{prefix}{file.stem} 1.0 {file.name}")
            (folder / "qmldir").write_text("\n".join(entries) + "\n")
        widgets = work / "Quickshell/Widgets"
        widgets.mkdir(parents=True)
        (widgets / "qmldir").write_text("module Quickshell.Widgets\nClippingRectangle 1.0 ClippingRectangle.qml\n")
        (widgets / "ClippingRectangle.qml").write_text("import QtQuick\nRectangle { clip: true }\n")
        shutil.copy(ROOT / "tests/qml/tst_shell_controls.qml", work)
        env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
        return subprocess.run([runner, "-input", tmp, "-import", tmp], env=env).returncode


if __name__ == "__main__":
    raise SystemExit(main())
