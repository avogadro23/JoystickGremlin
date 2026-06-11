# AGENTS.md — `theme/Gremlin`

Guidance for building and extending the custom QML control library under
`theme/Gremlin`. Read this before creating or modifying any file here. Place this
file at `theme/Gremlin/AGENTS.md`.

The two recurring tasks are:
- **Schematic A — Producer:** author a control that must exist in both looks and
  share look-independent behavior. (You are *defining* the control.)
- **Schematic B — Consumer:** build a component that embeds a variant-bearing
  control and selects the look per instance. (You are *using* the control.)

Decide which you are doing with **Section 6** before writing code.

---

## 1. Environment

- **Binding:** PySide6 (Qt 6). Python 3.14+.
- **QML:** Qt Quick + Qt Quick Controls 2, Qt 6 syntax only.
  - `Connections` use `function onSignalName(args) { ... }`, never the deprecated
    `onSignalName:` form.
  - Signal handlers with parameters use the arrow form: `onActivated: (i) => ...`.
- **Host application** sets the base look once at startup and adds the import path:
  ```python
  from PySide6.QtQuickControls2 import QQuickStyle
  QQuickStyle.setStyle("Universal")
  ```
- The host window is an `ApplicationWindow`.

---

## 2. What this library is

Two component modules under a shared root:

```
theme/Gremlin/
├── Base/      Universal-look custom controls (relies on the app's Universal style)
└── Compact/   Condensed copies of basic controls + compact custom controls
```

- **Base** holds custom controls that render in the stock Universal look. It does
  **not** redefine basic controls (`Button`, `ComboBox`, …); those fall back to the
  app's Universal style.
- **Compact** holds condensed re-implementations of basic controls plus compact
  versions of the custom controls.

### Selection model — READ THIS

Look selection is **per-use-site, in code**, by *which type is instantiated* —
**not** by switching Qt Quick Controls styles. Quick Controls styles are
application-wide; this library deliberately does not rely on per-instance style
switching (it does not exist). Mix looks in one app via qualified imports:

```qml
import Gremlin.Base as Base
import Gremlin.Compact as Compact

Base.SomeControl    { /* Universal look */ }
Compact.SomeControl { /* compact look  */ }
```

**Consequence:** Compact basic controls apply **only where their types are
explicitly instantiated**. Stock `Button {}` / `ComboBox {}` elsewhere still render
in the app's active (Universal) style.

---

## 3. Directory layout (template)

```
theme/Gremlin/
├── AGENTS.md
├── Base/
│   ├── qmldir
│   ├── <SharedBehavior>.qml   # look-independent reusable behavior (0..n)
│   └── <CustomControl>.qml    # Universal-look custom controls (0..n)
└── Compact/
    ├── qmldir
    ├── <BasicControl>.qml     # condensed copy of upstream Universal control (0..n)
    └── <CustomControl>.qml    # compact-look custom controls (0..n)
```

- Shared, look-agnostic helpers (`<SharedBehavior>`) live in **Base**
- **Compact depends on Base** for them.
- If Compact must ever stand alone, hoist those into a neutral `theme/Gremlin/Common` module both import — do not add that directory speculatively.

---

## 4. Core principles (do not violate)

1. **Extract behavior, not look.** Look-independent behavior is factored into one
   shared component. Look-dependent visuals are not shared.
2. **Compact basic controls are faithful copies of upstream.** They are copies of
   the corresponding Qt Universal style control files, modified only for
   compactness. **Keep them diffable against upstream**: do not "clean up",
   deduplicate against Base, or re-architect them — a future Qt bump must be
   diffable and re-mergeable. Any custom additions stay minimal and obvious.
3. **One source of truth for shared values.** Values shared between the looks
   (clamps, delays, compact metrics) live in `qml/Style.qml` which is made
   accessible as `Gremlin.Style`. Never hard-code them.
4. **No business logic in QML.** Domain logic belongs in Python (`QObject`s
   exposed to QML). Presentation logic (decoration wiring, selection mediation)
   is allowed in these QML files.
