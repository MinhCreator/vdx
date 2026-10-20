#!/usr/bin/env python3
"""files_portal — the file manager's XDG desktop portal backend. It owns
org.freedesktop.impl.portal.desktop.shellfiles and serves FileChooser (open
and save files or folders). xdg-desktop-portal routes to it by
xdg-portal/shellfiles.portal and xdg-portal/hyprland-portals.conf. The URI
opener is xdg-desktop-portal's own (it asks an AppChooser only when no default
program is set): there is no org.freedesktop.impl.portal.OpenURI to serve.
It also serves org.freedesktop.FileManager1 (ShowFolders, ShowItems,
ShowItemProperties): browsers' "show in folder" opens the Files window with the
item selected (`files reveal`), "properties" its panel (`files inspect`).

A FileChooser request opens the Files window as a picker:
`qs -c shell ipc call files choose <request json>`. The answer comes back as
`files.py answer <id> <json>` into $XDG_RUNTIME_DIR/files-portal/<id>.json,
which this script polls for. Started and kept by the shell (FilesService).
"""
import json, mimetypes, os, subprocess, sys, time, uuid
from urllib.parse import quote, unquote

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

BUS = "org.freedesktop.impl.portal.desktop.shellfiles"
PATH = "/org/freedesktop/portal/desktop"
FM_BUS = "org.freedesktop.FileManager1"
FM_PATH = "/org/freedesktop/FileManager1"
RUNTIME = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
ANSWERS = os.path.join(RUNTIME, "files-portal")
HOME = os.path.expanduser("~")
PICK_SECONDS = 15 * 60

XML = """
<node>
  <interface name="org.freedesktop.impl.portal.FileChooser">
    <method name="OpenFile">
      <arg type="o" name="handle" direction="in"/>
      <arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/>
      <arg type="s" name="title" direction="in"/>
      <arg type="a{sv}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/>
      <arg type="a{sv}" name="results" direction="out"/>
    </method>
    <method name="SaveFile">
      <arg type="o" name="handle" direction="in"/>
      <arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/>
      <arg type="s" name="title" direction="in"/>
      <arg type="a{sv}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/>
      <arg type="a{sv}" name="results" direction="out"/>
    </method>
  </interface>
</node>
"""

# portal responses: 0 done, 1 cancelled, 2 failed
DONE, CANCELLED, FAILED = 0, 1, 2


def folder_of(raw):
    """a current_folder option (a NUL-ended byte string) as an existing folder"""
    if raw:
        path = bytes(raw).rstrip(b"\0").decode("utf-8", "replace")
        if os.path.isdir(path):
            return path
    return HOME


def patterns_of(items):
    """a filter's (type, pattern) pairs as the shell matches them: a glob (type 0) and a
    "major/*" mime type as they are, any other mime type ("application/pdf") as the globs of
    its extensions (the shell knows a file's kind, not its mime type); one with no known
    extension adds nothing"""
    out = []
    for kind, pattern in items:
        if kind == 0 or pattern.endswith("/*"):
            out.append(pattern)
        else:
            out += ["*" + ext for ext in mimetypes.guess_all_extensions(pattern)]
    return out


def filters_of(raw, current=None):
    """a(sa(us)) → [{name, patterns}], the app's current filter (sa(us)) first"""
    filters = list(raw or [])
    if current:
        filters = [tuple(current)] + [f for f in filters if f[0] != current[0]]
    return [{"name": label, "patterns": patterns_of(items)} for label, items in filters]


def answer(invocation, response, paths):
    uris = {"uris": GLib.Variant("as", ["file://" + quote(p) for p in paths])} if paths else {}
    invocation.return_value(GLib.Variant("(ua{sv})", (response, uris)))


def choose(invocation, method, title, options):
    request = {
        "id": uuid.uuid4().hex,
        "mode": "save" if method == "SaveFile" else "open",
        "title": title,
        "multiple": bool(options.get("multiple", False)),
        "directory": bool(options.get("directory", False)),
        "filters": filters_of(options.get("filters"), options.get("current_filter")),
        "folder": folder_of(options.get("current_folder")),
        "name": str(options.get("current_name", "")),
    }
    # the shell opens its window; a failed call answers at once, not after a timeout
    try:
        run = subprocess.run(["qs", "-c", "shell", "ipc", "call", "files", "choose", json.dumps(request)],
                             capture_output=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        run = None
    if run is None or run.returncode != 0:
        answer(invocation, FAILED, [])
        return

    result = os.path.join(ANSWERS, request["id"] + ".json")
    deadline = time.monotonic() + PICK_SECONDS

    def poll():
        if time.monotonic() > deadline:                  # the shell never answered (it died, or the window was lost)
            answer(invocation, CANCELLED, [])
            return False
        if not os.path.exists(result):
            return True                                  # keep polling
        try:
            with open(result, encoding="utf-8") as f:
                reply = json.load(f)
            os.remove(result)
            answer(invocation, int(reply.get("response", CANCELLED)), list(reply.get("paths") or []))
        except (OSError, ValueError, TypeError, AttributeError):
            answer(invocation, FAILED, [])               # a damaged answer ends the request, not the backend
        return False                                     # done

    GLib.timeout_add(150, poll)


FM_XML = """
<node>
  <interface name="org.freedesktop.FileManager1">
    <method name="ShowFolders">
      <arg type="as" name="URIs" direction="in"/>
      <arg type="s" name="StartupId" direction="in"/>
    </method>
    <method name="ShowItems">
      <arg type="as" name="URIs" direction="in"/>
      <arg type="s" name="StartupId" direction="in"/>
    </method>
    <method name="ShowItemProperties">
      <arg type="as" name="URIs" direction="in"/>
      <arg type="s" name="StartupId" direction="in"/>
    </method>
  </interface>
</node>
"""


def shell_call(*args):
    """the shell's files IPC; a missing shell is not an error for the caller"""
    try:
        subprocess.run(["qs", "-c", "shell", "ipc", "call", "files", *args], capture_output=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        pass


def handle_file_manager(connection, sender, object_path, interface, method, parameters, invocation, user_data=None):
    uris, _startup = parameters.unpack()
    paths = [unquote(u[len("file://"):]) for u in uris if u.startswith("file://")]
    if paths:
        shell_call("inspect" if method == "ShowItemProperties" else "reveal", paths[0])
    invocation.return_value(None)


def on_file_manager_acquired(connection, name, user_data=None):
    node = Gio.DBusNodeInfo.new_for_xml(FM_XML)
    for info in node.interfaces:
        connection.register_object(FM_PATH, info, handle_file_manager, None, None)


def handle_call(connection, sender, object_path, interface, method, parameters, invocation, user_data=None):
    _handle, _app, _parent, title, options = parameters.unpack()
    choose(invocation, method, title, options)


def on_bus_acquired(connection, name, user_data=None):
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    for info in node.interfaces:
        connection.register_object(PATH, info, handle_call, None, None)


def on_name_lost(connection, name, user_data=None):
    sys.exit(1)                                          # another copy owns the name


def main():
    Gio.bus_own_name(Gio.BusType.SESSION, BUS, Gio.BusNameOwnerFlags.NONE,
                     on_bus_acquired, None, on_name_lost)
    Gio.bus_own_name(Gio.BusType.SESSION, FM_BUS, Gio.BusNameOwnerFlags.NONE,
                     on_file_manager_acquired, None, None)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
