---
name: github-workflow
description: Conventions for authoring and maintaining GitHub Actions workflows. Pin each action to its latest version, read the Node version from .node-version (else latest LTS), and set up pnpm via the setup-pnpm action instead of corepack. Use when creating a workflow, adding or editing jobs or steps, or updating action versions in an existing workflow.
---

# GitHub Workflows

Rules for writing GitHub Actions workflows for this user.

## Action versions

- Pin every action to its latest major version tag (e.g. `actions/checkout@v7`).
- Find the latest tag at authoring time instead of reusing stale tags from memory:

  ```bash
  gh api repos/OWNER/REPO/releases/latest --jq .tag_name
  ```

- On a major-version bump, check the release notes for breaking changes to inputs.

Current latest, verified 2026-08 (re-check before use):

| Action | Latest |
|---|---|
| actions/checkout | v7 |
| actions/setup-node | v7 |
| actions/setup-python | v7 |
| actions/cache | v6 |
| actions/upload-artifact | v7 |
| actions/download-artifact | v8 |
| pnpm/action-setup | v6 |

## Node version

- If the repo has `.node-version` (or `.nvmrc`), use it via `node-version-file`.
- Otherwise use the latest LTS with `node-version: 'lts/*'`. Never hardcode a
  specific Node version.

## pnpm

- Use the setup-pnpm action (`pnpm/action-setup`) — never `corepack`.
- Do not hardcode a version: `pnpm/action-setup` reads `packageManager` from
  `package.json` automatically.
- If `package.json` has no pnpm version, set `version: latest`.

## Existing workflows

- When asked to update an existing workflow, first list every action with its
  current and latest version, and get the user's confirmation before changing
  anything.

## Example

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - uses: pnpm/action-setup@v6
        # version is read from package.json "packageManager"; no hardcoding

      - uses: actions/setup-node@v7
        with:
          node-version-file: '.node-version' # or: node-version: 'lts/*'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm test
```
