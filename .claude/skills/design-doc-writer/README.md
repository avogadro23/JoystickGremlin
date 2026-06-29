# design-doc-writer

A Claude Code skill that turns a vague feature idea into a precise, code-grounded
**design document** (PRD + spec hybrid, minus market/corporate framing) for a new
feature in an *existing* codebase.

It interviews you one question at a time — each with a recommendation and the
reasoning behind it — walks the decision tree depth-first, explores the real code
to ground every suggestion, **never assumes**, and stops at the document (it never
writes feature code).

## What's in the bundle

| File | Installs to | Purpose |
|---|---|---|
| `SKILL.md` + `references/` | `.claude/skills/design-doc-writer/` | Orchestrator instructions (the skill) |
| `agents/design-doc-explorer.md` | `.claude/agents/` | Read-only, model-pinned codebase explorer subagent |
| `commands/design-doc-writer.md` | `.claude/commands/` | Optional `/design-doc-writer` slash command |

The three pieces live in different Claude Code directories. The skill is the
single source of truth; the slash command is a thin deliberate entry point; the
subagent is spawned by the skill to keep heavy code reads out of the main context.

## Install (project scope)

```bash
# from your project root
mkdir -p .claude/skills/design-doc-writer .claude/agents .claude/commands

cp -r SKILL.md references .claude/skills/design-doc-writer/
cp agents/design-doc-explorer.md .claude/agents/
cp commands/design-doc-writer.md .claude/commands/
```

For user scope (available in every project), use `~/.claude/` instead of
`.claude/`.

## Use

- Auto-trigger: describe a feature you want to plan — e.g. "let's design bulk
  export before we build it" — and the skill activates.
- Deliberate: `/design-doc-writer <feature>`.

## Output

Two files, by default under `docs/design/` (confirmed with you at the start):

- `<slug>.notes.md` — append-only working notes / memory (kept and committed).
- `<slug>.md` — the condensed final design document.

## Models

The orchestrator should run on a strong model; the explorer subagent ships pinned
to a cheaper model (`haiku`) for cheap summarization. See
`references/subagent_and_models.md` to change this.
