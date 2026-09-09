# Review an Existing SkidPark Experience

Use this guide for a screen, flow, prototype, UX-copy, or implementation review.

## Build the journey before judging it

Identify the relevant scenario, entry point, steps, exit, and recovery paths.
Inspect only the states that matter to the request. Common high-value states
include:

- first use and empty collections;
- preparing a test and selecting a ski;
- unavailable, weak, or improving GPS;
- ready, starting, recording, detected stop, save, abort, and failure;
- no runs, one run, multiple selected runs, and excluded runs;
- overview, averaged runs, release-point analysis, and processing changes;
- poor-quality, incomplete, contradictory, or suspicious data.

Account for navigation back to the previous task and for repeated runs. The
core workflow should become faster after the first run, not repeatedly demand
setup intended only for first use.

Identify whether the journey is primarily used during exploratory training or
under pre-race time pressure. Test the same design against both situations, but
do not assume they require separate modes.

## Review lenses

Apply the lenses that can materially change the result:

1. **Task clarity** — Can the skier tell what to do now, what is happening, and
   whether the action succeeded?
2. **Field interaction** — Are primary actions operable with limited attention,
   one hand, movement, gloves, and a hard-to-read screen? Treat these as
   hypotheses until observed with users.
3. **Prevention and recovery** — Can the user avoid selecting the wrong ski,
   starting before GPS is usable, discarding a valid run, or confusing an
   incomplete run with a valid one?
4. **Information architecture** — Does the structure emphasize glide testing
   and keep inventory, settings, and advanced analysis in supporting roles?
5. **Interpretation** — Are labels, units, reference points, selected runs,
   processing choices, and comparison meaning clear?
6. **Measurement honesty** — Does the view expose relevant quality limitations
   and avoid implying that an estimate is ground truth?
7. **Accessibility** — Check contrast, scale, touch targets, semantics, focus
   order, and non-color cues. Do not infer rendered compliance from Dart source
   alone.
8. **Language** — Make Swedish copy short, consistent, action-oriented, and
   understandable without knowledge of signal processing.
9. **Layered expertise** — Does the first level explain the situation clearly,
   while deeper levels answer progressively more advanced questions? Let
   experienced skiers inspect meaningful detail without requiring less
   technical users to understand algorithms before they can record and compare
   runs. Check that selections, units, methods, and quality state remain
   consistent as the user moves between depths.

## Prioritize findings

Use severity only when it helps decision-making:

- **Critical:** credible safety risk, irreversible data loss, or blocked core
  journey.
- **High:** likely invalid capture, serious misinterpretation, or major failure
  in the record-and-compare workflow.
- **Medium:** recurring friction, weak discoverability, or avoidable cognitive
  load.
- **Low:** polish with limited effect on task success.

For each material finding, provide the observed evidence, affected state,
consequence, confidence, and smallest viable improvement. Avoid long generic
heuristic checklists and pixel-level prescriptions unsupported by a rendered
view.

## Finish with verification

Turn the preferred improvements into observable acceptance criteria. Recommend
the lightest suitable check: source review, widget test, device walkthrough,
think-aloud usability session, field test, or measurement validation. Do not
use a usability test to validate sensor accuracy, or an A–A sensor test to claim
that users understand the interface.
