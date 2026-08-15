#!/usr/bin/env python3
"""Validate the skills repo: SKILL.md frontmatter, inventory.tsv, and slash commands."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMMANDS_DIR = ROOT / "setup-skills" / "commands"
INVENTORY = ROOT / "setup-skills" / "scripts" / "inventory.tsv"
BOOTSTRAP_SKILL = "setup-skills"

errors = []

# 1. Skill folders: valid frontmatter, name matches folder.
skill_names = set()
for skmd in sorted(ROOT.glob("*/SKILL.md")):
    folder = skmd.parent.name
    text = skmd.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        errors.append(f"{skmd.relative_to(ROOT)}: missing '---' frontmatter")
        continue
    fm = m.group(1)
    name_m = re.search(r"^name:\s*(.+)$", fm, re.MULTILINE)
    desc_m = re.search(r"^description:\s*(.+)$", fm, re.MULTILINE)
    if not name_m:
        errors.append(f"{skmd.relative_to(ROOT)}: frontmatter missing 'name'")
    else:
        name = name_m.group(1).strip()
        if not re.fullmatch(r"[a-z0-9-]+", name):
            errors.append(f"{skmd.relative_to(ROOT)}: name '{name}' must be lowercase, hyphen-separated")
        if name != folder:
            errors.append(f"{skmd.relative_to(ROOT)}: name '{name}' does not match folder '{folder}'")
        skill_names.add(name)
    if not desc_m:
        errors.append(f"{skmd.relative_to(ROOT)}: frontmatter missing 'description'")

# 2. Inventory format + duplicates.
inventory_names = set()
for i, line in enumerate(INVENTORY.read_text().splitlines(), 1):
    s = line.strip()
    if not s or s.startswith("#"):
        continue
    parts = s.split()
    if len(parts) != 2:
        errors.append(f"{INVENTORY.relative_to(ROOT)}:{i}: expected '<repo> <skill>', got {len(parts)} fields")
        continue
    repo, skill = parts
    if skill in inventory_names:
        errors.append(f"{INVENTORY.relative_to(ROOT)}:{i}: duplicate skill '{skill}'")
    inventory_names.add(skill)

# 3. Every self skill folder (except the bootstrap) is registered in the inventory.
for name in sorted(skill_names):
    if name != BOOTSTRAP_SKILL and name not in inventory_names:
        errors.append(f"skill folder '{name}' is not listed in inventory.tsv")

# 4. Every slash command references a skill in the inventory.
for cmd in sorted(COMMANDS_DIR.glob("*.md")):
    m = re.search(r"Load the ([a-z0-9-]+) skill", cmd.read_text())
    if not m:
        errors.append(f"{cmd.name}: missing 'Load the <skill> skill' line")
        continue
    if m.group(1) not in inventory_names:
        errors.append(f"{cmd.name}: references skill '{m.group(1)}' not in inventory.tsv")

if errors:
    print("\n".join(errors))
    sys.exit(1)

n_commands = len(list(COMMANDS_DIR.glob("*.md")))
print(f"OK: {len(skill_names)} skills, {len(inventory_names)} inventory entries, {n_commands} commands")
