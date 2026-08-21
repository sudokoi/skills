---
name: setup-skills
description: Reproduces this repo's curated agent-skill setup on a fresh machine (or syncs it between machines). Installs skills from their source repos via the skills CLI, prompting for which agents to support and which skill categories to install (the pick is remembered), and optionally recreates the opencode slash commands. Use when setting up a new machine, restoring or syncing skills, or when asked to "set up my skills", "install my skills", "sync my skills", or "recreate my skill setup".
---

# Setup Skills

Reproduces the personal skill set tracked in this repo. The repo is the source of
truth: `scripts/inventory.tsv` lists every skill, its source repo, and its
category, and `commands/` holds the opencode slash-command wrappers. This skill
runs the skills CLI (`npx skills add …`) against that inventory, so installation
always comes from the upstream repos and is easy to maintain (add/remove one line
to change the set).

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
   repo checkout). Run it with a comma-separated agent list. See
   `install.sh --help` for the flags (`--all`, `--commands`, `--dry-run`):

   ```bash
   bash setup-skills/scripts/install.sh --agents opencode,cursor,codex
   ```

   In a terminal, the installer shows an interactive category tree: each category
   (core, react, kotlin, architecture, process, tooling) is a checkbox row with its
   skills listed beneath and ✓ marks on already-installed ones. Nothing is
   pre-checked on first run; space toggles a whole category, `a` selects all,
   enter installs. The picked categories are remembered in
   `${XDG_CONFIG_HOME:-~/.config}/setup-skills/selection` and pre-checked next
   time. Pass `--all` to skip the picker and install everything (used by CI);
   `--dry-run` prints the full plan without prompting.

   For each selected category the script loops over every agent and installs each
   inventory skill with:

   ```text
   npx skills add <repo> --skill <name> --global --yes --agent <agent>
   ```

4. **Report** which skills were installed and which agents were targeted.

## Idempotency

Re-running is safe. `npx skills add` with `--yes` is non-interactive and overwrites
an already-installed skill without error, so the same command can run on a fresh
machine or to bring an existing machine back in sync. `write-commands.sh` overwrites
the command files in place. The remembered category selection only pre-checks the
tree; every run reconfirms the pick before installing.

## Adding / removing a skill

Edit `scripts/inventory.tsv` (one `<repo> <skill> <category>` triple per line,
`#` for comments; category is one of core, react, kotlin, architecture, process,
tooling) and commit. Re-running this skill on any machine installs the new set.
