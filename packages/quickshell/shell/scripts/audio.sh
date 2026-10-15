#!/usr/bin/env bash
#
# audio.sh — ports of every sink and source, keyed by node name: the active
# one and all of them with their jack state:
#   {"<node.name>": {"port": "Speakers", "type": "Speaker", "active": "analog-output-speaker",
#                    "list": [{"name": "analog-output-speaker", "port": "Speakers",
#                              "type": "Speaker", "available": true}, ...]}, ...}
# Pipewire's Quickshell service doesn't expose ports.

{ pactl -f json list sinks; pactl -f json list sources; } 2>/dev/null |
  jq -cs 'add // []
    | map(. as $node | {key: .name, value: (
        ((.ports[] | select(.name == $node.active_port) | {port: .description, type}) // {})
        + {active: .active_port,
           list: [.ports[] | {name, port: .description, type, available: (.availability != "not available"), unknown: (.availability == "availability unknown")}]})})
    | from_entries'
