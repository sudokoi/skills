---
name: commit-style
description: Encodes the user's git commit conventions (Conventional Commits with a short title and a concise pointwise body, and atomic commits made only when a logical change is complete). Use when writing commit messages, staging or committing changes, squashing, or when asked to "commit this", "write a commit message", or "make a commit".
---

# Commit Style

Rules for writing commits the way this user expects. Applies to every commit,
including commits an agent makes on their behalf.

## Format

Conventional Commits — a short `<type>: <title>`, then a blank line, then a concise
pointwise body:

```
<type>: <title>

- point one
- point two
```

Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `style`, `ci`,
`build`, `revert`.

## Title

- Short and imperative, lowercase after the colon: `feat: add commit-style skill`.
- Summarizes the logical change, not the files touched.

## Body

- Concise, pointwise (bulleted).
- Each bullet states one logical point about what changed and why — the overall
  logic, not implementation minutiae.
- Keep it high level; do not enumerate files or over-explain the implementation.
- Omit the body only for a trivial single-line change.

## Atomicity and frequency

- One commit = one independent, complete logical change. Never commit half a
  feature or a grab-bag of unrelated edits.
- Commit only when an independent logical feature block is complete — no more
  (too granular), no less (too coarse).
- Every commit must be fully self-contained and meaningful when read later in
  isolation.

## Anti-patterns

- No `phase 1`, `item 1`, `part 1`, `WIP`, `update files`, or checklist-style
  messages — they are meaningless to anyone reading the history later.
- No merging unrelated changes into one commit to save commits.
- No deep implementation dumps; keep the message a clear logical summary.

## Procedure

1. Inspect `git status`, `git diff`, and `git log --oneline` before committing.
2. Stage only the files that belong to this logical change.
3. Write the message per the rules above, then commit.

## Examples

Good:

```
feat: add commit-style skill

- Encode the Conventional Commits format with a short title and pointwise body
- Require atomic commits, one per completed logical change
- Document anti-patterns such as phase/item/WIP messages
```

Bad:

```
phase 1: item 1 - update files
```
