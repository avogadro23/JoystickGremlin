---
description: Analyse this Python/PySide6+QML codebase and produce focused, AI-agent-ready documentation for a specific topic. Invoke when the user wants to document an architectural area, pattern, subsystem, or concept so that another AI agent can understand it without reading the whole codebase.
allowed-tools: Read, Glob, Grep, Bash(find:*), Bash(grep:*), Bash(wc:*)
argument-hint: <topic> — e.g. "signal/slot wiring", "navigation model", "theming system", "async data loading"
disable-model-invocation: true
---

# Codebase Topic Documentation Generator

You are a senior software architect specialising in Python backend logic and Qt/QML frontend development with PySide6. Your task is to produce **concise, structured documentation** about a specific topic in this codebase that a downstream AI agent can consume without access to the source files.

## Topic requested by the user

$ARGUMENTS

---

## Phase 1 — Discover the codebase layout

Run the following to understand the project structure before reading any file.

!`find . -type f \( -name "*.py" -o -name "*.qml" \) | grep -v __pycache__ | grep -v ".venv" | grep -v "node_modules" | sort | head -120`

Also check for a top-level README or CLAUDE.md:

!`find . -maxdepth 2 -name "README*" -o -name "CLAUDE.md" | head -10`

---

## Phase 2 — Locate topic-relevant files

Use Grep and Glob to find every file that is likely relevant to **$ARGUMENTS**. Cast a wide net first, then narrow:

1. Search Python files for class names, function names, decorators, and import statements related to the topic.
2. Search QML files for component names, signal names, property bindings, and id references related to the topic.
3. Check `*.ui` or `*.qrc` resource files if present.
4. Look inside any `models/`, `controllers/`, `views/`, `qml/`, `resources/`, `services/`, or `utils/` directories for topic-related modules.

Read every relevant file in full. Do **not** skip files because they look similar — subtle differences matter.

---

## Phase 3 — Analyse and synthesise

After reading all relevant files, answer these questions internally before writing the documentation:

- What is the **single responsibility** of each component involved in this topic?
- How does **data flow** between the Python layer and the QML layer for this topic? (signals → slots, properties, `setContextProperty`, `@QmlElement`, etc.)
- What **design patterns** are in use? (MVVM, MVC, Repository, Singleton, Factory, Observer via signals, etc.)
- Are there any **non-obvious conventions** the codebase enforces (naming, threading rules, registration patterns)?
- What are the **entry points** an agent would touch to extend or modify this topic area?
- Are there any **known quirks, workarounds, or TODOs** in the topic area?

---

## Phase 4 - Expert feedback

After you analyzed everything come up with questions you want to ask an expert in the code base to clarify aspects that are not entirely clear or possibly contradictory and need to be resolved.

Ask these questions to the user, don't answer them yourself.

- I see there are two ways achieving the same thing, which one should be used?
- I see the code is using both old and new styles of signals, which approach is the appropriate one?

---

## Phase 5 — Write the documentation

Produce a Markdown document with **exactly** the sections below. Keep each section tight and agent-consumable — prefer structured lists and code snippets over prose paragraphs.

---

```markdown
# [TOPIC]: <concise title derived from $ARGUMENTS>

> **Purpose of this document:** Provide a downstream AI agent with everything it needs to understand, navigate, and safely modify the `<topic>` subsystem of this codebase without reading the raw source files.

---

## 1. Scope

One short paragraph: what this topic covers and what it explicitly does NOT cover.

---

## 2. Key Files & Modules

| File / Module | Role in this topic |
|---|---|
| `path/to/file.py` | What it does here |
| `path/to/Component.qml` | What it does here |

List every file that is materially involved. Omit unrelated files.

---

## 3. Architecture Overview

Describe how the pieces fit together. Use an ASCII diagram if helpful.

Example:

```
UserAction (QML)
    │ signal clicked()
    ▼
ViewModel (Python, QObject)
    │ @Slot / @Property
    ▼
Service / Repository (Python)
    │
    ▼
Data Layer / API
```

Explain each arrow: what mechanism connects them (signal, property binding, direct call, Qt.queued connection, etc.).

---

## 4. Data Flow

Step-by-step trace of the most important runtime path(s) for this topic.

Example:
1. User triggers `<action>` in `<QML file>` via `<signal/event>`
2. `<Python slot>` in `<class>` receives it
3. `<class>` calls `<service method>`
4. Result propagates back via `<mechanism>` to `<QML property/model>`

---

## 5. Core Classes & Their Contracts

For each Python class central to this topic:

### `ClassName` (`path/to/module.py`)

- **Inherits:** `QObject` / `QAbstractListModel` / etc.
- **Registered as QML type:** yes/no — registration call or decorator
- **Key properties:** list with types and whether notify signals exist
- **Key signals:** list with parameter types
- **Key slots / methods:** list with brief purpose
- **Threading notes:** runs on main thread / worker thread / uses `QThreadPool`

---

## 6. QML Side

For each QML component central to this topic:

### `ComponentName.qml` (`path/to/ComponentName.qml`)

- **Type / base:** `Item`, `Rectangle`, `Popup`, custom type, etc.
- **Exposed properties:** list
- **Signals emitted:** list
- **Python bindings used:** which context properties or registered types it accesses
- **Notable patterns:** any non-obvious binding tricks, `Loader` usage, dynamic creation, etc.

---

## 7. Extension Points

How should an AI agent add new behaviour to this topic area?

- To add a new **[feature type]**: create/modify `<file>`, register via `<mechanism>`, expose via `<pattern>`
- To add a new **QML component** that participates: follow `<pattern>` seen in `<example file>`
- Mandatory steps checklist (if any): e.g. "must call `registerType()` in `main.py`"

---

## 8. Conventions & Rules

Bullet list of non-obvious rules the agent MUST follow to avoid breaking things:

- Naming: e.g. "all ViewModel classes must end in `ViewModel`"
- Threading: e.g. "never access the QML engine from a worker thread"
- Signal hygiene: e.g. "always emit `dataChanged` before returning from a slot that mutates a model"
- Registration: e.g. "new QML types must be added to `qmldir` and `resources.qrc`"
- Error handling: e.g. "slots must not raise exceptions; log and return a sentinel value"

---

## 9. Known Issues / TODOs

List any TODOs, FIXMEs, workarounds, or known fragility found in the relevant files. Quote the comment and the file path.

---

## 10. Glossary

| Term | Meaning in this codebase |
|---|---|
| `<term>` | `<definition>` |

Only include terms that have a project-specific meaning different from Qt/Python defaults.
```

---

## Output instructions

- Write the completed document above as your response. Do **not** include any preamble like "Here is the documentation" — output the Markdown directly.
- Replace every `<placeholder>` with real content drawn from the actual files you read.
- If a section genuinely has nothing to report (e.g. no known issues), write `None found.` rather than omitting the section.
- Code snippets must be real excerpts (≤ 20 lines each) from the actual source, not invented examples.
- The document must be self-contained: a reader with no access to the repo must understand the topic fully.