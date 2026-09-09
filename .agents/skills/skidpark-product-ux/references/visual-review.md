# Inspect SkidPark Visually and Interactively

Use this guide when a recommendation depends on rendered appearance,
interaction, navigation, or transient UI state. Combine it with
`ux-review.md`; this guide establishes the evidence, while that guide supplies
the review lenses and prioritization.

## Declare the evidence boundary

Say which evidence was actually inspected:

- a running app that was clicked through;
- screenshots or a prototype;
- Flutter source and inferred states.

Do not turn source inference into a visual finding. Without rendered evidence,
limit claims about hierarchy, spacing, contrast, clipping, focus, animation,
and perceived responsiveness. Ask for only the missing screenshots or states
that could materially change the recommendation.

## Prefer the strongest available inspection path

1. **Interactive computer control:** When a Computer Use capability is
   available, use it to operate the Android emulator visually. Keep the flow
   scoped, capture meaningful states, and avoid changing or deleting valuable
   data.
2. **Android Debug Bridge:** When visual computer control is unavailable, use
   `scripts/android_ui.sh` to start or inspect an emulator, install and launch
   the app, navigate with taps and swipes, export the accessibility hierarchy,
   and capture screenshots. The local ADB server and emulator may require
   explicit permission to run outside the Codex sandbox.
3. **Static evidence:** If no runnable app is available, inspect supplied
   screenshots or generate the project's Appshots. Request targeted additional
   states instead of pretending the flow was exercised.

Use accessibility bounds from `dump-ui` to choose tap coordinates when
possible. Coordinate taps alone are brittle, so re-dump the hierarchy or take
a screenshot after navigation rather than assuming it succeeded.

## Android emulator workflow

Run these commands from the repository root:

```sh
.agents/skills/skidpark-product-ux/scripts/android_ui.sh avds
.agents/skills/skidpark-product-ux/scripts/android_ui.sh boot Medium_Phone
.agents/skills/skidpark-product-ux/scripts/android_ui.sh wait
.agents/skills/skidpark-product-ux/scripts/android_ui.sh install
.agents/skills/skidpark-product-ux/scripts/android_ui.sh launch
.agents/skills/skidpark-product-ux/scripts/android_ui.sh dump-ui /private/tmp/skidpark-ui.xml
.agents/skills/skidpark-product-ux/scripts/android_ui.sh screenshot /private/tmp/skidpark-ui.png
```

`boot` remains attached to its terminal, so run later commands from another
terminal or keep its process as an ongoing tool session. Use `tap`, `swipe`, and
`back` to navigate. Set `ANDROID_SERIAL` when more than one device is connected.
Use `build` before `install` when the debug APK is stale or missing.

## Review a bounded journey

Before clicking, name the scenario and the few states needed to answer the
question. Record the build, device, starting data state, inspected screens, and
important states that could not be reached. Cover failure, recovery, and
repetition only when they matter to the decision.

Separate findings into:

- observed visual or interaction evidence;
- implementation-derived facts;
- hypotheses that still need device, field, or user validation.

An emulator can reveal structure, state transitions, semantics, and obvious
visual issues. It cannot validate cold-weather handling, glare, gloves, GPS
behavior in motion, or whether a skier interprets the result correctly. Route
those claims to a field or usability check.
