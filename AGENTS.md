# AGENTS.md — Personal Skills Repo

## What this repo is

A version-controlled home for my agent skills — the "skills" equivalent of a
dotfiles repo. It holds two kinds of skills:

- **Self-authored skills** — one top-level `<name>/SKILL.md` folder each:
  - `setup-skills/` — the bootstrap skill that installs everything else on a fresh machine.
  - `commit-style/` — my commit conventions.
  - `github-workflow/` — my GitHub Actions conventions.
- **Third-party skills** — not vendored here; they are listed in
  `setup-skills/scripts/inventory.tsv` and installed from their upstream repos.

## Reproducing the setup

On a fresh machine, install the bootstrap skill and run it:

    npx skills add sudokoi/skills --skill setup-skills --global --yes --agent opencode

`setup-skills` asks which agents to support, then installs every skill listed in
`setup-skills/scripts/inventory.tsv`. See `setup-skills/scripts/install.sh --help`
for the installer flags (`--commands`, `--include-optional`, `--dry-run`).
Re-running is idempotent.

## Adding a custom skill

1. Create `<name>/SKILL.md` — frontmatter `name` (lowercase, hyphenated, matches
   the folder) and a required `description`.
2. Register it in `setup-skills/scripts/inventory.tsv` as `sudokoi/skills <name>`.
3. Run `python3 scripts/validate.py` and `python3 scripts/test_validate.py` to check
   the metadata and the validator itself.
4. Commit following the `commit-style` skill.

## CI

- `.github/workflows/ci.yml` — on every push: `scripts/validate.py` (frontmatter,
  inventory, slash-command references), `scripts/test_validate.py`, a dry-run of the
  installer, plus `bash -n` and `shellcheck` on the scripts.
- `.github/workflows/install.yml` — on `main` and manual dispatch: smoke-tests the
  real install and verifies every planned skill lands in `~/.agents/skills`.

## Conventions

- One folder per skill; a skill is just a `SKILL.md` plus optional helper files.
- Follow the `commit-style` skill for commits and the `github-workflow` skill for
  workflow changes.
- Do not commit secrets or personal tokens.
- Target audience is me (React + React Native, Kotlin native modules, Cloudflare),
  but `setup-skills` should ask rather than assume.

## Technical reference

**Where opencode discovers skills** (https://opencode.ai/docs/skills/):
- Project: `.opencode/skills/<name>/SKILL.md`, `.claude/skills/...`, `.agents/skills/...`
- Global: `~/.config/opencode/skills/...`, `~/.claude/skills/...`, `~/.agents/skills/...`
- Each skill = a folder with a `SKILL.md` whose frontmatter has `name` (lowercase,
  hyphen-separated, must match folder name) and `description` (required).

**skills.sh CLI** (`npx skills`):
- `npx skills add <owner/repo-or-url> --skill <name>` installs one skill.
- `--global` installs to `~/.agents/skills` (universal); `--yes` skips prompts.
- `--agent <name>` selects a target agent (repeat for multiple, or omit for all
  detected agents).
- `--copy` copies instead of symlinking; `--full-depth` finds nested skills.
