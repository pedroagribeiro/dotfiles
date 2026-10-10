---
name: feature-onboarding-doc
description: Produce a technical onboarding document for a feature, subsystem or project — the kind a new team member reads to understand a data model, a flow, the endpoints and the async machinery, and then starts working. Use this whenever someone asks to document a feature or project for the team, write an onboarding or handover doc, explain a subsystem to new joiners, produce a Confluence/Notion technical page about how something works, or capture "the model that's in vigor" before knowledge is lost. Also use it when asked to document an integration with a third-party API, or to write up an architecture for people rather than for a PR. Trigger even when the word "onboarding" is never said — "write up how the X feature works for the team" is this skill.
---

# Feature onboarding documents

## What makes these worth writing

A reader can already read the code. If the document only describes what the code says, it is
redundant on the day it ships and wrong a month later.

The value is in everything that is **not recoverable by reading the code**:

- **Why** a shape was chosen, especially where it looks odd
- **What is missing** — classes with no callers, deferred phases, endpoints that don't exist yet
- **What surprised us** — vendor quirks, constraints learned by probing, the joins people get wrong
- **What will waste a newcomer's afternoon** — the test environment that can't reproduce the bug, the
  debugger that silently doesn't work

Keep that distinction in mind the whole way through. When a section starts restating method bodies,
cut it and replace it with the reason the method is shaped that way.

## Before researching: settle two things

Getting these wrong means rewriting, so ask up front rather than guessing.

1. **Where does the document stop?** Features bleed into each other. Decide the boundary so you know
   what to research — but keep it to yourself. A reader does not need a scope disclaimer, and these
   documents are usually living: the next phase gets written into the same file, at which point a
   sentence announcing what the document excludes is simply wrong.
2. **How are diagrams authored?** Mermaid in fenced blocks is usually right — Confluence and GitHub
   render it, and it diffs as text. ASCII if the destination can't render Mermaid.

## This is documentation, not a status report

The strongest temptation when documenting work in flight is to write down where it is: what shipped,
what is in review, which PRs are open. Resist it. Those facts are stale within days, they turn a
reference into a snapshot, and a reader six months later cannot tell which parts have rotted.

Keep the distinction sharp in the text itself:

- **"This is deferred and the write side has no caller"** is documentation. It describes the system's
  actual shape, and a reader who builds on that method needs it.
- **"PR #531 is open and awaiting review"** is a status update. It belongs in a ticket.

The test: would the sentence still be true and useful if nobody updated the file for a year? If not,
either cut it or rewrite it as a property of the system rather than a position in a workflow.

## Research order

Order matters. Each step makes the next one cheaper, and reading in the wrong order produces a doc
that describes classes rather than a system.

### 1 · Inventory by layer, don't read yet

List filenames first. The shape of the feature is visible in the file list, and it immediately shows
what exists versus what you assumed existed.

```bash
git ls-tree -r --name-only <ref> | grep -iE "<feature>" | grep -E "^app/(models|services|controllers|jobs)/"
git ls-tree -r --name-only <ref> | grep -E "^db/migrate/" | grep -iE "<feature>"
```

Use a `<ref>` (branch or tag) rather than the working tree when the feature lives on a branch that
isn't checked out — `git show <ref>:<path>` reads files without disturbing anyone's work.

### 2 · Migrations before models

Migrations carry the constraints, and **constraints encode business rules more reliably than code
does**. A partial unique index, a composite unique key, a null constraint — each one is a rule
somebody decided to enforce at the database. These are the most durable facts in the whole document.

When you find one, work out what rule it protects and say that, not what the index is.

### 3 · Models next

Associations give you the entity graph. Comments in models are usually the highest-quality prose in
the codebase — the author was explaining themselves. Harvest them.

Watch for the association that **isn't** where a newcomer would look for it (a profile hanging off an
account rather than a user, a record keyed by something non-obvious). That is a prime candidate for
the "this will catch you out" callout.

### 4 · The core service before the endpoints

Every feature has one or two objects where the design actually lives — a reconciler, an orchestrator,
a state machine, a mapper. Find those and read them properly. The endpoints are mostly plumbing on
top, and they make sense only after you understand the core.

### 5 · Find what isn't built

This is the step most people skip, and it produces the single most valuable paragraph in the document.

```bash
# a class or method with no callers is usually a deferred phase, not dead code
grep -rn "ClassName" app/ spec/ | grep -v "class ClassName"
```

