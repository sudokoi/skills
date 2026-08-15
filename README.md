# Skills

My personal agent-skill setup, version-controlled so it can be reproduced on any
machine with a single `setup-skills` skill. This is the "skills" equivalent of a
dotfiles repo.

## What's here

- [`setup-skills/`](setup-skills/SKILL.md) — the skill that does the work:
  - [`scripts/inventory.tsv`](setup-skills/scripts/inventory.tsv) — the source of
    truth: one `<repo> <skill>` line per installed skill.
  - [`scripts/install.sh`](setup-skills/scripts/install.sh) — installs every skill
    via the skills CLI for the agents you choose.
  - [`scripts/write-commands.sh`](setup-skills/scripts/write-commands.sh) — writes
    the opencode slash-command wrappers.
  - [`commands/`](setup-skills/commands) — the opencode slash commands themselves.

## Setup on a new machine (or sync)

Install the skill, then run it. It prompts for which agents to support and whether
to write the opencode slash commands.

```bash
npx skills add <this-repo> --skill setup-skills --global --yes --agent opencode
```

Then ask an agent to **Load the `setup-skills` skill and set up my skills**, or run
the installer directly:

```bash
bash setup-skills/scripts/install.sh --agents opencode,cursor,codex --commands
```

`--agents` takes a comma-separated list. Supported names include `opencode`,
`cursor`, `codex`, `claude`, `gemini`, `windsurf`, `zed`, `warp`,
`github-copilot`, and more (the skills CLI knows the full list). `claude` and
`gemini` are mapped to their CLI names `claude-code` and `gemini-cli`.

## Adding or removing a skill

Edit `setup-skills/scripts/inventory.tsv` — add/remove a `<repo> <skill>` line —
then commit and re-run `setup-skills` on each machine. Installation always uses the
skills CLI against the upstream repo:

```text
npx skills add <repo> --skill <name> --global --yes --agent <agent>
```

Re-running is idempotent: the CLI overwrites already-installed skills without error.

## Out of scope

Cloudflare skills and `chrisbanes/skills` Compose/workflow skills are intentionally
not tracked here; they're managed separately.
