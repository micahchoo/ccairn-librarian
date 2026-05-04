---
description: Steward the project .claude/ directory — catalog, audit, split CLAUDE.md, persist reference docs, prune. Invokes the librarian skill.
---

Invoke the **librarian** skill.

Tell it which duty to focus on if you have one in mind:

- *"Catalog .claude/"* → Duty 1 (rebuild INDEX.md)
- *"Audit .claude/"* → Duty 2 (CLAUDE.md size, gitignore coverage, path-gating gaps)
- *"Split CLAUDE.md"* → Duty 3 (decompose into rules/)
- *"Migrate this from user to project"* → Duty 4
- *"Archive old plans"* → Duty 5 (prune & archive)
- *"Persist this decision"* → Duty 6 (timestamped reference doc)
- *"Path-gate the rules"* → Duty 7
- *"Cross-reference"* → Duty 8

Without a specific duty, the skill will audit the directory and recommend which duty to run first.
