#!/bin/bash
set -euo pipefail

# Point iTerm2 at the chezmoi-managed prefs folder
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
# Save changes back to the custom folder on quit without prompting
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile -bool true
defaults write com.googlecode.iterm2 NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
echo "==> iTerm2 will load preferences from ~/.config/iterm2 (restart iTerm2 to pick up)"
