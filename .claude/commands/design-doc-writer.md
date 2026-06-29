---
description: Start a grounded, interview-driven design document for a feature in this codebase
---

Invoke the **design-doc-writer** skill to produce a code-grounded design
document for the feature described below (or, if nothing is described, ask the
user what feature they want to design — one question to start).

Follow the skill exactly: interview one question at a time with a recommendation
and reasoning for each, never assume, walk the decision tree depth-first, explore
the codebase via the `design-doc-explorer` subagent, keep the append-only working
notes file as memory, and synthesize the final design document at the end. Do not
write any feature code — stop at the document.

Feature to design: $ARGUMENTS
