---
name: cross-platform-contract-check
description: >-
  Cross-platform contract analysis of a Nutrium feature across the four
  repositories that have to agree on it — the Rails backend (`nutrium`, a.k.a.
  nutrium-web), the Kotlin Multiplatform library `nutrium-mobile-shared`,
  `nutrium-ios` and `nutrium-android`. Use whenever Pedro asks whether a feature's
  contracts "casam" between platforms, wants to know if something can break between
  backend, shared lib and the apps, asks for a cross-platform / cross-repo review of
  a feature, ticket or set of PRs, mentions API/DTO/serializer mismatches, enum or
  nullability drift, push-notification or deep-link payloads, KMP version pins, or
  old app versions in the wild breaking after a backend change. Trigger on phrasings
  like "análise cross platform da feature X", "vê se os contratos batem", "isto parte
  no iOS?", "o Android e o iOS fazem o mesmo?", "confirma que o backend e a shared
  estão alinhados", even when only a feature name, a Jira key or PR links are given.
---

# Cross-platform contract check (Nutrium)

A feature at Nutrium is usually spread over up to four codebases, written by different people
at different times, and released on different schedules. Each edge between them is a contract
nobody wrote down: there is **no OpenAPI, no JSON schema and no shared fixtures**. The
contract only exists as "what the serializer emits" on one side and "what the DTO tolerates"
on the other.

The job is to reconstruct each contract from both sides, line them up, and find the places
where they disagree — or agree today but will stop agreeing on the next deploy or with the
app version a patient hasn't updated in eight months.

A finding is only worth reporting with **evidence on both sides** (`file:line` of the producer
and of the consumer). "The backend might send null here" is a hunch; "`GoalSerializer#target`
returns `nil` for archived goals (`app/serializers/goal_serializer.rb:31`) and
`GoalResponse.target: Double` has no default (`…/GoalResponse.kt:14`), so the whole goals
list fails with `InvalidJsonResponse`" is a finding.

## The topology

```
             nutrium (Rails, public_api /v2, AMS snake_case)
            /                   |                         \
   nutrium-mobile-shared    nutrium-ios legacy          nutrium-android legacy
   (KMP DTOs, kotlinx)      (Alamofire+SwiftyJSON)       (Retrofit+Gson)
       /         \
 nutrium-ios   nutrium-android
 (via SKIE)    (direct Kotlin)
```

Plus side channels that skip the shared lib entirely: **push payloads** (FCM), **deep-link
hosts**, **`enabled_features` flags**, and the **KMP version pinned by each app**.

The shared lib has no HTTP engine; each app injects its own client, so headers and auth are
app-owned even for "shared" features. And a given feature can be shared on one platform and
legacy on the other — find out, don't assume.

Read `references/platform-map.md` before starting: it has the paths, configs and conventions
for each repo so you don't rediscover them. Read `references/breakage-checklist.md` before
the matching phase: it is the list of concrete ways these contracts break here.

## Workflow

### 1 · Pin down the feature and the refs

