#!/usr/bin/env python3
"""Fixture-based tests for validate.py's rule groups."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate import validate

COMMANDS_REL = "setup-skills/commands"
INVENTORY_REL = "setup-skills/scripts/inventory.tsv"


class ValidationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.commands = self.root / COMMANDS_REL
        self.inventory = self.root / INVENTORY_REL
        self.commands.mkdir(parents=True)
        self.inventory.parent.mkdir(parents=True)
        self.inventory.write_text("sudokoi/skills foo core\n")
        self.skill("foo")

    def tearDown(self):
        self.tmp.cleanup()

    def skill(self, name, body=None):
        folder = self.root / name
        folder.mkdir(exist_ok=True)
        content = body or f"name: {name}\ndescription: A test skill.\n"
        (folder / "SKILL.md").write_text(f"---\n{content}---\n")

    def command(self, name, target):
        (self.commands / f"{name}.md").write_text(
            f"---\ndescription: x\n---\nLoad the {target} skill and do it.\n"
        )

    def errors(self):
        errors, _, _ = validate(self.root, self.commands, self.inventory)
        return errors

    def test_valid_repo_passes(self):
        self.command("foo", "foo")
        self.assertEqual(self.errors(), [])

    def test_missing_frontmatter(self):
        (self.root / "foo" / "SKILL.md").write_text("no frontmatter here\n")
        self.assertTrue(any("missing '---' frontmatter" in e for e in self.errors()))

    def test_missing_name(self):
        self.skill("foo", "description: A test skill.\n")
        self.assertTrue(any("missing 'name'" in e for e in self.errors()))

    def test_bad_name_format(self):
        self.skill("foo", "name: Foo_Bar\ndescription: A test skill.\n")
        self.assertTrue(any("must be lowercase, hyphen-separated" in e for e in self.errors()))

    def test_name_does_not_match_folder(self):
        self.skill("foo", "name: bar\ndescription: A test skill.\n")
        self.assertTrue(any("does not match folder" in e for e in self.errors()))

    def test_missing_description(self):
        self.skill("foo", "name: foo\n")
        self.assertTrue(any("missing 'description'" in e for e in self.errors()))

    def test_inventory_bad_field_count(self):
        self.inventory.write_text("sudokoi/skills\n")
        self.assertTrue(any("expected '<repo> <skill> <category>'" in e for e in self.errors()))

    def test_inventory_unknown_category(self):
        self.inventory.write_text("sudokoi/skills foo weird\n")
        self.assertTrue(any("unknown category 'weird'" in e for e in self.errors()))

    def test_inventory_all_categories_valid(self):
        self.command("foo", "foo")
        lines = ["sudokoi/skills foo core"]
        for cat in ("react", "kotlin", "architecture", "process", "tooling"):
            skill = f"skill-{cat}"
            lines.append(f"a/{cat} {skill} {cat}")
            self.command(skill, skill)
        self.inventory.write_text("\n".join(lines) + "\n")
        self.assertEqual(self.errors(), [])

    def test_inventory_duplicate(self):
        self.inventory.write_text("a/b foo core\nc/d foo core\n")
        self.assertTrue(any("duplicate skill 'foo'" in e for e in self.errors()))

    def test_self_skill_not_in_inventory(self):
        self.skill("bar")
        self.assertTrue(any("'bar' is not listed in inventory.tsv" in e for e in self.errors()))

    def test_command_references_unknown_skill(self):
        self.command("baz", "nope")
        self.assertTrue(
            any("references skill 'nope' not in inventory.tsv" in e for e in self.errors())
        )

    def test_command_missing_reference_line(self):
        (self.commands / "foo.md").write_text("---\ndescription: x\n---\nJust do the thing.\n")
        self.assertTrue(any("missing 'Load the <skill> skill' line" in e for e in self.errors()))

    def test_inventory_skill_has_no_command(self):
        self.assertTrue(any("'foo' has no slash command" in e for e in self.errors()))


if __name__ == "__main__":
    unittest.main(verbosity=2)
