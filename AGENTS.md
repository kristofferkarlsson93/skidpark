# SkidPark agent guidance

## Product context

SkidPark helps a solo cross-country skier compare ski glide. Small performance
differences matter. The goal is reliable *relative* comparisons between runs,
not merely a single run's distance or top speed.

The primary product output should be inspectable visualizations and transparent
quality information, not an automatic declaration of which ski won. The user
makes the final interpretation. Testing guidance should help users collect
better data without becoming a hard requirement for recording or analysis.

The optimal way to test skis is to be two people, starting from the top of a hill, holding hands and gliding down. At a given signal when having the same speed the skiers release their hands and see how the skis play out against each other.
You can not do this by your self. The purpose of this app is to help single skiers compare skis.

The app records GPS and accelerometer data, stores raw data locally, and uses
low-pass filtering and a Kalman filter to estimate speed. Comparison views
align runs around meaningful points such as maximum speed or a selected release
point.

The normal workflow assumes that the phone is held in the hand. Mounting the
phone or using external equipment may be useful for validation or an optional
precision mode, but should not silently become a requirement for the core
experience.

## Current product and UX direction

- Treat glide testing as the primary activity and the ski park as a supporting,
  persistent collection. The main navigation starts with Tests.
- Support preparation at home or in the car and flexible switching between
  recording and analysis in the track. Do not impose test lifecycle stages or
  separate home/track modes.
- Before product, UX, onboarding, navigation, or test-flow changes, read
  `docs/product-ux/PRODUCT_DECISIONS.md`. It is the source of truth for settled,
  provisional, and deliberately deferred decisions from prior discussions.

## Architecture

- Flutter/Dart app using Drift (SQLite), Provider/ChangeNotifier, and an MVVM
  style.
- Keep UI, view-model, persistence, and calculation/filtering logic separate.
- Use English, descriptive identifiers in code. Keep user-facing text Swedish
  unless the surrounding feature intentionally supports another language.
- Prefer small, focused files and methods. Structure orchestration methods as
  clear, named steps; use comments for non-obvious reasoning or maths, not to
  repeat the code.
- Prefer composition over inheritance and avoid abstractions without a concrete
  current need.

## Measurement and data integrity

- Preserve raw recorded sensor data; do not silently change its meaning or
  overwrite it when introducing new processing.
- Be explicit about units, coordinate axes, sampling frequency, timestamps,
  interpolation, and filter parameters.
- Changes to filtering, alignment, release-point detection, or metrics must
  explain their expected effect on comparison results and call out uncertainty.
- Favour deterministic, inspectable calculations. Do not hide data-quality
  limitations behind overly confident UI labels.
- Treat derived speed and distance as estimates until they have been checked
  with repeated A–A runs and an independent reference. Do not select a primary
  calculation merely because it produces smoother or larger visual differences.
- Before materially changing the measurement model, read the local
  `docs/glide-data-analysis/README.md` and its linked validation plan when they
  are available. They are intentionally ignored by Git because they are based
  on user data.

## Working in this repository

- Start by locating the relevant feature and tracing data flow before editing.
- When a change reveals durable project knowledge that would help future work,
  suggest a focused update to the relevant documentation. Do not create
  documentation churn or treat older notes as authoritative without checking
  the implementation.
- Drift-generated files such as `lib/common/database/database.g.dart` are
  ignored by Git. After a fresh checkout, dependency change, or database-schema
  change, run `dart run build_runner build --delete-conflicting-outputs`.
- Run `flutter analyze` for Dart changes when the local Flutter toolchain is
  available. Run focused tests where they exist.
- Automated coverage is still small. When changing pure calculation, filtering,
  alignment, or data-transformation logic, add focused tests where practical.
  For user-critical recording and analysis flows, prefer gradually building
  Flutter integration (end-to-end) coverage over broad mock-heavy unit tests.
- Do not add a large test framework or test suite as incidental work. Propose a
  scoped test plan first if that would be a material expansion.
- Keep changes focused. Do not reformat or alter unrelated code.

## Communication

- Match the language used by the user in the current conversation.
- Keep the user informed with concise progress updates during multi-step work.
- Finish with a short summary of what changed, why, and how it was verified.
- Surface design, data-quality, or safety concerns clearly, even when they are
  outside the immediate request.
- If a clearly better approach would materially change scope, architecture, or
  user experience, explain it and seek direction before implementing it.
