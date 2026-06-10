# Day 1 on a new machine — manual steps

Everything below needs a human (sign-ins, permissions). Work top to bottom; ~30 minutes total.
Tip: open this file and run `claude` inside `chezmoi cd` — Claude Code will walk you through it.

## 0. Sanity check the bootstrap

```sh
chezmoi doctor          # should be all ok/warning, no errors
brew bundle check --global || brew bundle --global --no-upgrade   # retry anything corporate policy blocked
```

## 1. 1Password (do this first — everything else needs passwords)

- Open 1Password.app → sign in to your **personal** account (account key from your phone's 1Password app; works independently of iCloud/Google accounts).
- Install the browser extension when Chrome is up.
- If company policy forbids the app: use https://my.1password.com in the browser instead.

## 2. GitHub

```sh
gh auth login            # github.com, HTTPS, login via browser
ssh-keygen -t ed25519 -C "$(git config user.email)"   # fresh key per machine — never transfer keys
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)"
```

If the employer uses GitHub Enterprise: `gh auth login --hostname github.<company>.com` as well.

## 3. Private overlay (Claude skills, Codex config)

```sh
gh repo clone carldiederichs/dotfiles-private ~/.dotfiles-private
~/.dotfiles-private/install.sh
```

## 4. AI tooling sign-ins

- `claude` → log in (Anthropic account)
- `codex` → log in (OpenAI account)
- Open Cursor once (creates the CLI), then `chezmoi apply` to install its extensions.

## 5. Shell history sync (atuin)

```sh
atuin login -u <username>      # key is in 1Password ("Atuin sync key")
atuin sync
```

(Skip on a work machine if you don't want personal shell history there.)

## 6. iTerm2

- Quit and reopen iTerm2 — it now loads prefs from `~/.config/iterm2`.
- If the font looks wrong: Settings → Profiles → Text → Font → `MesloLGS Nerd Font`.

## 7. macOS permissions (System Settings → Privacy & Security)

- **Accessibility**: AeroSpace, Raycast
- AeroSpace starts at login per its config; grant the prompt on first launch.
- On an MDM-managed Mac these may need IT approval (PPPC profile) — AeroSpace is non-essential for day 1.

## 8. Apps

- Chrome → sign in (work profile on work machine).
- Slack / Notion / Zoom / Teams → sign in (usually company-provisioned via SSO).
- Obsidian → vaults live in `~/code/obsidian/*` (git repos) — clone them if wanted on this machine.
- Docker Desktop → start once, accept license.

## 9. Cloud (work machine: set up fresh, inherit nothing)

```sh
aws configure sso        # if the employer uses AWS
gcloud auth login        # if GCP
```

## 10. Verify

```sh
exec zsh                 # p10k prompt renders with icons
gst                      # oh-my-zsh git plugin works
czd                      # chezmoi clean
```

## Troubleshooting on corporate Macs

| Symptom | Fix |
|---|---|
| Homebrew install fails (no admin) | Ask IT / Self-Service for Homebrew, or untar to `~/homebrew` (officially supported) and add to PATH |
| `curl \| sh` blocked | Download the chezmoi pkg from GitHub Releases manually, then `chezmoi init --apply carldiederichs` |
| TLS errors everywhere (proxy MITM) | IT installs the corp root CA; then `export NODE_EXTRA_CA_CERTS=...`, `git config http.sslCAInfo ...` as needed |
| Casks can't write /Applications | `brew install --cask --appdir=~/Applications <name>`, or use the company app portal versions |
| github.com SSH blocked | Stay on HTTPS (`gh` set it up that way already) |
