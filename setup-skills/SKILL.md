---
name: setup-skills
description: Reproduces this repo's curated agent-skill setup on a fresh machine (or syncs it between machines). Installs a fixed list of skills from their source repos via the skills CLI, prompting for which agents to support, and optionally recreates the opencode slash commands. Use when setting up a new machine, restoring or syncing skills, or when asked to "set up my skills", "install my skills", "sync my skills", or "recreate my skill setup".
---

# Setup Skills

Reproduces the personal skill set tracked in this repo. The repo is the source of
truth: `scripts/inventory.tsv` lists every skill and its source repo, and
`commands/` holds the opencode slash-command wrappers. This skill runs the skills
CLI (`npx skills add …`) against that inventory, so installation always comes from
the upstream repos and is easy to maintain (add/remove one line to change the set).

## Steps

1. **Ask which agents to support.** Do not assume opencode. Offer the common ones
   and let the user pick any set:

   - `opencode`, `cursor`, `codex`, `claude`, `gemini`, `windsurf`, `zed`, `warp`, `github-copilot`, …

   Friendly names `claude` and `gemini` are mapped to the CLI names `claude-code`
   and `gemini-cli` by the script. Default to `opencode` if the user has no
   preference.

2. **Ask whether to (re)create the opencode slash commands** (optional). These are
   one-line wrappers in `~/.config/opencode/commands/` that load a skill. Say yes
   only for opencode setups.

3. **Install the skills.** The installer and inventory live in `scripts/`, next to
   this `SKILL.md` (i.e. `<repo>/setup-skills/scripts/install.sh` when using the
   repo checkout). Run it with a comma-separated agent list; ask whether to include
   the optional skills too. See `install.sh --help` for the flags (`--commands`,
   `--include-optional`, `--dry-run`):

   ```bash
   bash setup-skills/scripts/install.sh --agents opencode,cursor,codex
   ```

   The script loops over every agent and installs each recommended inventory skill
   (and the `optional:` ones when `--include-optional` is passed) with:

   ```text
   npx skills add <repo> --skill <name> --global --yes --agent <agent>
   ```

4. **Report** which skills were installed and which agents were targeted.

## Idempotency

Re-running is safe. `npx skills add` with `--yes` is non-interactive and overwrites
an already-installed skill without error, so the same command can run on a fresh
machine or to bring an existing machine back in sync. `write-commands.sh` overwrites
the command files in place.

## Adding / removing a skill

Edit `scripts/inventory.tsv` (one `<repo> <skill>` pair per line, `#` for comments;
prefix a line with `optional:` to make the skill optional) and commit. Re-running
this skill on any machine converges to the new set.
