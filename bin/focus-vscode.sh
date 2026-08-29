#!/bin/bash -eu

# Preferred projects to focus first (partial substrings of the VS Code window title)
PROJECTS=(
    "AppExplorer"
)
# Match current environment's VS Code title pattern
PROJECTS=( "${PROJECTS[@]/%/" - Visual Studio Code"}" )

# Build an ordered list of VS Code windows: first those matching PROJECTS (in order), then all others
focus_vscode_next() {
    # Capture all normal windows from i3
    local windows json_lines
    windows=$(i3-msg -t get_tree | jq '.. | select(.window_type? == "normal") | { name, window }')

    # Extract VS Code windows as lines: "<id>\t<name>"
    mapfile -t CODE_WIN_LINES < <(echo "$windows" | jq -r 'select(.name? and (.name | contains("Visual Studio Code"))) | "\(.window)\t\(.name)"')

    # If none, bail out
    if [ ${#CODE_WIN_LINES[@]} -eq 0 ]; then
        echo "No VS Code windows found."
        exit 1
    fi

    declare -a ORDERED_IDS=()
    declare -a ORDERED_NAMES=()
    declare -A INCLUDED=()

    # Helper to append a window if not already included
    append_if_not_included() {
        local line="$1"
        local id name
        id=${line%%$'\t'*}
        name=${line#*$'\t'}
        if [ -z "${INCLUDED[$id]:-}" ]; then
            ORDERED_IDS+=("$id")
            ORDERED_NAMES+=("$name")
            INCLUDED[$id]=1
        fi
    }

    # 1) Add windows that match preferred PROJECTS order
    local project
    for project in "${PROJECTS[@]}"; do
        local line
        for line in "${CODE_WIN_LINES[@]}"; do
            local name=${line#*$'\t'}
            if [[ "$name" == *"$project"* ]]; then
                append_if_not_included "$line"
                break
            fi
        done
    done

    # 2) Append any remaining VS Code windows (not in PROJECTS)
    local line
    for line in "${CODE_WIN_LINES[@]}"; do
        append_if_not_included "$line"
    done

    # Determine current focus and choose next window cyclically
    local current_id=$(xdotool getwindowfocus)
    local idx=-1
    local i
    for (( i=0; i<${#ORDERED_IDS[@]}; i++ )); do
        if [ "${ORDERED_IDS[$i]}" = "$current_id" ]; then
            idx=$i
            break
        fi
    done

    local next_index
    if [ $idx -ge 0 ]; then
        next_index=$(( (idx + 1) % ${#ORDERED_IDS[@]} ))
    else
        next_index=0
    fi

    local target_id=${ORDERED_IDS[$next_index]}
    echo "Focusing VS Code window [id=$target_id] ${ORDERED_NAMES[$next_index]}"
    i3-msg "[id=$target_id] focus" > /dev/null
}

focus_vscode_next
