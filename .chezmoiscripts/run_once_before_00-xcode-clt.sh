#!/bin/bash
set -euo pipefail

if xcode-select -p >/dev/null 2>&1; then
  exit 0
fi

echo "==> Installing Xcode Command Line Tools..."
# Make the CLT show up in softwareupdate, then install headlessly
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
LABEL=$(softwareupdate -l 2>/dev/null | grep -o 'Label: Command Line Tools.*' | head -1 | sed 's/^Label: //') || true
if [ -n "${LABEL:-}" ]; then
  softwareupdate -i "$LABEL" --verbose
else
  xcode-select --install || true
  echo "==> Finish the Command Line Tools GUI install, then re-run: chezmoi apply"
fi
rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
