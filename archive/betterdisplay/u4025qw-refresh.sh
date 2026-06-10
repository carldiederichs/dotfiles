#!/usr/bin/env bash
set -euo pipefail

BETTER_DISPLAY="/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay"
DISPLAY_NAME="DELL U4025QW"
EXPECTED_RESOLUTION="3840x1620"
EXPECTED_HIDPI="on"
MODE_100="1660842599752930304"
MODE_110="1661194502529618944"
QUALITY_100="5120x2160 99.99Hz Fixed 10bit SDR RGB Full SRGB"
QUALITY_110="5120x2160 109.99Hz Fixed 10bit SDR RGB Full SRGB"

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

bd_get() {
    "$BETTER_DISPLAY" get "-name=$DISPLAY_NAME" "-$1" 2>/dev/null
}

bd_set_connection_mode() {
    "$BETTER_DISPLAY" set "-name=$DISPLAY_NAME" "-connectionMode=$1" >/dev/null
}

status() {
    printf 'resolution=%s\n' "$(bd_get resolution)"
    printf 'refresh=%s\n' "$(bd_get refreshRate)"
    printf 'hidpi=%s\n' "$(bd_get hiDPI)"
    printf 'connection=%s\n' "$(bd_get connectionMode)"
}

validate_mode() {
    local expected_refresh="$1"
    local expected_quality="$2"
    local resolution
    local refresh
    local hidpi
    local connection

    resolution="$(bd_get resolution)"
    refresh="$(bd_get refreshRate)"
    hidpi="$(bd_get hiDPI)"
    connection="$(bd_get connectionMode)"

    [[ "$resolution" == "$EXPECTED_RESOLUTION" ]] || return 1
    [[ "$refresh" == "$expected_refresh" ]] || return 1
    [[ "$hidpi" == "$EXPECTED_HIDPI" ]] || return 1
    [[ "$connection" == *"$expected_quality"* ]] || return 1
}

restore_100() {
    bd_set_connection_mode "$MODE_100" || true
    /bin/sleep 3
}

switch_profile() {
    local mode_id="$1"
    local expected_refresh="$2"
    local expected_quality="$3"

    bd_set_connection_mode "$mode_id"
    /bin/sleep 3
    if ! validate_mode "$expected_refresh" "$expected_quality"; then
        restore_100
        die "Mode validation failed. Restored the 100 Hz full-quality profile."
    fi
    status
}

[[ -x "$BETTER_DISPLAY" ]] || die "BetterDisplay is not installed at $BETTER_DISPLAY."

case "${1:-}" in
    100)
        switch_profile "$MODE_100" "100Hz" "$QUALITY_100"
        ;;
    110)
        switch_profile "$MODE_110" "109.99Hz" "$QUALITY_110"
        ;;
    120)
        die "A quality-preserving 120 Hz mode is not advertised for this Dell U4025QW and M1 Pro connection. Use 110 Hz."
        ;;
    status)
        status
        ;;
    *)
        printf 'Usage: %s {status|100|110|120}\n' "$0" >&2
        exit 2
        ;;
esac
