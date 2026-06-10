#!/bin/bash
set -euo pipefail

export NVM_DIR="$HOME/.nvm"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "==> Installing nvm..."
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)"
fi

. "$NVM_DIR/nvm.sh"

if ! nvm ls 22 >/dev/null 2>&1; then
  echo "==> Installing Node 22..."
  nvm install 22
fi
nvm alias default 22 >/dev/null
nvm use default >/dev/null

corepack enable || true

npm ls -g typescript >/dev/null 2>&1 || npm install -g typescript
npm ls -g @nestjs/cli >/dev/null 2>&1 || npm install -g @nestjs/cli
