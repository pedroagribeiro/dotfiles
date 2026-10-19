# Breakage checklist

Walk every item against the matrix. Each one names the question, then what makes it break at
Nutrium specifically. Skip an item only when the feature genuinely has nothing of that kind
(no enums, no push), and say so under "Contratos verificados".

## A · Backend → consumers (shared, iOS legacy, Android legacy)

1. **Envelope.** Does the client unwrap the envelope the action actually renders —
   `data.attributes.*` (json_api default) or `root_key.*` (`adapter: :json, root:`)? Includes
   `included` / `relationships` if the client reads associated records.
2. **Key names.** Every key the client reads exists in the serializer output, with that exact
   spelling — after `key:` renames. KMP properties without `@SerialName` use the camelCase Kotlin
   name and silently never match a snake_case key (they get the default, or fail if there is none).
3. **Nullability, field by field.** Can the backend emit `null`? (`&.`, optional `belongs_to`,
   nullable column, `return nil if`.) Then for each consumer:
   - KMP non-null without default → **whole response fails** (`InvalidJsonResponse`).
   - Gson → `null` inside a non-null Kotlin type → NPE wherever it's first used.
   - SwiftyJSON `init?(json:)` → item or response silently dropped, or a default value shown.
4. **Absent vs null.** Conditional attributes (`if:`) and `adapter: :json` with `except`
   make keys disappear. KMP treats absent like null-without-default unless there's a default.
5. **Types.** Integer vs float (`5` vs `5.0` is fine for KMP Double; `"5.0"` is not); `BigDecimal`
   rendered as a **string**; ids that could exceed `Int`; booleans that come as `0/1` or `"true"`;
   arrays that can be `null` instead of `[]`.
6. **Dates and times.** For every datetime field, the exact emitted format, then:
   - shared-on-iOS requires millis (`.SSSXXX`) → `.iso8601` without precision fails on iOS only;
   - shared-on-Android drops the offset → any non-`Z` offset is read as UTC on Android only;
   - Android Gson Retrofit2 expects literal `.SSS'Z'` → offsets or missing millis fail;
   - date-only vs datetime confusion, and "date" fields the backend computes in the patient's
     time zone (`x-nutrium-time-zone`) vs UTC.
7. **Enums / codes.** Full value set from `app/models/enums/<X>.rb` (or the codename list) vs the
   cases each client knows. For values the backend can emit that a client doesn't know: what does
   that client do (drop item, fallback, crash, `fatalError`)? Are iOS and Android doing the *same*
   thing? Values only recently added on the backend are the usual culprit.
8. **Pagination.** `meta.count` is total **pages**. Does the client loop until `page == count`,
   or treat `count` as records? Default `limit` 100 — does the client assume "everything in one page"?
9. **Errors.** For each non-2xx the action can produce: body shape (the 422 shapes vary per
   controller) vs what the client parses into `SHttpApiError(code, key, field, message)` or its own
   type; every error `code` string a client matches on (e.g. `appointment_ended`) must still be
   emitted, verbatim, by the backend. 400/404 bodies are `{}`.
10. **Auth & headers.** Does the endpoint require `x-nutrium-api-key` or auth? iOS only sends the API
    key on unauthenticated KMP calls; Android sends it always. Does the backend rely on
    `x-nutrium-time-zone` / `Accept-Language` that one app doesn't send on this path?
11. **Requests (client → backend).** Every param the controller `require`s / `permit`s vs what each
    client sends, with names and nesting. KMP omits properties equal to their default
    (`encodeDefaults = false`) — is that default *meaningful* to the backend (e.g. `false`, `0`)?
    Explicit `null` vs omitted: does the backend treat "key absent" as "don't change" and `null` as
    "clear"? Unpermitted params are dropped silently.

## B · Shared lib → apps

12. **Pinned version.** Is the shared change in the `RELEASE-…` each app pins? Do both apps pin the
    same version? If the feature needs a new shared release, is the app PR bumping it?
13. **Facade signatures.** New/changed parameters: Swift gets no default arguments (SKIE), so every
    iOS call site must pass them; Android call sites may silently take the default — is that default right?
14. **Sealed hierarchies & enums.** A new error/result subtype: iOS mostly uses `is`/`as?` casts —
    which branch does the new case fall into? Android `when` as a statement is also non-exhaustive.
    List the subtypes and how each app handles each one.
