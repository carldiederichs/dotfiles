#!/bin/bash
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  exit 0
fi

echo "==> Installing Oh My Zsh..."
# KEEP_ZSHRC=yes is critical: the installer must not clobber the chezmoi-managed ~/.zshrc
RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
