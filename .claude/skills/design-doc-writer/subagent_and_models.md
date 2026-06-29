# Explorer subagent & model selection

## The explorer subagent

The bundle ships `agents/design-doc-explorer.md`, a read-only subagent that does
the heavy code reading in its **own isolated context window** and returns only a
tight, cited summary. This keeps large codebase explorations out of the
orchestrator's context, so the orchestrator stays focused on the interview, the
search tree, and synthesis.

**Why read-only:** the explorer is given only `Read`, `Grep`, and `Glob`. It
physically cannot modify code, which guarantees the planning phase never touches
the codebase — reinforcing the skill's hard "no implementation" boundary.

**How to invoke:** spawn it for any non-trivial exploration during Phases 0.5
and 2 — "summarize how billing is wired and return only what's relevant to
adding usage-based pricing", "find every caller of `loadUser`", "what does
`src/sync/` do". Ask it to cite file paths and to return only what bears on the
current design question.

**If it is not installed:** the orchestrator may explore inline using its own
read tools, but should keep reads tight and summarize aggressively rather than
pulling whole files into context.

## Model selection

Per-subagent model selection is set via the `model` field in the subagent's
frontmatter (a specific model like `haiku`/`sonnet`/`opus`, a full model name,
or `inherit`).

**Recommended cost shape:** run the **orchestrator on a strong model** (the
expensive design reasoning lives here) and the **explorer subagents on a cheaper
model** (Haiku or Sonnet — cheap summarization at the leaves). The explorer ships
pinned to a cheaper model for this reason.

**Two things to be deliberate about:**

1. Set the explorer's model **explicitly** in its frontmatter. The default model
   for a subagent with an omitted `model` field has been ambiguous across Claude
   Code versions (inherit vs. a hardcoded default), so do not rely on the
   default.

2. Keep explorers **cheaper than** the orchestrator, not more expensive. At least
   one Claude Code surface enforces that a subagent's model may not exceed the
   main model's cost tier (it silently falls back to the main model otherwise).
   Orchestrator-strong / explorer-cheap sidesteps this entirely. If you want
   explorers on a *more* expensive model than the main session, verify your
   specific Claude Code version supports it first.

To change the explorer's model, edit the `model:` line in
`agents/design-doc-explorer.md`.
