#!/usr/bin/env bash
#
# audio.sh — active port of every sink and source, keyed by node name:
#   {"<node.name>": {"port": "Speakers", "type": "Speaker"}, ...}
# Pipewire's Quickshell service doesn't expose ports.

{ pactl -f json list sinks; pactl -f json list sources; } 2>/dev/null |
  jq -cs 'add // []
    | map(. as $node | {key: .name, value: (.ports[] | select(.name == $node.active_port) | {port: .description, type})})
    | from_entries'
