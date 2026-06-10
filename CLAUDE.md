# Claude Code guide for this repo

This is a **chezmoi source directory** for Carl's dotfiles. It is **public** on GitHub with `autoCommit + autoPush` enabled — anything committed here is published immediately.

## Hard rules

1. **Never add files containing secrets or machine state.** Specifically never: `~/.ssh/id_*`, `~/.netrc`, `~/.aws/**`, `~/.kube/**`, `~/.config/gh/hosts.yml`, `~/.codex/auth.json`, `~/.codex/config.toml` (mixes prefs with personal-path state), `~/.claude.json`, `~/.claude/history*`, anything under `~/Library` except the Cursor/Code `User/settings.json`/`keybindings.json` already managed.
2. **Never run `chezmoi apply` without showing the user `chezmoi diff` first.**
3. Personal content (Claude skills, Codex AGENTS.md) belongs in the separate **private** repo `carldiederichs/dotfiles-private`, never here.
4. The gitleaks pre-commit hook must stay enabled (`git config core.hooksPath .githooks`).

## Common tasks

- **"Finish my setup" on a new machine** → walk the user through `DAY1.md`, step by step, running the commands that are safe to run and prompting them for the interactive sign-ins.
- **Add a new app** → edit `dot_Brewfile.tmpl` (decide: all machines, or personal-only block), then `chezmoi apply` (the brew-bundle script re-runs on Brewfile changes).
- **Add a new dotfile** → `chezmoi add <path>`, review what landed in the source, check it for secrets before it auto-pushes.
- **Sync** → `czu` (pull+apply), `czr` (absorb local edits), `cze <file>` (edit managed file). Defined in `dot_config/zsh/aliases.zsh`.

## Architecture notes

- Machine profiles: `.chezmoi.toml.tmpl` prompts for `machine` (personal/work) and `email`; `dot_Brewfile.tmpl` and `dot_gitconfig.tmpl` template on them.
- Scripts in `.chezmoiscripts/` run in filename order: CLT → Homebrew → (files applied) → brew bundle → oh-my-zsh → node/nvm → iTerm2 prefs → Cursor extensions → git hooks.
- p10k and zsh-syntax-highlighting come from Homebrew formulae, not vendored clones.
- iTerm2 reads prefs from `~/.config/iterm2` via `PrefsCustomFolder` (set by script 50).
- CI (`.github/workflows/ci.yml`) runs the real bootstrap on a macOS runner for every push; keep it green.
- Machine-local escape hatches: `~/.zshrc.local`, `~/.gitconfig.local` (both sourced/included, both unmanaged).
