# hwt — herdr worktree helper (zsh)
#
# hwt <branch> [base]   create/open a herdr worktree for <branch>
#   - branch exists, not checked out anywhere → checks it out in a new worktree
#   - branch exists, already checked out      → spawns a numbered twin branch off it (branch-2, -3, …)
#   - branch doesn't exist                    → new branch off [base] (default origin/master)
#   Then: symlinks gitignored env files (.env.local, .env.development.local) from the
#   main checkout and runs `pnpm install --prefer-offline`.
#
# hwt --nuke            remove ALL linked worktrees of the current repo (with confirmation)
#   Closes herdr workspaces, mv's checkouts to a trash dir (instant), prunes git,
#   deletes files in a detached background job. Never touches branches or the main checkout.
#
# Requires: git, jq, herdr (https://herdr.dev), pnpm.
# Note: variable holding the checkout path must NOT be named `path` — lowercase
# `path` is zsh's tied array for $PATH and assigning it nukes command lookup.

hwt() {
  local branch=$1 base=${2:-origin/master}
  [[ -z $branch ]] && { echo "usage: hwt <branch> [base] | hwt --nuke"; return 1 }
  local repo=$(git rev-parse --show-toplevel) || return 1
  local out

  if [[ $branch == --nuke ]]; then
    local lines=$(herdr worktree list --cwd "$repo" --json |
      jq -r '.result.worktrees[] | select(.is_linked_worktree) | [.open_workspace_id // "-", .path] | @tsv')
    [[ -z $lines ]] && { echo "no linked worktrees"; return 0 }
    echo "$lines" | awk -F'\t' '{print "  " $2}'
    local yn
    read -q "yn?Remove these worktrees (uncommitted changes will be LOST)? [y/N] " || { echo; return 1 }
    echo
    local trash="$HOME/.herdr/worktrees/.trash/$$-$RANDOM"
    mkdir -p "$trash"
    echo "$lines" | while IFS=$'\t' read -r ws p; do
      [[ $PWD == $p* ]] && { echo "⚠ skipping $p (you are inside it)"; continue }
      [[ $ws != - ]] && herdr workspace close "$ws" >/dev/null 2>&1
      mv "$p" "$trash/" && echo "✗ removed $p"
    done
    git -C "$repo" worktree prune
    rm -rf "$trash" &>/dev/null &!
    echo "(file cleanup continues in background)"
    return 0
  fi

  if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
    if git -C "$repo" worktree list --porcelain | grep -qx "branch refs/heads/$branch"; then
      # branch already checked out somewhere: spawn a numbered twin branch off it
      local n=2
      while git -C "$repo" show-ref --verify --quiet "refs/heads/$branch-$n"; do ((n++)); done
      echo "'$branch' already has a checkout → spawning '$branch-$n' off it"
      out=$(herdr worktree create --cwd "$repo" --branch "$branch-$n" --base "$branch" --no-focus --json) || return 1
    else
      # existing local branch, not checked out anywhere: git makes the checkout, herdr adopts it
      local wtdir="$HOME/.herdr/worktrees/$(basename "$repo")/${branch//\//-}"
      git -C "$repo" worktree add "$wtdir" "$branch" || return 1
      out=$(herdr worktree open --cwd "$repo" --path "$wtdir" --no-focus --json) || return 1
    fi
  else
    # new branch off base (default origin/master)
    out=$(herdr worktree create --cwd "$repo" --branch "$branch" --base "$base" --no-focus --json) || return 1
  fi

  local p=$(echo "$out" | jq -r '.result.worktree.path')
  for f in .env.local .env.development.local; do
    [[ -f $repo/$f ]] && ln -sf "$repo/$f" "$p/$f"
  done
  (cd "$p" && pnpm install --prefer-offline) && echo "✓ ready: $p"
}
