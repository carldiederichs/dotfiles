# dotfiles

Carl's macOS setup, managed with [chezmoi](https://www.chezmoi.io). One command bootstraps a fresh Mac — including a locked-down corporate machine — with shell, terminal, window manager, editors, and AI tooling.

## New machine — one command

```sh
sh -c "$(curl -fsSL get.chezmoi.io)" -- init --apply carldiederichs
```

What happens:

1. chezmoi installs itself to `~/.local/bin` (no admin rights needed) and clones this repo.
2. **Two prompts**: `machine` (`personal`/`work`) and git `email`. Answer and walk away.
3. Xcode Command Line Tools and Homebrew install (one `sudo` password prompt, within the first minutes).
4. Everything else runs unattended (~30–45 min): all dotfiles, `~/.Brewfile` packages and apps (iTerm2, AeroSpace, Cursor, Claude Code, Codex, Chrome, Obsidian, Notion, Slack, 1Password, fonts, …), Oh My Zsh, Node via nvm, iTerm2 prefs wiring.
5. When it's done, open iTerm2 and follow [DAY1.md](DAY1.md) for the sign-ins that can't be automated. Or run `claude` in `chezmoi cd` and say **"finish my setup"**.

## Machine profiles

`machine=work` gets the core toolchain only. `machine=personal` adds personal apps (Spotify, WhatsApp, ExpressVPN, BetterDisplay, ollama, …) via templating in [dot_Brewfile.tmpl](dot_Brewfile.tmpl). Git identity comes from the prompted email. Machine-local extras go in `~/.zshrc.local` and `~/.gitconfig.local` (never committed).

## Keeping machines in sync

Auto-commit and auto-push are enabled — every change to the source state lands on GitHub immediately. Aliases (defined in [dot_config/zsh/aliases.zsh](dot_config/zsh/aliases.zsh)):

| Alias | Does | Use when |
|---|---|---|
| `cze <file>` | `chezmoi edit --apply` | editing a managed dotfile |
| `czr` | `chezmoi re-add` | an app rewrote its own config (Cursor, Claude settings) |
| `czu` | `chezmoi update` | pulling the other machine's changes |
| `czd` / `czs` | diff / status | checking state |

Daily loop: change something → `czr` → it's on GitHub. Other machine: `czu`.

A gitleaks pre-commit hook (`.githooks/`) blocks secrets from ever being committed.

## What is NOT here (by design)

- SSH keys, cloud credentials, kubeconfigs, tokens — generate or sign in fresh per machine ([DAY1.md](DAY1.md)).
- AWS config, employer-specific anything.
- Claude Code skills / Codex AGENTS.md — personal content lives in a separate **private** overlay repo (`dotfiles-private`), pulled in on day 1 after `gh auth login`.
- App state, caches, session history.

## Layout

- `dot_*` / `private_dot_*` — files applied into `$HOME`
- `Library/...` — Cursor and VS Code settings
- `dot_config/iterm2/` — iTerm2 prefs (loaded via `PrefsCustomFolder`)
- `.chezmoiscripts/` — ordered bootstrap scripts (CLT → Homebrew → bundle → omz → node → iTerm2 → Cursor extensions)
- `archive/` — retired configs (yabai, skhd, BetterDisplay profiles), never applied
- `.github/workflows/ci.yml` — every push runs the real bootstrap on a pristine macOS runner

## Testing

CI bootstraps a fresh macOS runner on every push (work profile) and asserts the result. To dry-run locally without touching `$HOME`:

```sh
chezmoi apply --destination /tmp/test-home --exclude scripts --force
```
