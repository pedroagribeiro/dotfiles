---
name: support-ticket-analysis
description: >-
  Investigate a Nutrium/Healthium Jira support ticket (the "IT" / Tech Support
  project) end-to-end and produce a European-Portuguese analysis comment posted
  on the ticket. Use this whenever Pedro references a support/tech-support ticket
  by key (e.g. "analisa a IT-33", "vê o ticket IT-70", "support ticket"), asks to
  investigate a reported bug or a patient/nutritionist complaint, mentions an
  "aviso fantasma"/"marcação fantasma" or similar user-reported anomaly, wants
  a Jira comment written in the house analysis style, or wants to **continue /
  resume an analysis already in progress** on a ticket (e.g. "continua a IT-33",
  "retoma a análise", "já confirmei em produção, fecha a IT-90"). Trigger even
  when the word "skill" is never used and even if only a ticket ID is given — a
  bare "IT-NN" is enough. Handles fetching the ticket, picking up any prior
  analysis already on it, tracing the root cause in the codebase, deciding whether
  it is even a bug, writing the PT-PT analysis, validating it with Pedro, and
  posting it as a comment in his name.
---

# Support Ticket Analysis (Healthium / Nutrium)

Investigate a Jira support ticket, find the real root cause in the codebase,
and hand Pedro a polished European-Portuguese analysis to post as a comment in
his own name. The value is in getting the *diagnosis* right — a confident,
well-written comment built on a wrong root cause is worse than no comment.

## Environment (bake these in, don't rediscover)

- Jira site: `nutrium.atlassian.net` — cloudId `be0a3a51-0216-4a52-857c-a642ed5f5cd2`.
- Support project key: **IT** ("Tech Support"). Tickets look like `IT-33`, `IT-70`.
- Main codebase for investigation: the `nutrium` Rails + React repo (usually the
  current working directory). Follow its `CLAUDE.md` (`docs/` architecture rules,
  the local host-run command notes, PT-PT copy rules).
- The **patient/nutritionist mobile apps are a separate codebase** — not in this
  repo. When the bug is plausibly client-side (e.g. an outdated app version is
  named in the ticket), say so instead of forcing a server-side explanation.
- Reporters often write in **Brazilian Portuguese**. The analysis you write is
  **European Portuguese (PT-PT)** — see the style section.

## Workflow

Work the phases in order. Don't jump to writing the comment before the
investigation is genuinely done — the whole point is a correct diagnosis.

### 1. Get the ticket ID

If Pedro gave a key (`IT-33`), use it. If not, ask for it — one short question,
don't guess.

### 2. Fetch the ticket in full

Use `getJiraIssue` with `fields: ["*all"]`, `responseContentFormat: "markdown"`,
and include comments. Read: summary, description, **all comments** (prior triage
often holds the key), reporter, status, and the **attachment list**.

Screenshots ("prints") are common and often decisive (an Amplitude event, the
patient-side view). You usually can't render them directly. If a screenshot
clearly matters to the diagnosis, tell Pedro what it seems to show from the
surrounding text and ask him to confirm/describe it rather than guessing.

**Check whether the analysis is already in progress.** A ticket is often not a
blank slate: prior comments may hold a partial or full analysis (frequently
authored by Pedro or the team), a preliminary conclusion left open pending a
production check, a question raised for the reporter, or new information added
since. The current conversation may also already contain analysis. When any of
that exists, switch to **resume mode** (below) instead of re-deriving from zero.

### 3. Investigate the root cause — use systematic debugging

Load and follow `superpowers:systematic-debugging`. The iron law applies: **no
conclusion without root-cause investigation first.**

- **Restate the report as concrete conditions**: exact dates (with years),
  statuses, which side sees it (web vs app), app version, what's confirmed clean.
  Ambiguity here is where wrong diagnoses come from.
- **Fan out into the codebase** with `Explore` / `general-purpose` subagents to
  find the relevant models, controllers, serializers, jobs, decorators.
- **Then read the actual code yourself and verify the hypothesis holds under
  this ticket's conditions.** Do not trust the first grep hit. (Real example
  from IT-33: an Explore pass flagged a year-blind date comparison in a
  decorator, but reading it showed the branch only runs for *future* dates and
  is web-only — a red herring for that ticket.) Check the guards, the dates, the
  platform, the statuses — confirm the code path can actually produce *this*
  symptom.
- **Decide whether it's even a bug.** Many tickets are expected behaviour or a
  user action (IT-70: the patient herself rescheduled — no bug). The verdict
  shapes the entire comment, so settle it before writing.
- **Rule out the obvious alternatives explicitly** (duplication, recurring/cloned
  records, a known-but-unrelated bug, stale client/app version) and note what you
  checked — reviewers trust a diagnosis more when the ruled-out paths are named.
