#!/bin/bash
set -euo pipefail

# Enable the gitleaks pre-commit hook in the chezmoi source repo so that
# autoCommit+autoPush can never push a secret to the public dotfiles repo.
SRC="${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}"
if [ -d "$SRC/.git" ] && [ -d "$SRC/.githooks" ]; then
  git -C "$SRC" config core.hooksPath .githooks
  echo "==> gitleaks pre-commit hook enabled in dotfiles source repo"
fi