15. **Nullability across the bridge.** `KotlinInt?` boxing, `requireNotNull(getSuccess())` on Android,
    `fatalError` in `KMPHelper.translateResult` on iOS — can a path reach them?
16. **Models the apps build.** For `S*Model`s the apps construct from their own parsing (patient,
    professional, appointment), compare both apps' constructions: same source fields, same fallbacks?
17. **Room schema.** Entity change → migration in `DbMigrations.kt` + new schema JSON + version bump.
    Missing migration = crash on upgrade, only for existing installs.
18. **Platform-specific facades** (`*IosFacadeType`): feature parity with the common one.

## C · Side channels

19. **Push.** For each push type the backend sends for the feature: the `type` string is handled in
    Android's `HandleRemoteMessageDataUseCase` switch and in an iOS handler; the keys each reads
    (`data`, `recipient`, `payload`, `attributes.message_type_id`) exist in the payload; iOS `loc-key`
    exists in iOS strings. Types handled by one app only are divergences.
20. **Deep links.** Every link the backend generates for the feature (emails, push `link`, generic
    actions): host/path handled on both apps? (iOS `GenericDeeplinkHandler` and Android
    `PatientScreen` host sets already differ — check this feature's hosts specifically.)
21. **Feature flags.** `enabled_features` key spelled the same on backend, iOS `EnabledFeature`,
    Android `PatientEnabledFeature`; what each app does with an unknown key.
22. **Strings.** Error codes or `loc-key`s shown to users have Tolgee keys on both apps.

## D · Time — deployed versions

23. **Backward compatibility.** For every change on the backend side of this feature: which
    already-released app versions read or write this endpoint, and does the change break them?
    Removing / renaming / retyping a field, adding a `require`d param, changing an enum value,
    changing an error code, changing the envelope — all break old installs, and there is no forced
    update. Check the release branches/tags of the apps (and the shared release they pinned) when
    "which versions are affected" matters.
24. **Deploy order.** If the apps depend on a new backend field, the backend must ship first and the
    apps must tolerate its absence until it does (or the client must handle the old shape).
25. **v0/v1 callers.** Is any old endpoint version for this feature still called by an older app
    version? Changes to shared serializers (top-level `app/serializers/*`) leak into every version
    that uses them.

## E · Platform parity (no backend involved)

26. **Same behaviour.** Where the feature is legacy on one platform and shared on the other (or legacy
    on both), compare the logic that each app re-implements: validation, rounding, unit conversion,
    date bucketing (patient time zone vs device time zone), sorting, empty states. Differences here are
    🟡 divergences — report them, they become support tickets.
27. **Validation semantics.** Every limit the backend validates (`length: { maximum: }`, ranges,
    presence) vs the client-side guard on each app — and how each side *counts*: Ruby `String#length`
    counts codepoints, Swift `String.count` counts grapheme clusters (fewer, so emoji-heavy text passes
    iOS and gets a 422), Kotlin `length`/`take` counts UTF-16 units (more, so it errs safe).

## F · Client state and failure handling

The contracts can all match and the feature still corrupts data. These found the worst bugs in
practice.

28. **Cache staleness.** For every cache-first read (Room, CoreData, greenDAO, in-memory): who ever
    forces a refresh? A catalog fetched once "if the table is empty" never sees backend changes again
    on that install. Compare the platforms — one often refreshes on screen open and the other never does.
29. **Account scope.** What does logout / account switch clear, per platform and in the shared
    `clear*Data` actions? Anything the backend computes **per patient** (gender-dependent catalog,
    plan-dependent options, enabled features) that survives logout leaks to the next account on the
    same device.
30. **Failure rendered as empty.** When a GET fails, does the UI show an error, or an empty form /
    default state? Then: what does saving that form send? Combined with an upsert that reconciles
    away items not in the request, or a full-list PUT/PATCH, a transient network error becomes data
    loss or silently re-enables things the patient had turned off.
31. **Full list vs delta writes.** Does the client send the whole collection when only one item
    changed? If the backend accepts partial updates, prefer deltas; if the client's view of the
    collection can be stale or defaulted (item 30), the full list overwrites the server with it.