- **Prefer evidence you can gather yourself, in this order — production is a last
  resort.** Reading production has a real cost: Pedro has to ask a colleague to
  run it. So exhaust the cheaper sources first:
  1. **The code + the Jira ticket** (description, comments, attachments) — often
     enough on their own.
  2. **Amplitude** — pull it from the **Amplitude MCP** (load its tools via
     `ToolSearch`; it's a claude.ai connector, so if it isn't connected ask Pedro
     to run `/mcp` → "claude.ai Amplitude" to authenticate). Amplitude answers the
     behavioural questions — "did the patient do this herself?", "is there recent
     activity for this account?", "which app version / event fired?" — and a
     concrete event is often the strongest, record-level proof (it's what closed
     IT-70). Verify as much as possible here before considering production.
  3. **Production DB read — only if code + Amplitude still can't close it.** This
     is the production-check section (below). Because it costs a colleague's time,
     make it a single, complete, one-shot query — never an iterative back-and-forth.
- **Say plainly what's proven vs. still open.** If the code proves it, say so. If
  it needs Amplitude or a production read to be certain, name exactly which
  question is open and which source will answer it.

### 4. Rescope / clarify whenever needed

Challenge the report's framing. If information is missing (email, exact date,
which platform) or the framing seems off, ask Pedro before writing. Don't
invent facts to fill gaps.

Also **ask Pedro whether there are screenshots ("prints") or other elements he
wants included** in the analysis. Support colleagues often find an attached
image (an Amplitude event, the patient-side view) more convincing than prose, so
surfacing the right one in the comment adds real value — but which to include is
his call, so ask rather than assume.

### 5. Write the analysis comment (PT-PT house style)

Match the house style used on IT-70 / IT-33. See **The comment format** below.
Produce the full comment, then **stop and validate with Pedro** — never post
before he approves. Offer, if he wants, the annotated `.h2` / `.p` review form
(a per-block formatting map he sometimes asks for).

### 6. Post as a comment in Pedro's name

Only after explicit approval. Post with `addCommentToJiraIssue` (markdown body)
on the ticket. The comment is authored by the authenticated account (Pedro), so
write it in his voice. After posting, give him the ticket URL.

## Resuming an in-progress analysis

When a ticket (or the conversation) already carries analysis, the job is to
**advance it, not restart it.** Starting from scratch wastes effort and, worse,
can silently contradict what's already on the ticket — confusing for whoever
reads it next.

- **Read what's already there first** and locate the open thread: is it a
  preliminary conclusion waiting on a production check? A question to the
  reporter? A hypothesis half-verified? New info that changes things?
- **Continue from that point.** Re-verify in code only what you actually need to
  move it forward — don't redo the whole investigation if the prior analysis was
  sound. If new evidence arrived (a production result, an Amplitude event, a
  screenshot, a reporter reply), fold it in.
- **Preserve continuity of voice and reasoning.** Build on the earlier finding
  rather than restating it. The most common resume is turning an *Análise
  preliminar* into a closed *Conclusão* once the production check confirms it:
  the follow-up says what was confirmed and settles the verdict.
- **If you now disagree with the earlier read, say what changed** — don't quietly
  reverse it. Name the new evidence that moved the conclusion.
- **Output shape — keep it to ONE comment on the ticket, with a clear call-to-
  action.** Two analyses on the same ticket (a preliminary plus a conclusion)
  confuse the support colleague who reads it. When you close a preliminary,
  **edit the existing comment in place** into the single consolidated conclusion —
  folding in what the preliminary said and ending with one explicit next step for
  support (e.g. "confirmar com a paciente se o aviso desapareceu") — rather than
  adding a second comment. The Atlassian MCP can add/update but **cannot delete**
  comments; if a now-redundant comment remains, reduce it to a one-line pointer to
  the consolidated one and ask Pedro to delete it in the Jira UI. Validate the
  consolidated text with Pedro before editing the live comment.

## The comment format

The house style is deliberately plain: **one H2 heading (the title) and the rest
flowing prose.** No sub-headings (except the optional production-check section),
no bullet lists, no emojis, confident domain language a support agent or
nutritionist can follow. Technical tokens (`status=completed`, `accepted_at`) go
in inline code.

Template:

```
## Análise — "<título curto>" (<contexto: data / paciente / nº da marcação>)

**<Conclusão:|Análise preliminar:>** <veredicto direto em 2–4 frases — é bug? não
é bug? causa provável? — em linguagem de domínio, não de código.>

<Parágrafo do mecanismo: o que se passa, explicado para quem não lê código.>

<Parágrafo das hipóteses descartadas: o que verificaste no código e porque não é
isso.>

<Parágrafo final: próximo passo / correção sugerida, se aplicável.>

_(Análise assistida por IA, revista e aprovada por Pedro Ribeiro.)_
```

