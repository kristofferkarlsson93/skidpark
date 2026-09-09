# Make Product Decisions for SkidPark

Use this guide for new capabilities, product direction, prioritization, and
experiments.

## Explore an idea before converging

Assume an early idea may be a probe rather than a preferred solution. Help the
developer think by discussing:

- the underlying opportunity and the strongest version of the idea;
- the assumption most likely to make it fail;
- credible counterarguments and alternative directions;
- whether a smaller change could produce the same learning or user value;
- the evidence that would change the current recommendation.

Do not jump directly to a polished specification. When the discussion reaches a
promising direction, summarize what has been decided and what remains open,
then offer to turn it into interaction frames, a wireframe, or a product spec.

## Frame the decision

Clarify, or infer and state:

- the skier and testing situation;
- the decision or action the product should enable;
- the current workaround and its cost;
- the desired behavior or learning outcome;
- constraints from sensor validity, raw-data preservation, local storage, and
  the phone-in-hand core experience.

Do not begin with a UI component or algorithm. First establish why the change
improves recording, comparison, interpretation, or learning.

## Aim at the product vision

The long-term aim is to help many skiers choose the right skis for the day's
conditions. Evaluate ideas in both important situations:

- **Training:** quicker repeated measurements, experimentation, accumulated
  learning, and deliberate analysis.
- **Before a race:** few available runs, limited time and attention, greater
  consequence of confusion, and a need for a fast trustworthy comparison.

The likely early audience is performance-minded and often comfortable with
data, roughly Vasaloppet start groups 1–4. Keep technical depth available, but
make the main result understandable without knowledge of filtering, sensor
fusion, or statistics.

## Position and name the product

When the question concerns the app's identity, do not begin by generating a
list of names. First separate four decisions that are easy to conflate:

- the product promise and category in the skier's own language;
- which job is primary and which capabilities support it;
- the information architecture and feature labels inside the app;
- the app name and broader brand.

For SkidPark, explicitly test whether the current identity makes ski inventory
look like the main product even though glide testing is the core job. Compare at
least these credible directions:

1. keep the current name but reposition the home screen and navigation;
2. evolve it into an umbrella brand with glide testing as the clear lead;
3. rename the product around its core promise.

Evaluate the options against immediate comprehension, distinctiveness,
credibility, room for plausible future capabilities, existing recognition,
migration cost, and fit in spoken and written Swedish. Avoid names or claims
that imply scientifically proven precision before the measurement model has
earned that confidence.

Explore a few meaningfully different naming territories before individual
names. For shortlisted names, check pronunciation, spelling, unwanted
associations, and how the name works together with a concise descriptor. Treat
domain, app-store, company-name, and trademark availability as current external
facts that require live verification. Label such checks as preliminary, not as
legal clearance.

## Build an information hierarchy

When a feature presents results or analysis, design the route from overview to
depth before designing individual charts or cards:

1. **Overview:** Make the situation and important contrasts understandable at a
   glance. Show enough quality context to prevent a misleading conclusion.
2. **Explanation:** Let the user understand what drives the overview, including
   selected runs, variation, reference points, and notable limitations.
3. **Deep analysis:** Expose relevant statistics, alternative views, processing
   choices, and inspectable data for users who want to investigate further.

These are conceptual depths, not required screens. Choose navigation and
interaction only after deciding which questions each depth should answer. A
deeper level should enable a new question or decision, not add density for its
own sake.

Maintain a clear trail back to the overview and preserve selections and method
state across depths. Never reserve decisive quality warnings for an advanced
view.

## Compare viable options

Include the status quo when it is credible. Compare options on:

- value to the core solo-testing journey;
- probability and cost of user error;
- measurement validity and risk of false confidence;
- inspectability and reversibility;
- learning value given current evidence;
- implementation and maintenance cost.

Recommend one option when the discussion is ready to converge and name its main
trade-off. If evidence is too weak for a durable product choice, prefer a
reversible prototype or research step over a large implementation.

## Add smart behavior carefully

Prefer deterministic assistance where the rule can be explained and inspected:
useful defaults, contextual guidance, quality flags, preconditions, and
suggested next actions. Automation should reduce handling and memory burden,
not silently decide which ski won or hide excluded data.

For every automatic behavior, define:

- its inputs and trigger;
- what the user sees;
- how the user can inspect, override, or recover;
- behavior for missing, delayed, or contradictory sensor data;
- why its confidence is appropriate.

Do not add AI merely to make the product sound smart. Use it only when it solves
a demonstrated problem better than clear deterministic logic and can meet the
same transparency standard.

## Separate two kinds of validation

- **Product/usability validation:** Can skiers understand and complete the
  workflow in realistic conditions?
- **Measurement validation:** Does the signal and calculation reproduce known
  or independently measured differences?

State which question an experiment answers. For a lightweight experiment,
specify the hypothesis, participants or test material, task, observation or
metric, and decision rule. Use the repository validation plan for changes that
affect measurement claims.

## Produce an actionable decision

For substantial feature work, provide a compact brief containing:

1. problem and target situation;
2. evidence, assumptions, and unknowns;
3. considered options and recommendation;
4. proposed journey and important edge states;
5. measurement-integrity implications;
6. acceptance criteria;
7. smallest validation or implementation slice.

Prefer one coherent direction over a catalogue of features. Mark later ideas as
deliberately deferred so they do not silently expand scope.