Ask (one short message, only what you can't infer):

- **Which feature**, and a hint to locate it — a Jira key, PR links, an endpoint, a screen.
- **Which ref in each repo.** Default is the integration branch (`origin/master` for `nutrium`,
  `origin/dev` for the three mobile repos) plus any feature branches/PRs Pedro names. A
  half-merged feature analysed at `dev` alone gives false "missing" findings.

If you can't ask (running as a subagent, or Pedro said "just go"), take the defaults and record
them, with commit SHAs, under **Âmbito**.

Read code at a ref with `git -C <repo> show <ref>:<path>` and `git -C <repo> grep <pattern> <ref>`
— **never check out branches**: these are Pedro's working trees, often mid-work. `git fetch` is fine.

Also record the **KMP version pinned** by each app at the chosen ref (see platform map). If
the shared-lib change for this feature isn't in the pinned release, that alone is a finding.

### 2 · Inventory the contract surface — one subagent per repo, in parallel

Dispatch four `general-purpose` subagents in a single message (not `Explore` — this needs
exact reading, not excerpts). Each gets: the repo path, the ref, the feature hints, the
absolute path of `references/platform-map.md` with the section heading to read (point, don't
paste), and the **output contract below**. Each returns a structured inventory, not prose:

```
ENDPOINTS        method · path · auth? · request params/body (name, type, required?, nullable?)
RESPONSE FIELDS  endpoint · json path · type · nullable? · omitted-when? · enum values · date format
                 (backend: what is EMITTED; clients: what is EXPECTED and what happens if absent/null/unknown)
ERRORS           status · body shape · error codes the producer emits / the consumer matches on
ENUMS            name · full value set (ids or codenames) · unknown-value behaviour (clients)
PUSH             type string · payload keys read/written
DEEP LINKS       hosts/paths generated (backend) / handled (apps)
FLAGS            enabled_features keys produced / checked
PUBLIC KMP API   (shared + apps) facade signatures, sealed subtypes, how the apps consume them
CLIENT STATE     (shared + apps) caches: cache-first reads, when they refresh (forceRefresh
                 callers), what logout / account switch clears; what the UI does when a read FAILS
                 (error state, or rendered as empty?) and what the next write then sends
                 (full list vs delta, upsert that reconciles away missing items)
VALIDATION       limits each side enforces (lengths, ranges, required) and HOW it counts
                 (Swift graphemes vs Ruby codepoints vs Kotlin UTF-16)
EVIDENCE         every row carries file:line
```

Tell the backend agent to resolve the **actual rendered shape**: which serializer, which
adapter (`json_api` default vs `adapter: :json, root:` overrides), which `key:` renames — by
reading the controller's `render` call, not by guessing from the model.

### 3 · Line the contracts up — you do this, not a subagent

Build one matrix per edge from the inventories. For each field / enum / error / push type /
deep link, one row with what each side does:

| Item | Backend emits | Shared expects | iOS (shared or legacy) | Android (shared or legacy) |
|------|---------------|----------------|------------------------|----------------------------|

**Compare sets with a script, never by eye.** Enum values, key lists, push types, deep-link
hosts: extract each side's list with `git grep`/`git show`, sort, and `diff`/`comm`. Subagents
miscount long lists (a 66-value enum came back as 66, 68 and 71 from three agents); one `comm`
settles it.

Then walk `references/breakage-checklist.md` against the matrix. The checklist is where the
real bugs are; a matrix with every cell "string, matches" usually means the inventory was
shallow — go back for nullability, unknown values and omitted keys.

Two kinds of disagreement matter, keep them apart:

- **Contract mismatch** — producer and consumer disagree; something fails or silently loses data.
- **Platform divergence** — iOS and Android each match the backend but behave differently from
  each other (one drops unknown enum values, the other crashes; one handles a deep-link host,
  the other ignores it). Users experience these as "works on my wife's phone".

### 4 · Verify every candidate before reporting

For each candidate finding, re-read both sides at the ref yourself — a handful of targeted
`git show` / `git grep` calls is usually enough; only fan out verifier subagents when there are
many candidates. Classify:

- **Confirmed** — traced both ends, the failure path is concrete (what input → what happens).
- **Plausible** — one side is confirmed, the other depends on data you can't see (e.g. whether
  production ever has `nil` there). Say exactly what would confirm it — a query, a Bruno request
  in `nutrium-api/v2`, a log search.
- **Dropped** — say nothing about it.

### 5 · Report

Write in **European Portuguese** (code identifiers stay as they are). Shape:

1. **Veredicto** — one or two sentences: do the contracts match, and what's the worst thing found.
2. **Âmbito** — feature, refs analysed per repo, KMP pins, which platforms use shared vs legacy
   for this feature. Short.
3. **Problemas** — ordered by severity, each with: what breaks, for whom (all users / iOS only /
   apps older than X / after next backend deploy), evidence on both sides, and the smallest fix
   and *which repo* it belongs in. Severity scale:
   - 🔴 parte já ou parte no próximo deploy
   - 🟠 parte versões antigas da app em produção, ou só com dados específicos
   - 🟡 divergência iOS/Android ou fragilidade latente
4. **Contratos verificados** — the matrix (condensed), so Pedro can see what *was* checked and
   matched, not just the failures. Absence of findings is only meaningful if coverage is visible.
   Checklist items that don't apply to the feature go in one line ("N/A: paginação, flags, v0/v1"),
   not a row each.
5. **Não verificado** — what couldn't be checked and why.

Keep it in the terminal unless it's long or Pedro wants to share it; then offer an artifact
(the `artifact-style` skill applies).

## Common mistakes

- **Analysing only the happy path.** The interesting rows are null, absent, unknown enum value,
  empty list, error body, and old app version. Each checklist item exists because it has bitten.
- **Trusting the model instead of the serializer.** The column exists ≠ it's emitted; the
  attribute exists ≠ it has that key (`key:` renames) or that envelope (`root:` overrides).
- **Assuming both apps go through the shared lib.** Check each platform's imports for the feature.
- **Forgetting deployed app versions.** The backend deploys continuously; apps don't update.
  Removing, renaming, retyping or newly-requiring anything is a break for every installed version
  that still sends/reads the old shape, even if all four `dev` branches agree.
- **Reporting a mismatch from one side's code alone.** No evidence on both sides, no finding.