5. **Small, single-purpose components.** Prefer `anchors`/layouts over manual
   `x`/`y`. Use `Connections` for non-trivial signal handling.

---

## 5. qmldir requirements

Each module needs a `qmldir`. A **module must be declared there** (not
optional). While plain components are auto-exposed by directory import but list
them for clarity. The components are not versioned.

```
# theme/Base/qmldir
module Gremlin.Base
<SharedBehavior> <SharedBehavior>.qml
<CustomControl> <CustomControl>.qml
```

---

## 6. Choosing a schematic

Answer in order:

1. **Are you defining or extending a control type that must exist in both looks
   and share some behavior across them?** → **Schematic A (Producer).**
2. **Are you building a component that embeds such a control and must choose its
   look at the embedding site (a flag, a condition, or caller injection)?**
   → **Schematic B (Consumer).**
3. **Do you just need a specific look at a direct call site, with no wrapping
   logic?** → Not a schematic. Instantiate `Base.X` or `Compact.X` (Section 2).
4. **Is the only difference between the looks a few metrics (padding/font/size)?**
   → A single control with a `bool` toggling metrics may suffice. (This does NOT
   apply to the structural Universal-vs-compact split, which uses full file
   copies — see principle 2.)

A and B **compose**: B embeds controls that were authored with A.

---

## SCHEMATIC A — Producer: a control in both looks sharing behavior

**Use when:** you are authoring/extending a control type; it must render in both
Base and Compact; some behavior or decoration must be identical across looks.

### Recipe

1. **Isolate the look-independent behavior** — the part that is the same
   regardless of Universal vs compact (e.g. a hover tooltip, a validation badge,
   a keyboard-shortcut handler, a busy overlay, a selection mediator). Implement
   it once as a reusable unit in `Base/`:
   - visual/interactive behavior → a small child component (Item / handler bundle);
   - pure logic/state → a `QtObject` controller.
   It must contain **no look-specific styling** and be parameterized via properties.
2. **Put shared constants in `Style`.**
3. **Author the Base variant** `Base/<Control>.qml`: the control rendered in the
   Universal look (basic controls via app-style fallback; custom controls built
   normally) **composing** the shared behavior.
4. **Author the Compact variant** `Compact/<Control>.qml`:
   - **Basic control** → a faithful copy of the upstream Universal control file,
     modified for compactness, with the shared behavior added in minimal,
     diffable lines.
   - **Custom control** → build on the local compact basic control (reference the
     local compact type unambiguously; do not re-import the stock type under the
     same name), composing the **same** shared behavior.
5. **Keep look-specific sub-parts per variant** (delegates, custom `contentItem`,
   `background`, `indicator`, `popup`). Extract a shared sub-part **only if** it is
   confirmed visually identical across both looks.
6. **Diff discipline:** additions to copied upstream files are a handful of
   clearly demarcated lines that reference the shared behavior — never inline the
   behavior's logic.

### Skeleton

```qml
// Base/<SharedBehavior>.qml — the one reuse unit; look-independent
import QtQuick
SomeType {
    // parameterized via properties; defaults from Theme; NO styling tied to a look
    // behavior implemented here, exactly once
}
```
```qml
// Base/<Control>.qml — Universal look
<BaseControl> {
    id: control
    // ...Universal-rendered control...
    <SharedBehavior> { /* composed in, parameterized from `control` */ }
}
```
```qml
// Compact/<Control>.qml — compact look
<CompactBaseControl> {            // copied-upstream basic, or local compact base
    id: control
    // ...compact-rendered control (per-variant visuals)...
    <SharedBehavior> { /* SAME composition */ }
}
```

### Output checklist
- [ ] Shared behavior exists once in `Base/`, no look styling inside it.
- [ ] Shared constants in `Style` imported as `Gremlin.Style`.
- [ ] Base and Compact variants both compose the shared behavior.
- [ ] Compact basic copies remain faithful/diffable to upstream.
- [ ] Look-specific sub-parts kept per variant unless proven identical.