Look for: methods with no callers, endpoints defined but not routed, TODO/deferred ticket references,
features behind a flag that is off everywhere. A document that presents a half-built system as
finished is worse than no document — it sends people to build on foundations that aren't there.

### 6 · Contract specs are the assumptions ledger

Many integrations have a spec file that pins what the team *believes* about an external system. Find
it. It separates verified behaviour from assumption, and that distinction belongs in the doc —
readers need to know which facts are load-bearing guesses.

### 7 · Harvest hard-won operational knowledge

Vendor quirks, probe results, environment gotchas. These are rarely written down anywhere and they are
exactly what a newcomer burns days rediscovering. Check memory files, past tickets, and your own
session history. Date them and say they should be re-verified — they go stale silently.

## Structure

Adapt freely, but this ordering works because each section answers a question raised by the one
before. Numbered headings help people cite sections in review.

1. **What this is** — the problem in a paragraph, who the external parties are, and the two or three
   principles that explain the rest of the design. Name each principle on its own axis; if two
   pressures are doing different work (say, latency and cost), separating them here saves confusion
   in every later section.
2. **Glossary** — six or seven terms, especially any that sound alike. Everything downstream depends
   on these meaning one thing.
3. **When the feature is reachable** — gates, flags, preconditions. This is small and easy to scatter,
   and scattering it is a mistake: it answers "why is my request refused and why does nothing in the
   logs explain it", which is among the first questions a newcomer actually has.
4. **Data model** — ER diagram, how it plugs in to what already exists, the constraints that encode
   rules, and the lifecycle (what happens on deletion, archival, erasure). Call out the association
   people get wrong.
5. **The main flow** — flowchart. Mark clearly which steps are synchronous, which are async, and which
   are **not built**. Link to external docs where the vendor's semantics, not yours, are authoritative.
6. **How async work completes** — if anything settles out of band, this is the section most likely to
   be misunderstood. A sequence diagram plus numbered rules, each with its reason. Include how
   deliveries are authenticated — signature schemes differ between integrations and get miscopied.
7. **Configuration** — the credentials and environment variables the feature introduced: the key paths,
   never the values, a skeleton showing where they nest, and what the failure looks like when one is
   missing. Easy to forget because it is obvious to whoever wrote it, and the first thing that stops a
   newcomer.
8. **Where to look** — annotated file map, and which specs pin which behaviour.

Those eight are the spine. Three more earn their place often enough to consider, but are genuinely
optional — judge each against the audience rather than including it by reflex:

- **Error contract** — the *shape* callers must handle and any invariant they can rely on, not an
  enumeration. Worth a section when two channels look alike and get confused.
- **Deliberate trade-offs and rough edges** — decisions with reasons, never a TODO list. This is where
  a document earns trust: one that admits its compromises gets believed about everything else.
- **Working against the test environment** — what the sandbox cannot reproduce, vendor constraints,
  runnable snippets. See below. The most useful to a newcomer and the fastest to date; some teams
  would rather it lived in a runbook, which is a reasonable place for it.

### Do not restate the API

There is a strong pull toward an endpoint section — a table of routes, parameters, status codes, a
sample response. Resist it whenever a contract tool already owns that surface: OpenAPI, Stoplight,
Swagger, a published schema. Two descriptions of the same API will drift, and when they do, nobody can
tell which one lies. Name the authority instead, and say that the code wins over this file.

What survives is the part a contract file cannot express:

- **Why** an endpoint behaves oddly — why a read is a `POST`, why a create returns a pending resource
- **Which step of the flow** it serves, which belongs in the flow section anyway
- The **data principle** behind the response — what is stored versus computed or fetched on the way
  through, which explains why fields are empty without the reader guessing

Mentioning a route inside a flowchart or sequence diagram is not restating the API; it is saying what
happens when. That is fine and usually necessary.

## Make it executable — this is the section most likely to get dropped

Every other section can be written by reading carefully. This one cannot, which is exactly why it is
the one that gets skipped under time pressure and the one that most distinguishes a useful document
from a competent summary. **If you are running short, cut depth from the structural sections before you
cut this.**

A reader should be able to *do* something within a minute of finishing. That means actual commands:

```ruby
# the entry point a newcomer would reach for, with realistic output shown
SomeService.check(subject, key: 'value')
# => #<struct status="available", count=42, error=nil>
```

