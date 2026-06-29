---
name: design-doc-writer
description: >-
  Produce a grounded design document (PRD + spec hybrid, minus market/corporate
  framing) for a new feature in an EXISTING codebase, by interviewing the user
  one question at a time and exploring the real code before each decision. Use
  this WHENEVER the user wants to plan, design, or spec a feature in a codebase
  before building it — e.g. "design doc for X", "spec out X", "let's design X
  before we build it", "write a design document", "grill me on this feature and
  write it up", or when they describe a non-trivial feature and start reasoning
  about how it should work. Trigger even if the user does not say the words
  "design document". Do NOT trigger when the user just wants to start
  implementing or fixing code now — this skill stops at the document and never
  writes feature code.
---

# Design Doc Writer

Turn a vague feature idea into a precise, code-grounded design document through a
relentless one-question-at-a-time interview. This is a planning tool: it runs
*before* implementation and **never writes the feature**.

The discipline is borrowed from the grill-me pattern (interview relentlessly,
walk the decision tree depth-first, recommend an answer for each question) with
three additions: (1) it actively explores the real codebase to ground every
suggestion, (2) it **never assumes** — exploration informs a question, it does
not replace one, and (3) it emits two persistent files: an append-only working
notes file (memory) and a condensed final design document.

## Core principles (hold these the entire session)

- **One question at a time.** Never present a wall of questions. Ask the single
  highest-leverage open question, wait, then move on.
- **Never assume.** When code or convention could answer a question, explore it
  and form a recommendation — but still put it to the user with the evidence and
  the reasoning, and let them decide. "I read `OrderService` and it emits events
  via `EventBus`, so I'd reuse that rather than add a new dispatch path, because
  it preserves the existing ordering guarantees — agree?" Evidence + reasoning +
  recommendation, user makes the call.
- **Depth-first, one branch at a time.** Pick a branch of the decision tree and
  resolve it fully before moving to the next. Do not surface an API question
  while the data-model branch is still open. If resolving a branch reveals a new
  dependency, slot it in as a child of the current branch — do not wander off.
- **Resolve upstream before downstream.** Walk branches in dependency order: a
  decision that constrains many others (e.g. "new entity vs. extend an existing
  one") is settled before the decisions that depend on it.
- **Precise and concise.** Illustrate with the smallest sufficient artifact —
  the *shape* of an approach: an interface/API described at endpoint or
  typed-field-list level, a schema sketch, a mermaid diagram. **No source-code
  fragments**; pseudocode only as a rare exception for a genuinely non-obvious
  algorithm (a few lines, never full function bodies). This applies to the notes
  file too: terse findings, not pasted code dumps.
- **Stop at the document.** Never implement, never write feature code, even if
  the conversation drifts that way. Grill first, decide second; implementation
  is a separate session.

## The two output files

Establish a `<feature-slug>` early (kebab-case, e.g. `bulk-export`). Confirm the
output directory with the user before writing — default `docs/design/`, but some
teams use `docs/rfcs/`, `docs/adr/`, or `.design/`.

1. **Working notes — `docs/design/<slug>.notes.md`** (append-only memory).
   Grows continuously through the interview. Holds raw explorer findings with
   file-path citations, the reasoning behind each suggestion, rejected
   alternatives, open questions, and the current state of the search tree. This
   is the agent's durable memory — re-read it after any context compaction or
   resume instead of trying to hold everything in context. Messy is fine.
   Header it clearly: `> Auto-generated working notes. See <slug>.md for the
   actual design.` **Keep it** at the end, committed alongside the final doc.

2. **Final design document — `docs/design/<slug>.md`** (condensed artifact).
   Synthesized from the notes. As each branch closes, draft its resolved section
   here so the user is never far from a usable deliverable; do the polishing /
   condensing pass at synthesis time. Outline in `references/document_outline.md`.

## Workflow

### Phase 0 — High-level intake (no code yet)

Interview the user about the feature at a high level — what it is, roughly what
it is for, the broad strokes — *without reading the codebase yet*. Goal: form a
general mental model. A handful of questions, one at a time. Do not go deep.

### Phase 0.5 — Grounding scan

Now read the project's context files (`AGENTS.md`, `CLAUDE.md`, README) and do a
*light* structural pass (top-level layout, language, framework, test setup,
relevant entry points). Enough to ask informed questions — not a deep audit.
Prefer doing this via the `design-doc-explorer` subagent so the orchestrator's
context stays clean (see "Exploring the codebase" below).

### Phase 1 — Build the visible search tree

From the mental model + grounding scan, construct the decision tree: the
branches/questions to resolve, ordered by dependency. **Show it to the user** so
they can reorder, add, or kill branches before the interview begins — catching a
missing branch here is cheap; catching it 30 questions in is not. Mirror the
final-doc outline (see `references/document_outline.md`), but adapt to the
feature. Persist the tree into the notes file and keep it updated as a progress
map: `resolved: …  current: …  pending: …`.

### Phase 2 — Depth-first branch walk

Walk the tree one branch at a time, depth-first. For each open question:

1. If the codebase can inform it, spawn a `design-doc-explorer` subagent to dig
   into the relevant code and return a tight, cited summary.
2. Present the question to the user with: the evidence found, your reasoning,
   and a recommended answer. Wait for their decision. **Never lock in an
   assumption.**
3. Append the resolved decision + evidence + rejected alternatives to the notes
   file, and draft the corresponding final-doc section.
4. Update the progress map. Move to the next question in the branch; only move to
   the next branch once the current one is fully resolved.

### Phase 3 — Synthesize

Condense the notes into the final design document: clean prose, the minimal
sketches needed, the decision log distilled into "Design decisions &
alternatives". Confirm the notes file is kept and headed as working notes.
Report both file paths to the user. **Stop. Do not offer to implement.**

## Exploring the codebase (subagent usage)

Heavy code reading must not pollute the orchestrator's context. Spawn the
`design-doc-explorer` subagent (read-only; pinned to a cheaper model)
for any non-trivial exploration — "summarize how billing is wired", "find every
caller of `loadUser`", "what does this module do". The subagent returns only a
cited summary relevant to the design question; the orchestrator keeps the tree,
the interview, and synthesis.

If the explorer subagent is not installed, the orchestrator may explore inline,
but should still keep reads tight and summarize aggressively. See
`subagent_and_models.md` for installation, the read-only rationale,
and model-pinning notes (run the orchestrator on a strong model, explorers on a
cheaper one; set models explicitly rather than relying on defaults).

## Reference files

- `document_outline.md` — the section-by-section spec for the final
  document. Read before drafting any section.
- `subagent_and_models.md` — how the explorer subagent works, why
  read-only, and how model selection is configured.