> **Worked example:** a word-wrapping hover tooltip shared by a combobox in both
> looks → `Base/WrappingToolTip.qml` (the shared behavior, clamps width + delay
> from `Style`); `Base/TooltipComboBox.qml` and `Compact/TooltipComboBox.qml` each
> compose it (control-level tooltip + per-item tooltip in the popup delegate), with
> their own per-look popup delegates.

---

## SCHEMATIC B — Consumer: embed a variant control, select look per instance

**Use when:** you are building a higher-level component that embeds a control
which exists in both looks, and the look must be chosen per instance in code —
not app-wide.

```qml
MyWidget { useCompact: true }   // embeds the compact variant
MyWidget { }                    // embeds the base variant
```

### Recipe

1. **Expose a selection input** — a `bool useCompact` for the simple case, or a
   `Component` property for open-ended selection (Section B.2).
2. **Wrap each variant type in a `Component`** (a type cannot be chosen by variable
   in declarative instantiation).
3. **Drive a `Loader`** whose `sourceComponent` is selected by the input.
4. **Wire data in** via `Qt.binding` in `onLoaded`; **read signals out** via
   `Connections` targeting `loader.item`. Forward only the API the wrapper exposes.
5. **Treat the flag as set-once config** (see considerations).

### Skeleton

```qml
import QtQuick
import Gremlin.Base as Base
import Gremlin.Compact as Compact

Item {
    id: root
    property bool useCompact: false          // set-once config

    // forward ONLY the API this component exposes to its callers
    property var someData
    readonly property var someState: _loader.item ? _loader.item.<state> : null
    signal somethingHappened(var arg)

    Component { id: _baseVariant;    Base.<Control>    {} }
    Component { id: _compactVariant; Compact.<Control> {} }

    Loader {
        id: _loader
        // ...placed where the control belongs in this component's layout...
        sourceComponent: root.useCompact ? _compactVariant : _baseVariant
        onLoaded: {
            item.<prop> = Qt.binding(() => root.someData)
            // ...one binding per forwarded input...
        }
    }

    Connections {
        target: _loader.item
        function on<Signal>(arg) { root.somethingHappened(arg) }
    }
}
```

### B.2 Optional generalization
If a third variant or fully custom embed is anticipated, drive the `Loader` from a
`Component` property and make the flag sugar over it (add only if needed):

```qml
property bool useCompact: false
property Component variantComponent: useCompact ? _compactVariant : _baseVariant
Loader { sourceComponent: root.variantComponent /* ...same onLoaded */ }
```

### B.3 Considerations
- **Loader indirection:** the embedded control is `_loader.item`, reached via
  `Qt.binding` (in) and `Connections` (out) — never by id or alias (an alias to
  `_loader.item` is invalid; it is null until loaded).
- **Set-once flag:** treat the selector as construction-time config so the
  `Loader` instantiates once and `onLoaded` wiring is safe. Toggling at runtime
  recreates the control and resets its transient state — avoid live toggling.
- **API forwarding cost:** forward only what the wrapper needs to expose, not the
  whole embedded surface.

### Output checklist
- [ ] One `Loader`; `sourceComponent` chosen by the selector.
- [ ] Each variant wrapped in a `Component`.
- [ ] Inputs bound via `Qt.binding` in `onLoaded`; outputs via `Connections`.
- [ ] Only the needed API forwarded.
- [ ] Selector documented/treated as set-once.

> **Worked example:** a widget embedding a `TooltipComboBox` with `useCompact`
> picking `Compact.TooltipComboBox` vs `Base.TooltipComboBox` through a `Loader`.

---

## 7. Never do

- Never switch Qt Quick Controls **styles** to vary look per instance.
- Never inline a shared behavior's *logic*; always go through its reusable unit.
- Never refactor or deduplicate Compact copies of upstream controls against Base —
  keep them faithful and diffable.
- Never alias to `Loader.item`; wire via `Qt.binding` / `Connections`.
- Never hard-code shared values; read them from `Style`.
- Never put domain/business logic in these QML files.