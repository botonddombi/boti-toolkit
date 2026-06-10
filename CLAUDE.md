# CLAUDE.md

Personal toolkit repo for Botond (`botonddombi`). Public — never commit secrets, tokens, API keys, or company-internal details (Kamino repo internals stay generic).

## Layout & conventions

- `shell/*.zsh` — one self-contained, sourceable file per helper, with a usage header comment. zsh-specific (watch the `path` tied-variable footgun).
- `SETUP.md` — the machine setup playbook. Every step must be idempotent and in install order.
- `.claude/agents/` — Claude Code agents shipped with the repo.

## Keeping it updated

When a helper changes in `~/.zshrc` or a new tool joins the daily setup, the change belongs here:

1. Helpers live in `shell/` — `.zshrc` only `source`s them. Never let the two drift; edit the repo file, not the zshrc copy.
2. New tool or config step → add it to `SETUP.md` in install order, and teach `setup-guide` to detect it.
3. Verify shell changes with `zsh -n <file>` before committing.

Plain commit messages (`add X`, `fix Y`) — no conventional-commit scopes, no Co-Authored-By trailers.
