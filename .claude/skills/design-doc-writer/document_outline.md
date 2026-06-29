# Final document outline

The final design document (`docs/design/<slug>.md`) is a PRD + spec hybrid —
product reasoning **minus** market and corporate framing, fused with an
engineering specification. Every technical claim about the existing system is
grounded in real code with file-path references gathered during exploration.

Keep it precise and concise. Convey technical detail through the smallest
sufficient artifact — a type signature, an interface or schema sketch, the
*shape* of an approach. **Never** full function bodies or working feature code.

Draft each section as its branch closes; do a condensing pass at synthesis.

## Sections

1. **Problem & motivation** — the need this serves and why now. Product
   reasoning, no market sizing or business case.

2. **Goals & non-goals** — explicit, bulleted scope boundaries. What this
   feature will and will not do.

3. **Current state** — how the relevant part of the *existing* codebase works
   today, grounded in actual code with file-path references. This is the section
   that makes the doc codebase-specific rather than greenfield.

4. **Requirements / desired behavior** — functional requirements as an itemized
   list. Each item has a stable ID, an optional priority, a bolded short
   description, then a longer explanation:

   ```
   [R1] (must) **Bulk selection** — Users can select multiple records via
   checkbox and act on them in one operation. Selection persists across
   pagination within a session.
   [R2] (should) **Partial-failure reporting** — If an operation succeeds for
   some records and fails for others, the user sees which failed and why.
   [R3] **Empty-state handling** — Acting on an empty selection is a no-op with
   a clear message.
   ```

   - **IDs (`[R#]`) are required** — stable handles so Sections 8 (decisions) and
     9 (testing) can reference a requirement instead of restating it.
   - **Priority (`(must)`/`(should)`/`(could)`) is optional** — include only when
     the feature has meaningful scope tiering; omit otherwise (see R3).
   - Keep the bolded lead phrase short; keep the explanation to a sentence or two.
   - For the rare requirement where exact conditional behavior is load-bearing, a
     trimmed Given/When/Then is acceptable *for that item only* — prose elsewhere.

5. **Proposed design** — the technical approach. Structure is **adaptive**: the
   agent proposes which Level-2 components and which optional facets (data model,
   concurrency, migration impact, error propagation, …) apply to this feature and
   drops the rest — it suggests, the user approves. The spine:

   - **Lead-in** — one orienting paragraph and a **mermaid component diagram**
     showing the pieces and how they connect. Add a **mermaid sequence diagram**
     for the main (happy-path) flow where it aids understanding.
   - **Level 1 — Component interaction** — narrative of how the components
     collaborate to satisfy the requirements; how the new work attaches to what
     already exists. This is the "how things interact" level.
   - **Level 2 — Per component (class / package)** — one short subsection per
     component, using a light, consistent mini-template:
     - *Responsibility* — one line.
     - *Interface / API* — described at the **shape** level: endpoints as
       method + path + purpose; request/response and data shapes as typed field
       lists or small tables. **Not** rendered as source-code snippets.
     - *Integration & files touched* — concrete paths.

   **Code rule for this section:** no source-code fragments. The API/interface is
   *described*, not coded. **Pseudocode is a major exception** — permitted only
   for a genuinely non-obvious algorithm, capped at a few lines, where prose would
   be vaguer. Never full function bodies.

   Optional: a one-line "design at a glance" summary at the top for skimmers; a
   dedicated data-model treatment (typed field list / schema sketch) when the
   feature is data-centric.

6. **Affected areas / integration points** — the specific modules, files, and
   systems this touches, grounded in exploration. Concrete paths, not
   generalities.

7. **Edge cases & error handling** — boundary conditions, failure modes, and how
   each is handled.

8. **Design decisions & alternatives** — *(merged decision log + alternatives)*
   each significant decision: the options weighed, what was rejected and why, and
   the code evidence behind the choice. This is the condensed distillation of the
   reasoning captured in the notes file.

9. **Testing strategy** — how the feature will be verified; unit/integration
   boundaries, what needs fixtures or new test infrastructure.

10. **Rollout / migration considerations** — data migrations, feature flags,
    backward-compatibility, phased rollout, anything needed to ship safely.

11. **Out of scope** — aspects deliberately excluded, each with a brief why, so a
    reader knows the omission was intentional rather than overlooked. Genuinely
    unresolved questions, if any, may sit here under their own heading — but the
    section's framing is *exclusion*, not uncertainty.

## Notes-vs-final split

- The **notes file** holds the full, messy trail: every explorer finding with
  citations, full reasoning, every rejected alternative, the live search tree.
- The **final doc** is the condensed, readable synthesis. Section 8 is where the
  notes' decision trail gets distilled — the final doc should not reproduce the
  raw notes.