Rules:

- **Lead in bold.** Use `**Conclusão:**` when the diagnosis is settled and proven
  (like IT-70). Use `**Análise preliminar:**` when it still needs a production
  check to be certain (like IT-33). Being honest about certainty is the point —
  don't dress a preliminary finding as a closed conclusion.
- **PT-PT, not PT-BR.** Write in European Portuguese even though the report is
  often Brazilian: e.g. *utilizador, ecrã, marcação, a fazer* (not *fazendo*),
  *está/consegue*. Keep the app's own domain terms (consulta, marcação, plano).
- **Minimal AI marker, always.** End with a single discreet line —
  `_(Análise assistida por IA, revista e aprovada por Pedro Ribeiro.)_` — nothing heavier.
  The comment is posted under Pedro's name and he reviews/approves it before it
  goes out, so the marker both flags the AI provenance and makes his sign-off
  explicit — without dominating the comment.
- **No confidence tags in the comment.** The `[ Certain ]` / `[ Likely ]` tags
  from the repo's chat rules are for chat, not for the Jira comment; express
  certainty in prose (preliminar vs conclusão) instead.

## Production-check section (last resort — only when code + Amplitude can't close it)

Reach for this **only after the code and Amplitude have been exhausted** — a
production read costs Pedro a request to a colleague, so it's the last resort, not
the default. When it's genuinely needed, add **one clearly labelled section** with
the read-only commands, right before the closing paragraph. Make it unmistakable
that these are **read-only** and change nothing.

```
**Como confirmar em produção** (comandos apenas de leitura — não alteram nada):

​```ruby
# ... console script that only reads/prints ...
​```

<Uma frase a dizer o que confirma o resultado: "se aparecer X=... e Y=..., a
causa fica provada.">
```

Hard rules for these commands:

- **Read-only only.** Never `update`, `save`, `destroy`, `!`-mutators, jobs, or
  anything that writes. This runs against production. Only lookups and `puts`.
- **Verify models before writing the script** — follow the `nt:console-data`
  skill's core rule (read the model / enums first) so the script runs first try.
  Reference the real enum classes (`AppointmentStatus.new(id).codename`,
  `SchedulingStatus`), not raw integers, and look records up by the identifier the
  ticket gives (usually the patient's account email).
- Keep it tight: find the record(s), print the fields that decide the diagnosis,
  and (when useful) a filtered list of the suspect rows.
- **Assume one shot.** Because each run costs a colleague's time, pull everything
  the diagnosis needs in a single script: the record's identity, the deciding
  fields, AND the suspect rows — so one run is conclusive and nobody is asked twice.
- **Disambiguate the subject first.** Confirm you're on the right patient/record
  before concluding: list every record for that account and cross-check against
  the professional who reported it. A wrong record yields a confident-but-wrong
  read — see IT-33.

## Quick reference — worked examples

- **IT-70** ("Marcação fantasma?") — verdict: **not a bug**. Patient rescheduled
  herself; Amplitude screenshot proved it. Style: `## Análise —`, bold
  `Conclusão:`, three prose paragraphs, no code. Use as the tone/format anchor.
- **IT-33** ("Aviso fantasma") — a cautionary example. The preliminary read (a
  completed-but-`unconfirmed` appointment resurfacing as "pending") looked solid
  from the code, but the production data **refuted** it: no `unconfirmed`
  appointment existed at all, and the queried record didn't even match the
  ticket's narrative (no Dec 8 appointment, no 2026 activity — a wrong/old patient
  record was suspected). Lessons, now baked in above: never rubber-stamp a
  preliminary hypothesis when the confirming data arrives — verify it actually
  holds; and disambiguate you're on the right patient/record before concluding.

## Tools

- Fetch: `mcp__…__Atlassian__getJiraIssue` (fields `*all`, markdown, with comments).
- Post: `mcp__…__Atlassian__addCommentToJiraIssue` (markdown body) — approval-gated.
  The same tool **updates** a comment when given `commentId`; there is **no
  delete-comment tool**, so consolidate by editing in place (see resume mode).
- Both take `cloudId: be0a3a51-0216-4a52-857c-a642ed5f5cd2`.
- Behavioural evidence (prefer over production): the **Amplitude MCP**
  (`mcp__…__Amplitude__*`) — a claude.ai connector; if not connected, ask Pedro to
  run `/mcp` → "claude.ai Amplitude" to authenticate.
- Investigation: `Explore` / `general-purpose` subagents + reading the code.
- These are deferred tools — load their schemas with `ToolSearch` first.
