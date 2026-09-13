#!/usr/bin/env bash
set -euo pipefail

AEROSPACE="/opt/homebrew/bin/aerospace"
CODEX_BUNDLE_ID="com.openai.codex"

[[ -x "$AEROSPACE" ]] || exit 1
plain_text="$(/usr/bin/pbpaste -Prefer txt)"
[[ "$plain_text" =~ [^[:space:]] ]] || exit 0

codex_window_ids="$("$AEROSPACE" list-windows --monitor all --app-bundle-id "$CODEX_BUNDLE_ID" --format '%{window-id}')"
codex_window_id="${codex_window_ids%%$'\n'*}"
[[ -n "$codex_window_id" ]] || exit 0

# Cursor copies syntax-highlighted HTML alongside the source text. Replace the
# clipboard contents with text only so Codex cannot inherit that styling.
printf '%s' "$plain_text" | /usr/bin/pbcopy

"$AEROSPACE" focus --window-id "$codex_window_id"

/usr/bin/osascript <<'OSA'
tell application "System Events"
    repeat 20 times
        try
            set codexProcess to first application process whose bundle identifier is "com.openai.codex"
            if frontmost of codexProcess then exit repeat
        end try
        delay 0.05
    end repeat

    keystroke "v" using command down
end tell
OSA