Include:

- A snippet per major path — not one example, one per thing someone will want to try
- Which snippets are read-only, and which write rows, cost money or call a vendor
- The debugging approach that **actually works** in that environment, and the one that looks like it
  should but silently doesn't

That last point is worth hunting for specifically. Debuggers that don't attach, test environments that
can't reproduce the interesting case, a gem that isn't loaded outside development — these cost people
whole afternoons and appear in no file. Ask what the team already knows and write it down.

Where it ends up is the author's call — this material also makes a good runbook, and a team that keeps
runbooks separately is right to put it there. What is not defensible is losing it, because nowhere
else is it written down at all.

## Writing

**Lead with the correction, not the description.** A newcomer arrives with wrong assumptions. Sections
that open by naming the wrong assumption land harder than ones that build up from first principles.

**Prefer the load-bearing detail over the complete list.** Five rules that each matter beat fifteen
that include the obvious. If something is inferable from a method name, leave it out.

**Expect the first draft to be about twice as long as what survives.** This is reliable enough to plan
for: a careful first pass produces a complete, well-organised document that a reviewer then halves,
and the halved version is better. Knowing it is coming changes what you do with it — do not defend
length, and when you reread your own draft, ask of each section not "is this true" but "would someone
cut this, and would they be right". Depth in the two or three sections carrying the real design beats
even coverage across ten.

**Tables for comparison, prose for reasoning.** A table that needs a "why" column should have been
prose. Watch table width — a markdown row cannot wrap, so a wide table either breaks rendering or
blows past a line-length limit. If rows won't fit, use a bold label with indented sub-bullets.

**Keep diagrams narrow.** A diagram that runs off the right edge is not read, and ER diagrams are the
usual offender: renderers lay attribute blocks out side by side, so four entities with six columns
each becomes unreadable. Put the entities and their relationships in the diagram and the columns in a
list underneath. The diagram's job is the shape; the detail reads better as text anyway.

**Annotate columns with type, nullability and provenance.** A bare column name is barely worth
listing — the reader could have run `\d table`. What they cannot get that way is where each value
comes from, and in an integration that is the whole question:

```
`insurance_policies`
- `bridge_policy_id` (string) (from Bridge)
- `state_code` (string) (as the patient may change it after the policy was created)
- `resolution_source_id` (integer | nil)
```

Marking which identifiers belong to the third party makes the ownership boundary visible in the data
itself. It also tends to make a prose section explaining "what we store versus what we fetch"
unnecessary, which is a good trade — showing beats explaining.

**Parallel rules want bullets, not a run of paragraphs.** Four constraints, five invariants, three
statuses: when items are the same kind of thing, a bulleted list with a bold label lets a reader scan
for the one they need. Reserve paragraphs for reasoning that genuinely flows.

**Don't cross-reference by section number.** "See §8" breaks the moment a section is added, cut or
reordered — and in a living document that happens constantly. Name the thing instead: "the reconciler",
"the webhook section". If something is needed in two places, the second mention is usually a sign it
belongs in only one of them.

**Date anything probed.** "No DELETE endpoint (probed 2026-09-21)" ages honestly; "there is no DELETE
endpoint" becomes a lie without warning.

**Integrate late facts, don't append them.** Something always turns up after the structure is set — a
second gate, a deletion path, an auth scheme. The cheap move is to bolt a paragraph onto whichever
section is nearest, and it is always visible: the reader hits a data-model section that suddenly
discusses HTTP status codes. Ask where the fact *belongs*, and if there is no good home, that usually
means a section is missing rather than that the fact is minor. Adding one costs less than the
confusion of a misfiled paragraph.

## Verify before handing over

Mechanical checks, fast, and each one catches a real class of defect:

```bash
awk 'length > 120 { print NR" ("length")" }' <file>   # long lines, if the house style wraps
grep -n "^## " <file>                                  # section numbering after any insert
grep -c '```mermaid' <file>                            # diagrams survived editing
```

Then re-read the whole thing for the two failure modes the mechanical checks can't see: a paragraph
sitting in the wrong section because it arrived late, and any sentence that is really a status update
wearing a documentation sentence's clothes.

Finally: ask where it should live. A doc in a scratch directory helps nobody. Offer the repo (versioned
beside the code it describes, on the branch that owns that code) or the team's wiki, and say which you
recommend and why.
