#!/usr/bin/env bash
#
# audio.sh — ports of every sink and source, keyed by node name: the active
# one and all of them with their jack state:
#   {"<node.name>": {"port": "Speakers", "type": "Speaker", "active": "analog-output-speaker",
#                    "list": [{"name": "analog-output-speaker", "port": "Speakers",
#                              "type": "Speaker", "available": true}, ...]}, ...}
# Pipewire's Quickshell service doesn't expose ports.
#   audio.sh --listen   {ok} per change of a card (a jack, a profile), the server
#                       (the default device) or the set of devices; not per volume

if [[ ${1:-} == --listen ]]; then
    ok() { echo '{"ok":true}'; }
    . "${BASH_SOURCE[0]%/*}/listen.sh"
    LISTEN_MATCH="on (card|server)|'(new|remove)' on (sink|source) " listen_to pactl subscribe
    exit 0
fi

{ pactl -f json list sinks; pactl -f json list sources; } 2>/dev/null |
  jq -cs 'add // []
    | map(. as $node | {key: .name, value: (
        ((.ports[] | select(.name == $node.active_port) | {port: .description, type}) // {})
        + {active: .active_port,
           list: [.ports[] | {name, port: .description, type, available: (.availability != "not available"), unknown: (.availability == "availability unknown")}]})})
    | from_entries'
