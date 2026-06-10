# Machine setup playbook

The full dev environment, in install order. Each step is idempotent — safe to re-run on a machine that's partially set up. The `setup-guide` agent (`.claude/agents/setup-guide.md`) walks through this file interactively and checks what's already installed.

## 1. Base tooling

```sh
# Homebrew (if missing)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install git jq gh pnpm
gh auth login            # personal account: botonddombi
```

Node is managed per-project (e.g. kamino-webapp pins Node 24 via `package.json` engines / `.nvmrc`-style tooling). Install whatever the active project needs.

## 2. GPG / SSH (YubiKey)

`.zshrc` wires the GPG agent as the SSH agent:

```sh
export GPG_TTY=$(tty)
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
```

Sound notifications for YubiKey touch: a wrapper script is set as the **global** `gpg.program` so commits play a sound when the key is waiting for touch. Don't mistake the wrapper for a git misconfiguration — it's intentional. (Pairs with Claude Code Notification/Stop hooks for sounds.)

## 3. Claude Code + oh-my-claudecode

1. Install Claude Code (CLI or desktop app).
2. Install [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — add the `omc` marketplace (`/plugin marketplace add Yeachan-Heo/oh-my-claudecode`), then in a Claude Code session say `setup omc` or run `/oh-my-claudecode:omc-setup`. Current setup: plugin + CLI, HUD statusline enabled, teams enabled.
3. MCP servers in use: `codedb` (code intelligence — use it for code search instead of grep), `context7`, `chrome-devtools`, Figma desktop, plus claude.ai connectors (Linear, Slack, Sentry, Mixpanel, …).

## 4. herdr

Terminal-native agent runtime / multiplexer: https://herdr.dev — install per their docs (lands in `~/.local/bin`, which `.zshrc` adds to PATH).

- Worktree checkouts live under `~/.herdr/worktrees/<repo>/<branch-slug>` (config: `[worktrees] directory` in herdr config).
- herdr has **no setup hooks** on worktree creation — that's what `hwt` is for.

## 5. boti-toolkit shell helpers

Clone this repo and source the helpers from `.zshrc`:

```sh
git clone https://github.com/botonddombi/boti-toolkit.git ~/Documents/boti-toolkit
echo 'source "$HOME/Documents/boti-toolkit/shell/hwt.zsh"' >> ~/.zshrc
```

Updating later: `git -C ~/Documents/boti-toolkit pull` — the shell picks up changes on the next new pane (or `source ~/.zshrc`).

## 6. Per-repo notes (kamino-webapp)

- Gitignored env files `.env.local` and `.env.development.local` hold the RPC config (`VITE_APP_CUSTOM_RPC` etc.). Without them the app falls back to Triton and gets 403s on localhost — `hwt` symlinks them into every worktree automatically.
- For near-instant `pnpm install` across worktrees, pnpm's global virtual store helps (`enableGlobalVirtualStore` in `pnpm-workspace.yaml`) — note that file is committed/team-wide.
- VS Code ≥ 1.103 shows all worktrees of an open repo in the Source Control Repositories view, regardless of where the checkouts live. For side-by-side editing use a multi-root workspace.

## Known footguns

- **zsh `path` variable**: lowercase `path` is tied to `$PATH`. Never `local path=...` in a zsh function.
- **git branch namespacing**: a branch `x` can't exist if any `x/...` branch exists (and vice versa).
- **one branch = one worktree**: git refuses to check out the same branch twice; `hwt` spawns numbered twin branches instead.
