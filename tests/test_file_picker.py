"""The file picker is a window of its own with its own FilesState, apart from the file manager's."""
import re
import unittest
from pathlib import Path

FILES = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/apps/files"
# what may still name the browser's singleton: the window, the settings page, the picker's request relay
SINGLETON_USERS = {"FilesService.qml", "FilesWindow.qml", "FilesSettings.qml", "FilePickerWindow.qml"}


class FilePicker(unittest.TestCase):
    def test_state_is_an_instance_and_the_service_wraps_one(self):
        self.assertNotIn("pragma Singleton", (FILES / "FilesState.qml").read_text())
        service = (FILES / "FilesService.qml").read_text()
        self.assertIn("pragma Singleton", service)
        self.assertIn("FilesState {", service)

    def test_picker_window_has_its_own_state(self):
        window = (FILES / "FilePickerWindow.qml").read_text()
        self.assertIn("FilesState {", window)
        self.assertIn("svc: chooser", window)
        self.assertIn("onPickAsked", window)

    def test_the_file_manager_does_not_take_picker_requests(self):
        window = (FILES / "FilesWindow.qml").read_text()
        self.assertNotIn("pickRequested", window)
        self.assertNotIn("finishPick", window)
        self.assertNotIn("resizeTo", window)

    def test_the_ui_reads_its_own_state_not_the_singleton(self):
        for path in sorted(FILES.glob("*.qml")):
            if path.name in SINGLETON_USERS:
                continue
            code = re.sub(r"//.*", "", path.read_text())
            self.assertIsNone(re.search(r"\bFilesService\b", code), f"{path.name} names FilesService")


if __name__ == "__main__":
    unittest.main()
