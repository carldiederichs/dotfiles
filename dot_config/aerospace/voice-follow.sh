#!/bin/bash
set -euo pipefail
dir="${HOME}/.config/aerospace"
binary="${dir}/voice-follow"
# Rebuild after restoring the managed source or changing it; never run a partial build.
if [[ ! -x "$binary" || "${dir}/voice-follow.swift" -nt "$binary" ]]; then
    if mkdir "${dir}/.voice-follow-build-lock" 2>/dev/null; then
        tmp="$(mktemp "${dir}/voice-follow.XXXXXX")"
        trap 'rm -f "$tmp"; rmdir "${dir}/.voice-follow-build-lock"' EXIT
        /usr/bin/swiftc "${dir}/voice-follow.swift" -o "$tmp"
        mv "$tmp" "$binary"
    else
        exit 0
    fi
fi
exec "$binary" "$@"
