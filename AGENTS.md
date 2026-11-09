# SkidPark agent guidance

## Product and sources of truth

SkidPark helps a solo cross-country skier compare glide across repeated runs.
Small relative differences matter. Show inspectable visualizations and quality
information; the skier makes the final interpretation. Testing guidance helps
collect better data without becoming a requirement for recording or analysis.
The normal workflow assumes a phone held in the hand; mounted equipment is an
optional validation or precision aid.

- Before product, UX, navigation, or test-flow changes, read
  `docs/product-ux/PRODUCT_DECISIONS.md`. It owns settled decisions, working
  assumptions, and deferred topics. Prototypes and old implementation reports
  are supporting evidence; check them against current decisions and code.
- Before materially changing measurement or its accuracy claims, read the local
  `docs/glide-data-analysis/README.md` and linked validation plan when available.
  These user-data analyses are intentionally ignored by Git.
- Use `.agents/skills/skidpark-product-ux/SKILL.md` for product and UX judgment,
  not purely mechanical Flutter changes.

## Architecture and code

- Flutter/Dart, Drift (SQLite), Provider/ChangeNotifier, and MVVM. Keep UI,
  view-model, persistence, and calculation/filtering responsibilities separate.
- Use descriptive English identifiers and Swedish user-facing text unless the
  surrounding feature intentionally supports another language.
- Prefer small, focused methods and composition. Name orchestration steps;
  comment non-obvious reasoning and maths rather than restating code.
- Extract shared widgets for patterns used by multiple real screens, rather
  than accumulating repeated private `_buildX` helpers.
- Trace relevant data flow before editing. Keep changes focused and preserve
  unrelated work in the working tree.

## Persistence and recording invariants

- `GlideTestSki` is the source of truth for a test's ordered ski selection.
  Export the complete selection, including skis that do not yet have a run.
- `TestRun.runNumber` is stable within its glide test. Allocate it in
  `TestRunRepository` in the insert transaction, never from a global row id or
  list index. Preserve explicit numbers in import/export; assign file order for
  older exports.
- Opening or analyzing a test must not start location services. The recording
  route owns the recorder lifecycle: start after `Nytt åk`; stop on save,
  cancel, back navigation, errors, and disposal.

## Measurement and data integrity

- Preserve raw sensor data and its meaning when adding processing.
- Judge methods by whether they preserve meaningful run/ski differences.
  Compare those differences with repeated-run variation; assess absolute
  accuracy by its effect on relative comparisons.
- State units, coordinate axes, sampling frequency, timestamps, interpolation,
  and filter parameters. Explain the effect and uncertainty of changes to
  filtering, alignment, release-point detection, or metrics.
- Prefer deterministic, inspectable calculations. Do not hide data-quality
  limits behind confident labels. Derived speed and distance remain estimates
  until checked with repeated A–A runs and an independent reference; smoother
  curves or larger separation alone do not justify a primary calculation.

## Delivery and verification

- Explicit delivery phases are hard scope boundaries. For delegated work, state
  inclusions and exclusions and review the resulting diff for scope. Do not
  bring later phases forward without asking.
- For requested implementation subagents without a specified model, prefer a
  lower-cost coding model for routine bounded work; justify stronger models by
  risk or complexity. The main agent owns review and verification.
- When implementing a canonical prototype, compare rendered appearance, copy,
  density, and interactions. Document intentional deviations.
- After a fresh checkout, dependency change, or database-schema change, run
  `dart run build_runner build`. Drift's `*.g.dart` files are Git-ignored.
- For Drift schema changes, trace recording, example installation, import,
  export, and UI decoding. Test migration from the latest shipped schema and
  every older cumulative migration branch affected by the definition.
- Run `flutter analyze` for Dart changes and focused existing tests. Add focused
  tests for calculation, filtering, alignment, and data transformations where
  practical. Build recording/analysis end-to-end coverage gradually; propose
  material test-framework expansions before implementing them.
- Recording-flow device checks cover forward/back/cancel/start/stop/save and
  short/long volume actions in overview and ski selection. Prioritize credible
  data-loss, GPS, and navigation failures over rapid multi-input edge cases.
- Update durable documentation when behavior or decisions change. Keep current
  tasks in `TODO.md`; avoid appending session narratives to agent instructions.

## Communication

Match the user's language, give concise progress updates, and finish with what
changed, why, and how it was verified. Surface material design and data-quality
concerns. Ask before materially broadening scope, architecture, or UX.
