#!/bin/sh

action="$1"
name="$2"

# rc 0: $name is the current output device
# rc 255: $name exists but is not the current output device
# rc 1: no output device named $name
status() {
    name="$1"
    active_device_description=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed -n 's/.*node\.description = "\(.*\)"/\1/p')
    if printf '%s\n' "$active_device_description" | grep -q -i -x -F "$name"; then
        exit 0
    fi
    if list | sed 's/^[0-9]*: //' | grep -q -i -x -F "$name"; then
        exit 255
    fi
    exit 1
}

activate() {
    name="$1"
    nodes=$(pw-cli list-objects Node | grep -P -o '(?<=id )\d+(?=,)')
    for node_id in $nodes; do
        node_info=$(pw-cli info "$node_id")
        if ! echo "$node_info" | grep --color=auto -q -i 'media.class = "Audio/Sink"'; then
            continue
        fi
        if echo "$node_info" | grep --color=auto -q -i "node.description = \"${name}\""; then
            wpctl set-default "$node_id"
            exit 0
        fi
    done
    exit 1
}

list() {
    nodes=$(pw-cli list-objects Node | grep -P -o '(?<=id )\d+(?=,)')
    for node_id in $nodes; do
        node_info=$(pw-cli info "$node_id")
        if ! echo "$node_info" | grep --color=auto -q -i 'media.class = "Audio/Sink"'; then
            continue
        fi
        node_description=$(echo "$node_info" | sed -n 's/.*node\.description = "\(.*\)"/\1/p')
        echo "${node_id}: ${node_description}"
    done
}

case "$action" in
    "status")
        status "$name"
        ;;
    "set")
        activate "$name"
        ;;
    "list")
        list
        ;;
    *)
        echo "Invalid action" >&2
        exit 1
esac
