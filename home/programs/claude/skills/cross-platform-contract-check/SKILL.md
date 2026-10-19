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

### 1 · Find the feature in every repo

Read code at a ref with `git -C <repo> show <ref>:<path>` and `git -C <repo> grep <pattern> <ref>`
— **never check out branches**: these are Pedro's working trees, often mid-work. `git fetch` is fine.

**If Pedro gave a Jira key, discover the refs from it — don't ask for them.** All four repos
name work after the ticket: branches `ENG-3805-short-desc`, sub-branches `ENG-3770.1-…` or
`T2-466-4-…`, commits `ENG-3805: …` / `ENG-3805 - …`, merges `Merge branch 'ENG-3805-…'` /
`Merge pull request #N from healthium/ENG-3805-…`. GitHub repos are `healthium/<repo-dir>`.

1. **Expand the key set.** Fetch the ticket with the Atlassian MCP `getJiraIssue`
   (cloudId `be0a3a51-0216-4a52-857c-a642ed5f5cd2`): summary, description, **subtasks, parent and
   linked issues**. Work is often split by platform into subtasks with their own keys, so collect
   all of them. If the MCP isn't available, carry on with the key alone and say so.
2. **Search each repo** (fetch first; the regex stops `ENG-38` matching `ENG-3805`):
   ```bash
   KEYS='ENG-3805|ENG-3806'                                  # ticket + subtasks/parent
   RE="(^|[^A-Z0-9])($KEYS)([.-][0-9]+)?([^0-9]|$)"
   for r in nutrium nutrium-mobile-shared nutrium-ios nutrium-android; do
     echo "== $r"; git -C $r fetch --prune --quiet origin
     git -C $r for-each-ref --sort=-committerdate --format='%(refname:short)  %(committerdate:short)' refs/remotes refs/heads | grep -E "$RE"
     git -C $r log origin/dev --oneline -E --grep="$RE" | head -20
     gh pr list -R healthium/$r --state all --search "${KEYS//|/ OR }" --limit 30 \
       --json number,title,state,headRefName,baseRefName,mergedAt \
       | jq -c --arg re "$RE" '.[] | select((.title+" "+.headRefName) | test($re))
                              | [.number, .state, .headRefName, "→", .baseRefName, .mergedAt]'
   done
   ```
   Run it with `bash -c` (the expansion `${KEYS//|/ OR }` is bash). In Pedro's zsh, always brace
   variables before a colon — `"${REF}:path"`, never `$REF:path` (zsh reads `:s`, `:h`… as modifiers).
   Also add the **linked issues' subtasks** to `KEYS`: a backend ticket usually links one ticket per
   platform, and the branches are named after *their* subtasks (e.g. iOS `T2-493.4-…` under `T2-468`).
   Ignore local-only leftovers (`*-backup-*`, `*-wip`, branches older than the ticket's open PRs) and
   don't widen the search to the epic/parent: it pulls in sibling tickets. The `jq` filter matters: the
   `gh` search is fuzzy and returns neighbouring keys. Merged branches are usually deleted from the
   remote, so a merged feature shows up only in `git log` and in the `MERGED` PRs.
3. **Pick one analysis ref per repo:**
   - **Open PR(s)** → the branch tip. For stacked PRs (`baseRefName` is another feature branch),
     take the top of the stack: the head that no other open PR uses as base. Several independent
     open branches in one repo → list them all; each one's changed files are read at its own ref.
   - **Branch without a PR** → treat it like an open PR (work in progress, often the shared side
     that gets its PR later). If it's older than the ticket's other work or merged into nothing,
     mention it and ask whether it's still live.
   - **Merged only** → `origin/dev`. Also note whether it shipped: for `nutrium`,
     `git merge-base --is-ancestor <merge-sha> origin/master` tells you whether it's in production
     (`master` = deployed); for the mobile repos, `git branch -r --contains <merge-sha> | grep RELEASE`
     and `git tag --contains <merge-sha>` give the first release that includes it.
   - **Nothing found** → `origin/dev`: the existing contract the other repos' change must
     still match. A repo with no work for the ticket is itself worth a line — a backend change with
     no Android branch is either fine or the bug.
4. **Get the feature diff** per repo: `git -C <repo> diff --stat origin/dev...<ref>` (or the
   merged PRs' commits). These files are where step 2 starts. They aren't the whole surface,
   because the unchanged code they call is part of the contract too.
5. **Show the ref map and keep going.** Put it in a table: repo · keys found · branch/PR · state
   (open / merged / released in X) · analysis ref + SHA. Stop and ask only when it's genuinely
   ambiguous, e.g. two competing branches, or branch names that don't look like the same feature.

**Without a key** (feature name, endpoint, screen), ask once for a key or PR links. If there's
none, use `origin/dev` in all four repos (in `nutrium`, `dev` is the integration branch and
`master` is production; add `origin/master` when the question is "what's live now") and
locate the feature by grepping for its endpoint/model names. If you can't ask (running as a
subagent, or Pedro said "just go"), use the defaults and record them, with SHAs, under **Âmbito**.

Also record the **KMP version pinned** by each app at its analysis ref (see platform map). If
the shared-lib change for this feature isn't in the pinned release, that alone is a finding.

### 2 · Inventory the contract surface — one subagent per repo, in parallel

Dispatch four `general-purpose` subagents in a single message (not `Explore` — this needs
exact reading, not excerpts). Each gets: the repo path, the ref, the feature hints, that repo's
feature diff file list from step 1, the absolute path of `references/platform-map.md` with the section heading to read (point, don't
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

### 5 · Decide the fix for each problem

Pedro wants a recommendation, not a menu. For every confirmed or plausible problem, find where
it *could* be fixed (backend, shared, iOS, Android, several of them), then pick one using these
criteria in order:

1. **Does it protect the installed apps?** If old app versions are affected, only a backend
   change reaches them without an App Store / Play release and a wait for updates. Prefer a
   tolerant backend fix (keep emitting the old shape, accept both inputs, add instead of rename),
   plus the client fix for the future. A backend fix that changes what old apps receive is
   never the answer.
2. **One fix or two?** A bug in logic both apps run through the shared lib is fixed once in
   `nutrium-mobile-shared`. Fixing it separately in iOS and Android is two PRs that will drift.
   If the logic lives twice in the apps (legacy, or app-built `S*Model`s), say whether moving it
   into the shared lib is worth it now, or whether that's a follow-up.
3. **Release cost and lag.** The backend deploys continuously. A shared fix needs a shared
   release, the pin bumped in **both** apps (`ConfigData.kt`, `setup_nutrium_project.sh`) and an
   app release on each store. An app-only fix needs just one app release. When two options fix
   the problem equally well, the one that ships sooner wins.
4. **Fits the repo's existing pattern.** The fix should look like code already there. Cite the
   precedent (`file:line`) for how that repo already handles the same situation elsewhere, e.g.
   a mapper that already drops unknown values or a serializer that already uses `iso8601(3)`.
5. **Smallest change that removes the failure mode**, not just the symptom seen. Making one field
   nullable fixes one crash; if the real problem is that the DTO is stricter than the serializer
   across the board, say so. Don't propose the refactor unless the narrow fix leaves the bug
   class open in a way that will bite this feature again.

6. **iOS and Android end up behaving the same.** If the fix changes what users see (an error
   state instead of an empty form, a limit, a refresh), check that the other platform already
   behaves that way or gets the same change. Otherwise the fix creates a new 🟡 divergence.

Edge cases of the criteria:

- **No backend fix possible** (client-side state, caches, UI handling): say so explicitly, and
  say that installed versions stay exposed until they update. Pedro needs to weigh that.
- **Fix now + follow-up.** When the quick fix (one app, ships sooner) and the structural one
  (shared, fixes both) cover different parts of the problem, recommend both and label which is
  the fix and which is the follow-up. Follow-ups go in the Plano too, last, marked as such.
- **No precedent in the repo** for criterion 4: cite the closest analogous pattern and say the
  exact precedent doesn't exist, so the reviewer knows it's new ground.
- **Plausible findings**: say whether the fix should wait for confirmation. If it's cheap and
  harmless, recommend doing it anyway. If it's costly or risky, confirm first, and say how.

Write it down as: **recommendation** (repo, file, what changes, with a short code sketch when it
makes the change unambiguous) → **why**, in terms of the criteria → **rejected alternative(s)** in
one line each with the reason. If several fixes are needed together, give the **order** they must
ship in.

Recommend from the evidence: if you aren't sure the fix is safe (e.g. you can't see who else calls
that serializer), say what to check before doing it.

### 6 · Report

Write in **European Portuguese** (code identifiers stay as they are). Shape:

1. **Veredicto** — one or two sentences: do the contracts match, and what's the worst thing found.
2. **Âmbito** — the ref map from step 1 (keys, branch/PR, state, SHA per repo), KMP pins, which
   platforms use shared vs legacy for this feature. Short.
3. **Problemas** — ordered by severity, each with: what breaks, for whom (all users / iOS only /
   apps older than X / after next backend deploy), evidence on both sides, and **Solução
   recomendada**: the step-5 recommendation, why, and the rejected alternatives in one line.
   Severity scale:
   - 🔴 parte já ou parte no próximo deploy
   - 🟠 parte versões antigas da app em produção, ou só com dados específicos
   - 🟡 divergência iOS/Android ou fragilidade latente
4. **Plano de correção** — only if there are problems. The recommended fixes grouped **by repo**,
   in the order they must ship (backend tolerance → shared release → pin bumps → apps), each
   with the problem number(s) it closes. If a fix belongs in one of the ticket's open PRs from
   step 1, name that PR, because it's cheaper to fix there than in a new one. If step 1 found no
   open PRs (or wasn't run), say so in one line.
5. **Contratos verificados** — the matrix (condensed), so Pedro can see what *was* checked and
   matched, not just the failures. Absence of findings is only meaningful if coverage is visible.
   Checklist items that don't apply to the feature go in one line ("N/A: paginação, flags, v0/v1"),
   not a row each.
6. **Não verificado** — what couldn't be checked and why.

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
- **Analysing `dev` when the work is on a branch.** With a ticket key, the step-1 search is
  mandatory: a half-merged feature analysed at `dev` alone gives false "missing" findings.
- **Recommending the fix that's easiest to write instead of the one that reaches users.** A
  client-only fix for something that breaks installed versions leaves them broken until people
  update.
