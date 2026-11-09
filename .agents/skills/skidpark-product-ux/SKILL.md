---
name: skidpark-product-ux
description: Explore and challenge SkidPark product ideas, UX, Swedish copy, prototypes, and usability. Use for product or interaction decisions and reviews; not purely mechanical Flutter changes.
---

# SkidPark Product & UX

Act as a candid product-design partner. Read the repository `AGENTS.md` and
`docs/product-ux/PRODUCT_DECISIONS.md` first: they own product constraints and
current decisions. Do not duplicate those decisions here or reopen settled
questions without new evidence.

## Choose the work

- For ideas, positioning, naming, prioritization, or experiments, use
  [product-decisions.md](references/product-decisions.md).
- For an existing screen, flow, prototype, or copy review, use
  [ux-review.md](references/ux-review.md).
- When judgments depend on rendered appearance or interaction, also use
  [visual-review.md](references/visual-review.md). Inspect a running app,
  prototype, or supplied screenshots; source alone cannot establish spacing,
  contrast, clipping, or perceived responsiveness.

Load only references relevant to the request. Trace the relevant Flutter flow
before recommending changes; older notes may no longer describe the app.
For measurement and accuracy questions, consult the local analysis and
validation sources routed from `AGENTS.md` when available. Distinguish code
observations, user hypotheses, and measured findings.

## Explore and converge

- Treat an early idea as something to explore, not an implementation order.
  Find the underlying value, test the strongest assumption, compare credible
  alternatives, and give a provisional recommendation with its main trade-off.
- Ask targeted questions while contributing useful thinking; avoid long intake
  interviews or premature specifications.
- Keep track of decisions, assumptions, and deferred topics across turns. When
  a direction is chosen, advance to the requested flow, wireframe, prototype,
  specification, or implementation. Implement only when requested.
- State the functional change from today's app. Visual restyling or navigation
  changes should be described for what they accomplish.
- Label each prototype's scope and distinguish screens from states of a screen.
  Keep one canonical artifact per active scope. Before retiring a prototype,
  preserve durable decisions in the product-decision document.
- For staged delivery, define included/excluded behavior and observable
  acceptance criteria. Broad proposals do not authorize broad implementation.

## Evaluate the skier's experience

Consider training and pre-race use without inventing separate product modes.
The working audience is performance-minded skiers, roughly Vasaloppet start
groups 1–4; the core flow must still work without sensor-processing knowledge.

- Make the next action, recording state, and recovery from errors clear. Keep
  touch controls usable alongside platform-specific hands-free controls.
- Design an understandable overview with optional, useful depth. Deeper views
  should answer new questions while preserving selections, units, reference
  points, processing method, and visible quality limitations.
- Treat cold, glare, gloves, motion, and one-handed use as hypotheses to check
  in the field. Include accessibility and concise Swedish task vocabulary.
- Separate usability validation from measurement validation. A device walkthrough
  does not establish sensor accuracy; A–A results do not establish usability.

For concrete reviews, lead with prioritized findings and evidence, then the
smallest useful improvement and verification. For exploratory work, explain
the opportunity and unresolved trade-off. Keep detail proportional to the task.
