# Skills

Just my personal, opinionated set of agent skills. Install `setup-skills` and
it sets up everything else on any machine the same way.

## Setup

```bash
npx skills add sudokoi/skills --skill setup-skills --global --yes --agent opencode
```

Then either ask your agent to load `setup-skills`, or run the installer directly:

```bash
bash setup-skills/scripts/install.sh --agents opencode
```

You get a tree of categories to pick from. Nothing is pre-checked on the first
run; what you pick is remembered (`~/.config/setup-skills/selection`) and
pre-checked next time. `--all` skips the picker, `--dry-run` prints what would
happen, `--commands` also writes the opencode slash commands. Running it again
is safe.

## The inventory

One file decides what exists: `setup-skills/scripts/inventory.tsv`.

```text
<repo> <skill> <category>
```

Categories: `core`, `react`, `kotlin`, `architecture`, `process`, `tooling`.
My own three skills (`setup-skills`, `commit-style`, `github-workflow`) live in
this repo as normal `<name>/SKILL.md` folders and install from the repo itself,
same as everything else.

To change the set, edit the tsv, commit, run `setup-skills` again on each
machine.

## Slash commands

Four, on purpose. Any more and I cannot remember them:

- `/grill-me`
- `/code-review`
- `/tdd`
- `/diagnose-bugs`

Every other skill loads on its own when a task matches its description.
`scripts/write-commands.sh` copies these into `~/.config/opencode/commands/`
and deletes ones removed from the repo.

## Checks

`scripts/validate.py` checks frontmatter, the inventory format, and command
references. `setup-skills/scripts/test_install.sh` covers the installer
contracts. CI runs both with shellcheck, ruff, markdownlint, and an installer
dry-run, on every push.
