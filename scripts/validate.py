#!/usr/bin/env python3
"""Validate the skills repo: SKILL.md frontmatter, inventory.tsv, and slash commands."""

import re
import sys
from pathlib import Path

BOOTSTRAP_SKILL = "setup-skills"
CATEGORIES = ("core", "react", "kotlin", "architecture", "process", "tooling")


def validate(root: Path, commands_dir: Path, inventory: Path):
    """Run every rule against a repo layout. Returns (errors, skill_names, inventory_names)."""
    errors = []
    skill_names = set()
    inventory_names = set()

    # 1. Skill folders: valid frontmatter, name matches folder.
    for skmd in sorted(root.glob("*/SKILL.md")):
        folder = skmd.parent.name
        text = skmd.read_text()
        m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if not m:
            errors.append(f"{skmd.relative_to(root)}: missing '---' frontmatter")
            continue
        fm = m.group(1)
        name_m = re.search(r"^name:\s*(.+)$", fm, re.MULTILINE)
        desc_m = re.search(r"^description:\s*(.+)$", fm, re.MULTILINE)
        if not name_m:
            errors.append(f"{skmd.relative_to(root)}: frontmatter missing 'name'")
        else:
            name = name_m.group(1).strip()
            if not re.fullmatch(r"[a-z0-9-]+", name):
                errors.append(
                    f"{skmd.relative_to(root)}: name '{name}' must be lowercase, hyphen-separated"
                )
            if name != folder:
                errors.append(
                    f"{skmd.relative_to(root)}: name '{name}' does not match folder '{folder}'"
                )
            skill_names.add(name)
        if not desc_m:
            errors.append(f"{skmd.relative_to(root)}: frontmatter missing 'description'")

    # 2. Inventory format + categories + duplicates.
    for i, line in enumerate(inventory.read_text().splitlines(), 1):
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split()
        if len(parts) != 3:
            errors.append(
                f"{inventory.relative_to(root)}:{i}: expected '<repo> <skill> <category>', "
                f"got {len(parts)} field(s)"
            )
            continue
        repo, skill, category = parts
        if category not in CATEGORIES:
            errors.append(
                f"{inventory.relative_to(root)}:{i}: unknown category '{category}' "
                f"(known: {', '.join(CATEGORIES)})"
            )
        if skill in inventory_names:
            errors.append(f"{inventory.relative_to(root)}:{i}: duplicate skill '{skill}'")
        inventory_names.add(skill)

    # 3. Every self skill folder (except the bootstrap) is registered in the inventory.
    for name in sorted(skill_names):
        if name != BOOTSTRAP_SKILL and name not in inventory_names:
            errors.append(f"skill folder '{name}' is not listed in inventory.tsv")

    # 4. Every slash command references a skill in the inventory. Commands are
    #    opt-in (only skills that need explicit invocation get one).
    command_targets = set()
    for cmd in sorted(commands_dir.glob("*.md")):
        m = re.search(r"Load the ([a-z0-9-]+) skill", cmd.read_text())
        if not m:
            errors.append(f"{cmd.name}: missing 'Load the <skill> skill' line")
            continue
        target = m.group(1)
        if target not in inventory_names:
            errors.append(f"{cmd.name}: references skill '{target}' not in inventory.tsv")
        command_targets.add(target)

    return errors, skill_names, inventory_names


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    commands_dir = root / "setup-skills" / "commands"
    inventory = root / "setup-skills" / "scripts" / "inventory.tsv"
    errors, skill_names, inventory_names = validate(root, commands_dir, inventory)
    if errors:
        print("\n".join(errors))
        return 1
    n_commands = len(list(commands_dir.glob("*.md")))
    print(
        f"OK: {len(skill_names)} skills, {len(inventory_names)} inventory entries, "
        f"{n_commands} commands"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
