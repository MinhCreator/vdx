#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["requests"]
# ///
"""Mihomo (Clash Meta) manager."""

import base64
import subprocess
import sys
from pathlib import Path

import requests

SUBSCRIPTIONS = [
    {
        "name": "krusofiya",
        "url": "https://sub.krusofiya.fun/TjFt2zjV-1Y_0fdc",
        "path": Path.home() / ".config/mihomo/providers/krusofiya.yaml",
        "decode": False,
    }
]

HEADERS = {
    "User-Agent": "ClashMeta/2.11.27",
    "x-hwid": "6cbc749b50e64dbaa3d19acff8f9ca1c",
}


# ── Helpers ───────────────────────────────────────────────────────────────────


def decode_base64(data: str) -> str:
    data += "=" * (-len(data) % 4)
    return base64.b64decode(data).decode("utf-8")


def systemd(action: str) -> None:
    try:
        subprocess.run(["systemctl", "--user", action, "mihomo"], check=True)
    except subprocess.CalledProcessError:
        print(f"[!] failed to {action} mihomo")


# ── Commands ──────────────────────────────────────────────────────────────────


def update() -> None:
    for sub in SUBSCRIPTIONS:
        print(f"updating {sub['name']}...")
        try:
            response = requests.get(sub["url"], headers=HEADERS, timeout=15)
            response.raise_for_status()
            content = response.text.strip()
            if sub.get("decode"):
                content = decode_base64(content)
            sub["path"].parent.mkdir(parents=True, exist_ok=True)
            sub["path"].write_text(content, encoding="utf-8")
            print(f"saved to {sub['path']}")
        except Exception as e:
            print(f"[!] {sub['name']}: {e}")


# ── CLI ───────────────────────────────────────────────────────────────────────

COMMANDS = {
    "--start": lambda: systemd("start"),
    "--stop": lambda: systemd("stop"),
    "--restart": lambda: systemd("restart"),
    "--status": lambda: systemd("status"),
    "--update": update,
}


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(f"usage: vpn [ {' | '.join(COMMANDS)} ]")
        sys.exit(1)
    COMMANDS[sys.argv[1]]()


if __name__ == "__main__":
    main()
