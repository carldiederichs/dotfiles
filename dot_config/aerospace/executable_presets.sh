#!/usr/bin/env bash
set -euo pipefail

AEROSPACE="/opt/homebrew/bin/aerospace"
BETTER_DISPLAY="/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay"
DELL_DISPLAY="DELL U4025QW"
DELL_RESOLUTION="3840x1620"
VIRTUAL_DISPLAY="Interview 16:9"
VIRTUAL_RESOLUTION="3840x2160"
STAGING_WORKSPACE="PRESET-STAGING"
UNMATCHED_WORKSPACE="2"
REFERENCE_MONITOR_WIDTH=3840
REFERENCE_LEFT_WIDTH=2550
MIN_AGENT_WIDTH=600
HORIZONTAL_GAP_ALLOWANCE=25
STATE_DIR="${HOME}/.local/state/aerospace-presets"
VIDEO_STATE="${STATE_DIR}/interview-workspace"

notify() {
    local message="${1//\\/\\\\}"
    message="${message//\"/\\\"}"
    /usr/bin/osascript -e "display notification \"${message}\" with title \"AeroSpace Presets\"" >/dev/null 2>&1 || true
}

die() {
    notify "$1"
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

require_executable() {
    [[ -x "$1" ]] || die "Missing executable: $1"
}

focused_workspace() {
    "$AEROSPACE" list-workspaces --focused --format '%{workspace}'
}

focused_monitor_width() {
    local monitor_name

    monitor_name="$("$AEROSPACE" list-monitors --focused --format '%{monitor-name}')"
    [[ -n "$monitor_name" ]] || die "Cannot identify the focused workspace monitor."

    MONITOR_NAME="$monitor_name" /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import("AppKit");
ObjC.import("Foundation");
const monitorName = ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey("MONITOR_NAME"));
const screen = $.NSScreen.screens.js.find(candidate => ObjC.unwrap(candidate.localizedName) === monitorName);
screen ? Math.round(ObjC.unwrap(screen.frame).size.width) : "";
JXA
}

monitor_exists() {
    "$AEROSPACE" list-monitors --format '%{monitor-name}%{newline}' | /usr/bin/grep -Fqx "$1"
}

window_count() {
    "$AEROSPACE" list-windows --workspace "$1" --count
}

is_left_app() {
    case "$1" in
        md.obsidian|\
        com.todesktop.230313mzl4w4u92|\
        com.googlecode.iterm2|\
        com.postmanlabs.mac|\
        com.google.Chrome|\
        com.apple.Safari|\
        com.microsoft.edgemac)
            return 0
            ;;
    esac
    return 1
}

is_right_app() {
    case "$1" in
        com.anthropic.claudefordesktop|\
        com.openai.codex|\
        com.openai.chat)
            return 0
            ;;
    esac
    return 1
}

move_windows_to_workspace() {
    local target="$1"
    shift
    local window_id

    for window_id in "$@"; do
        "$AEROSPACE" move-node-to-workspace --window-id "$window_id" "$target"
    done
}

force_windows_to_tiling() {
    local window_id

    for window_id in "$@"; do
        "$AEROSPACE" layout --window-id "$window_id" tiling || true
    done
}

window_parent_layout() {
    local workspace="$1"
    local window_id="$2"

    "$AEROSPACE" list-windows --workspace "$workspace" \
        --format '%{window-id}%{tab}%{window-parent-container-layout}%{newline}' |
        /usr/bin/awk -F '\t' -v window_id="$window_id" '$1 == window_id { print $2; exit }'
}

absorb_into_right_accordion() {
    local workspace="$1"
    local window_id="$2"
    local max_attempts="$3"
    local attempt

    for (( attempt = 0; attempt < max_attempts; attempt++ )); do
        if [[ "$(window_parent_layout "$workspace" "$window_id")" == "v_accordion" ]]; then
            return 0
        fi
        "$AEROSPACE" move --window-id "$window_id" right || true
        /bin/sleep 0.05
    done
    [[ "$(window_parent_layout "$workspace" "$window_id")" == "v_accordion" ]]
}

