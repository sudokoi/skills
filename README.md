# Skills

My personal agent skills, version-controlled so they can be reproduced on any
machine with a single `setup-skills` skill. This is the "skills" equivalent of a
dotfiles repo: it holds both my own custom skills and the third-party skills I use.

## What's here

- [`setup-skills/`](setup-skills/SKILL.md) — the bootstrap skill that does the work:
  - [`scripts/inventory.tsv`](setup-skills/scripts/inventory.tsv) — the source of
    truth: one `<repo> <skill>` line per installed skill (third-party and self).
  - [`scripts/install.sh`](setup-skills/scripts/install.sh) — installs every skill
    via the skills CLI for the agents you choose.
  - [`scripts/write-commands.sh`](setup-skills/scripts/write-commands.sh) — writes
    the opencode slash-command wrappers.
  - [`commands/`](setup-skills/commands) — the opencode slash commands themselves.
- [`commit-style/`](commit-style/SKILL.md) — my custom commit conventions.

## Custom skills

Custom skills live in this repo as `<name>/SKILL.md` and are installed like any
other skill, with the repo itself as the source. Add them to `inventory.tsv` as
`<owner>/<repo> <skill>` (e.g. `<owner>/<repo> commit-style`) so `setup-skills`
installs them on every machine. `setup-skills` itself is the entry point and stays
out of the inventory.

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
skills CLI against the source repo:

```text
npx skills add <repo> --skill <name> --global --yes --agent <agent>
```

Re-running is idempotent: the CLI overwrites already-installed skills without error.

## Out of scope

Cloudflare skills and `chrisbanes/skills` Compose/workflow skills are intentionally
not tracked here; they're managed separately.
