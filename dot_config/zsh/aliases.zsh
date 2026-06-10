# ==============================================================================
# Custom Aliases
# ==============================================================================

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# List files
alias ll="ls -la"
alias la="ls -A"

# Git shortcuts (additional to oh-my-zsh git plugin)
alias gs="git status"
alias gp="git pull"
alias gco="git checkout"

# Editor shortcuts
alias zshconfig='chezmoi edit ~/.zshrc --apply'
alias dotfiles='cd "$(chezmoi source-path)" && code .'

# Reload zsh config
alias reload="source ~/.zshrc"

# Chezmoi sync (work <-> personal machines)
alias czu='chezmoi update'        # pull latest dotfiles from GitHub and apply
alias cze='chezmoi edit --apply'  # edit a managed file (auto-commits + pushes)
alias czr='chezmoi re-add'        # absorb in-place changes (auto-commits + pushes)
alias czd='chezmoi diff'          # what would change on apply
alias czs='chezmoi status'

# macOS specific
alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"
alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"
