# AGENTS.md — Personal Skills Repo

## What this repo is

A version-controlled home for my agent skills — the "skills" equivalent of a dotfiles
repo. The goal: reproduce my exact agent/skill setup on any machine with a single
`setup-skills` skill, instead of hand-installing skills one by one.

## Current state

- Repo exists but is empty (this file is the first thing in it).
- The machine already has a working setup (see "Skill inventory" below) installed
  globally, plus a set of opencode slash commands.
- Nothing here yet packages that setup for reuse. That's the task.

## Immediate task — write the `setup-skills` skill

Create `setup-skills/SKILL.md` (and any helper scripts) that, when invoked by an
agent, reproduces the setup below on a fresh machine. Requirements the user asked for:

- **Agent prompt during install:** the skill must ask which agents to support
  (opencode, claude, cursor, codex, gemini, etc.) rather than hardcoding opencode.
- Install each skill from its source repo via the skills CLI (see below).
- Optionally (re)create the opencode slash commands in `~/.config/opencode/commands/`.
- Idempotent: re-running should not error if a skill is already installed.

Use the exact `npx skills add` invocation shape documented in "Technical reference".
The `--agent <name>` flag accepts a single agent name; to support multiple agents
the skill should loop over the user's chosen list.

## Skill inventory (what "setup" must reproduce)

Skills installed globally, grouped by source repo. All were installed with:

    npx skills add <repo> --skill <name> --global --yes --agent opencode

### Installed in this session (exact source repos confirmed)

| Skill | Source repo |
|---|---|
| design-taste-frontend | leonxlnx/taste-skill |
| agent-browser | vercel-labs/agent-browser |
| codebase-architecture | mblode/agent-skills |
| codebase-design | mattpocock/skills |
| domain-modeling | mattpocock/skills |
| frontend-architecture | sickn33/agentic-awesome-skills |
| vercel-composition-patterns | vercel-labs/agent-skills |
| vercel-react-best-practices | vercel-labs/agent-skills |
| vercel-react-native-skills | vercel-labs/agent-skills |
| tdd | mattpocock/skills |
| bulletproof-react-architecture | aidrecabrera/bulletproof-react-skill |
| shadcn | shadcn/ui |
| diagnosing-bugs | mattpocock/skills |
| code-review | mattpocock/skills |
| kotlin-concurrency-and-flow | chrisbanes/skills |
| kotlin-api-design | chrisbanes/skills |
| kotlin-control-flow | chrisbanes/skills |
| kotlin-tooling-agp9-migration | Kotlin/kotlin-agent-skills |
| find-skills | vercel-labs/skills |
| grill-me | mattpocock/skills |
| improve-codebase-architecture | mattpocock/skills |

### Explicitly out of scope (do not install)

- Cloudflare skills (`agents-sdk`, `cloudflare`, `cloudflare-email-service`,
  `durable-objects`, `sandbox-sdk`, `turnstile-spin`, `web-perf`,
  `workers-best-practices`, `wrangler`) — skip these.
- `chrisbanes/skills` Compose-only / workflow skills (`compose-*`,
  `run-github-project`, `shepherd`, `to-plan`, `using-chrisbanes-skills`) — skip.

## Slash commands inventory

OpenCode custom commands live in `~/.config/opencode/commands/<name>.md` (frontmatter:
`description`, optional `agent`/`model`; body = prompt template; `$ARGUMENTS` =
positional args). Commands currently defined:

`agent-browser`, `agp-migration`, `build-agent`, `bulletproof-react`,
`cloudflare`, `cloudflare-email`, `code-review`, `codebase-architecture`,
`codebase-design`, `composition-patterns`, `design-taste`, `diagnose-bugs`,
`domain-modeling`, `durable-objects`, `find-skill`, `frontend-architecture`,
`grill-me`, `improve-arch`, `kotlin-api`, `kotlin-control-flow`, `kotlin-flow`,
`react-native`, `react-perf`, `sandbox`, `shadcn`, `tdd`, `turnstile`,
`web-perf`, `workers-review`, `wrangler`.

Each command's body is one line: "Load the <skill> skill and <apply it>
[optional $ARGUMENTS]." (A command that merely loads a skill is the supported
bridge — skills themselves are not slash commands.)

## Technical reference

**Where opencode discovers skills** (from https://opencode.ai/docs/skills/):
- Project: `.opencode/skills/<name>/SKILL.md`, `.claude/skills/...`, `.agents/skills/...`
- Global: `~/.config/opencode/skills/...`, `~/.claude/skills/...`, `~/.agents/skills/...`
- Each skill = a folder with a `SKILL.md` whose frontmatter has `name` (lowercase,
  hyphen-separated, must match folder name) and `description` (required).
- Agents load skills via the `skill` tool; there is no native slash-command trigger
  for a skill — hence the wrapper commands above.

**skills.sh CLI** (`npx skills`):
- `npx skills add <owner/repo-or-url> --skill <name>` installs one skill.
- `--global` installs to `~/.agents/skills` (universal) instead of project-local.
- `--yes` skips prompts; `--agent <name>` selects a target agent (e.g. `opencode`,
  `claude`, `cursor`); omit `--agent` for all detected agents.
- Omitting `--skill` shows the repo's available skills interactively.

## Conventions

- One folder per skill; the `setup-skills` skill is itself a normal skill
  (`setup-skills/SKILL.md`).
- Keep `SKILL.md` names lowercase + hyphenated, matching their folder names.
- Do not commit secrets or personal tokens.
- Target audience for this repo: me (React + React Native dev, Kotlin native
  modules, Cloudflare) — but the setup skill should ask, not assume.
