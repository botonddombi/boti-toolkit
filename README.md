# boti-toolkit

Personal dev environment toolkit — shell helpers, machine setup playbook, and a Claude Code agent that walks through installing all of it.

## What's here

| Path | What |
|---|---|
| `shell/hwt.zsh` | `hwt` — herdr worktree helper: create/open worktrees per branch, env symlinks, `pnpm install`, `--nuke` cleanup |
| `SETUP.md` | The full machine setup playbook, in install order |
| `.claude/agents/setup-guide.md` | Claude Code agent that checks what's installed and walks through `SETUP.md` interactively |

## Quick start (new machine)

```sh
git clone https://github.com/botonddombi/boti-toolkit.git ~/Documents/boti-toolkit
echo 'source "$HOME/Documents/boti-toolkit/shell/hwt.zsh"' >> ~/.zshrc
```

Then open Claude Code in this repo and ask it to **"walk me through the setup"** — the `setup-guide` agent takes it from there.

## Updating

`.zshrc` sources the helpers straight from this clone, so:

```sh
git -C ~/Documents/boti-toolkit pull
```

New panes pick the changes up automatically (`source ~/.zshrc` for the current one).

## hwt cheat sheet

```sh
hwt branch-a                  # worktree for existing branch (twin branch-a-2 if already checked out)
hwt boti/new-idea             # new branch off origin/master, in its own worktree
hwt boti/fix origin/dev/2.27  # new branch off a different base
hwt --nuke                    # remove ALL linked worktrees (keeps branches), instant + background cleanup
```