group_as_vertical_accordion() {
    local workspace="$1"
    shift
    local -a window_ids=("$@")
    local index
    local last_index
    local seed_index
    local max_attempts
    local window_id

    if (( ${#window_ids[@]} < 2 )); then
        return
    fi

    last_index=$(( ${#window_ids[@]} - 1 ))
    seed_index=$(( last_index - 1 ))
    max_attempts=$(( ${#window_ids[@]} + 1 ))
    "$AEROSPACE" join-with --window-id "${window_ids[$seed_index]}" right
    "$AEROSPACE" layout --window-id "${window_ids[$seed_index]}" v_accordion

    for (( index = seed_index - 1; index >= 0; index-- )); do
        absorb_into_right_accordion "$workspace" "${window_ids[$index]}" "$max_attempts" ||
            die "Could not build a vertical accordion on workspace $workspace."
    done

    for window_id in "${window_ids[@]}"; do
        [[ "$(window_parent_layout "$workspace" "$window_id")" == "v_accordion" ]] ||
            die "Could not verify a vertical accordion on workspace $workspace."
    done
}

layout_preset() {
    local dry_run="${1:-}"
    local workspace
    local window_id
    local bundle_id
    local window_workspace
    local monitor_width
    local left_width
    local max_left_width
    local -a left_windows=()
    local -a right_windows=()
    local -a unmatched_windows=()

    require_executable "$AEROSPACE"
    workspace="$(focused_workspace)"
    monitor_width="$(focused_monitor_width)"
    [[ "$monitor_width" =~ ^[0-9]+$ ]] || die "Cannot read the focused workspace monitor width."
    left_width=$(( monitor_width * REFERENCE_LEFT_WIDTH / REFERENCE_MONITOR_WIDTH ))
    max_left_width=$(( monitor_width - MIN_AGENT_WIDTH - HORIZONTAL_GAP_ALLOWANCE ))
    if (( left_width > max_left_width )); then
        left_width="$max_left_width"
    fi
    (( left_width > 0 )) || die "Focused workspace monitor is too narrow for the preset."

    [[ "$workspace" != "$UNMATCHED_WORKSPACE" ]] || die "Workspace 2 is reserved for unmatched windows. Run the preset from another workspace."
    [[ "$(window_count "$STAGING_WORKSPACE")" == "0" ]] || die "Reserved staging workspace is not empty: $STAGING_WORKSPACE"

    while IFS=$'\t' read -r window_id bundle_id window_workspace; do
        [[ -n "$window_id" ]] || continue
        if is_left_app "$bundle_id"; then
            left_windows+=("$window_id")
        elif is_right_app "$bundle_id"; then
            right_windows+=("$window_id")
        else
            unmatched_windows+=("$window_id")
        fi
    done < <("$AEROSPACE" list-windows --workspace "$workspace" --format '%{window-id}%{tab}%{app-bundle-id}%{tab}%{workspace}%{newline}')

    printf 'Workspace: %s\n' "$workspace"
    printf 'Left accordion: %s\n' "${left_windows[*]:-(none)}"
    printf 'Right accordion: %s\n' "${right_windows[*]:-(none)}"
    printf 'Move to workspace %s: %s\n' "$UNMATCHED_WORKSPACE" "${unmatched_windows[*]:-(none)}"
    printf 'Left width: %s (scaled for %s-wide monitor)\n' "$left_width" "$monitor_width"

    if [[ "$dry_run" == "--dry-run" ]]; then
        return 0
    fi
    (( ${#left_windows[@]} > 0 )) || die "No left-side work windows found on workspace $workspace."
    (( ${#right_windows[@]} > 0 )) || die "No right-side agent windows found on workspace $workspace."

    move_windows_to_workspace "$STAGING_WORKSPACE" "${left_windows[@]}" "${right_windows[@]}"
    if (( ${#unmatched_windows[@]} > 0 )); then
        move_windows_to_workspace "$UNMATCHED_WORKSPACE" "${unmatched_windows[@]}"
    fi

    move_windows_to_workspace "$workspace" "${left_windows[@]}" "${right_windows[@]}"
    # AeroSpace applies the moves asynchronously. Let the rebuilt tree settle before directional joins.
    /bin/sleep 0.2
    "$AEROSPACE" workspace "$workspace" || true
    force_windows_to_tiling "${left_windows[@]}" "${right_windows[@]}"
    "$AEROSPACE" flatten-workspace-tree --workspace "$workspace"
    "$AEROSPACE" layout --window-id "${left_windows[0]}" h_tiles || true

    group_as_vertical_accordion "$workspace" "${left_windows[@]}"
    group_as_vertical_accordion "$workspace" "${right_windows[@]}"
    "$AEROSPACE" balance-sizes --workspace "$workspace"
    "$AEROSPACE" resize --window-id "${left_windows[0]}" width "$left_width"
    "$AEROSPACE" focus --window-id "${left_windows[0]}"

    notify "Applied the two-thirds work and one-third agent layout on workspace $workspace."
}

bd_get() {
    "$BETTER_DISPLAY" get "-name=$1" "-$2" 2>/dev/null
}

bd_get_global() {
    "$BETTER_DISPLAY" get "-$1" 2>/dev/null
}

bd_run() {
    local output

    output="$("$BETTER_DISPLAY" "$@" 2>&1)" || die "BetterDisplay command failed: $*"
    [[ "$output" != *"Failed."* ]] || die "BetterDisplay rejected command: $*"
}

bd_set_virtual() {
    bd_run set "-name=$VIRTUAL_DISPLAY" "$@"
}

virtual_display_exists() {
    "$BETTER_DISPLAY" get "-name=$VIRTUAL_DISPLAY" -identifiers >/dev/null 2>&1
}

virtual_display_connected() {
    [[ "$(bd_get "$VIRTUAL_DISPLAY" connected 2>/dev/null || true)" == *"on"* ]]
}

virtual_pip_enabled() {
    [[ "$(bd_get "$VIRTUAL_DISPLAY" pip 2>/dev/null || true)" == "on" ]]
}

guard_dell_mode() {
    local resolution
    local refresh_rate

    resolution="$(bd_get "$DELL_DISPLAY" resolution)" || die "Cannot read the Dell display resolution."
    refresh_rate="$(bd_get "$DELL_DISPLAY" refreshRate)" || die "Cannot read the Dell display refresh rate."

    [[ "$resolution" == "$DELL_RESOLUTION" ]] || die "Dell resolution changed: expected $DELL_RESOLUTION, found $resolution."
    [[ "$refresh_rate" == "100Hz" || "$refresh_rate" == "109.99Hz" ]] || die "Dell refresh rate changed: expected 100Hz or 109.99Hz, found $refresh_rate."
}

wait_for_aerospace_monitor() {
    local monitor_name="$1"
    local expected="$2"
    local attempt

    for (( attempt = 0; attempt < 30; attempt++ )); do
        if [[ "$expected" == "present" ]] && monitor_exists "$monitor_name"; then
            return 0
        fi
        if [[ "$expected" == "absent" ]] && ! monitor_exists "$monitor_name"; then
            return 0
        fi
        /bin/sleep 0.2
    done
    return 1
}

enable_video_mode() {
    local workspace

    workspace="$(focused_workspace)"
    /bin/mkdir -p "$STATE_DIR"
    printf '%s\n' "$workspace" > "$VIDEO_STATE"

    if ! virtual_display_exists; then
        bd_run create \
            -type=VirtualScreen \
            "-virtualScreenName=$VIRTUAL_DISPLAY" \
            -useResolutionList=on \
            "-resolutionList=$VIRTUAL_RESOLUTION" \
            -virtualScreenHiDPI=on
    fi

    if ! virtual_display_connected; then
        bd_set_virtual -connected=on
    fi
    wait_for_aerospace_monitor "$VIRTUAL_DISPLAY" present || die "AeroSpace did not detect the Interview 16:9 virtual screen."
    if [[ "$(bd_get "$VIRTUAL_DISPLAY" resolution)" != *"$VIRTUAL_RESOLUTION"* ]]; then
        bd_set_virtual "-resolution=$VIRTUAL_RESOLUTION"
    fi
    if ! virtual_pip_enabled; then
        bd_set_virtual -pip=on "-targetName=$DELL_DISPLAY"
    fi
    bd_set_virtual \
        -pip \
        "-targetName=$DELL_DISPLAY" \
        -freeAspect=on \
        -originX=0.1625 \
        -originY=0.05 \
        -width=0.675 \
        -height=0.9 \
        -priority=topmost \
        -unmovable=on \
        -showTitlebar=off \
        -showShadow=off

    "$AEROSPACE" move-workspace-to-monitor --workspace "$workspace" "$VIRTUAL_DISPLAY"
    "$AEROSPACE" workspace "$workspace"
    guard_dell_mode
    notify "Interview mode enabled. Share the Interview 16:9 screen in your meeting app."
}

disable_video_mode() {
    local workspace=""

    if [[ -f "$VIDEO_STATE" ]]; then
        workspace="$(<"$VIDEO_STATE")"
    fi

    if virtual_display_exists; then
        if virtual_pip_enabled; then
            bd_set_virtual -pip=off
        fi
        if [[ -n "$workspace" ]] && monitor_exists "$VIRTUAL_DISPLAY"; then
            "$AEROSPACE" move-workspace-to-monitor --workspace "$workspace" "$DELL_DISPLAY" || true
        fi
        if virtual_display_connected; then
            bd_set_virtual -connected=off
        fi
        wait_for_aerospace_monitor "$VIRTUAL_DISPLAY" absent || die "AeroSpace still detects the Interview 16:9 virtual screen."
    fi

    /bin/rm -f "$VIDEO_STATE"
    if [[ -n "$workspace" ]]; then
        "$AEROSPACE" workspace "$workspace" || true
    fi
    guard_dell_mode
    notify "Interview mode disabled. The Dell remains at $DELL_RESOLUTION with a verified refresh profile."
}

video_toggle() {
    require_executable "$AEROSPACE"
    require_executable "$BETTER_DISPLAY"
    [[ "$(bd_get_global proAvailable)" == "on" ]] || die "BetterDisplay Pro is required for interview mode."
    guard_dell_mode

    if [[ -f "$VIDEO_STATE" ]]; then
        disable_video_mode
    else
        enable_video_mode
    fi
}

case "${1:-}" in
    layout)
        layout_preset "${2:-}"
        ;;
    video-toggle)
        video_toggle
        ;;
    *)
        printf 'Usage: %s {layout [--dry-run]|video-toggle}\n' "$0" >&2
        exit 2
        ;;
esac
