# Platform map

Where each contract lives in each repo. All repos are siblings under
`/Users/pedroribeiro/Code/healthium/`. Paths drift — if one is gone, search for its
neighbours rather than concluding the mechanism no longer exists.

## nutrium (Rails 7.2 — the producer)

**Routes.** `config/routes.rb` draws per-API files. The mobile apps talk to
`config/routes/public_api.rb`: subdomain `api`, URL `/vN/...` (no `/api` prefix), `versionist`
`api_version(module: 'vN')`. **v2 is current**; v0/v1 are legacy but may still be hit by old
app versions. Auth: `devise_token_auth` at `auth/` (+ `auth/refresh`, `auth/google_sign_in`,
`sign_up`). Controllers: `app/controllers/api/public/{v0,v1,v2,accounts}`.
Other APIs (`private_api.rb` = web React, `general_api.rb` = partners, `open_api.rb`) are not
mobile contracts — ignore unless the feature crosses them.

**Serialization.** ActiveModelSerializers 0.10, `config/initializers/json_api.rb`:
`adapter = :json_api`, `key_transform = :unaltered` → keys **snake_case**, default envelope
`{data:{id,type,attributes,relationships}}`. Many v2 actions override with
`render json: x, adapter: :json, root: 'foo'` → `{foo: ...}`. **Read every `render` call**; the
envelope is per action. Serializers: `app/serializers/api/public/v2/**`, `app/serializers/public/{v0,v1}`,
and top-level `app/serializers/*_serializer.rb` (also used by v2). `serialization_scope :current_account`.
`attribute :x, key: :y` renames happen.

- `nil` is emitted as `null`, not omitted (unless a serializer uses `if:`/conditional attributes —
  then the key is *absent*, a different failure mode on the client).
- Times: `config.time_zone = 'UTC'`. Default `as_json` of a time is ISO8601 with 3-digit millis
  (`2026-10-19T10:00:00.000Z`). Serializers that call `.iso8601` without precision drop the
  millis; some call `&.utc&.iso8601(3)` explicitly. Dates render as `yyyy-MM-dd`.
- `BigDecimal` (decimal columns) renders as a **JSON string** (`"12.5"`) under Rails' default.
- Enums: custom classes in `app/models/enums/` (~200). Rendered as integer `*_id`
  (`scheduling_status_id`) or as `codename` strings. New values get added here without the apps knowing.

**Params & errors.** Strong params, snake_case: `params.require(:device).permit(...)`.
`app/controllers/api/base_controller.rb`: `RecordNotFound` → 404 `{}`, `ParameterMissing` → 400 `{}`.
Controllers that `head :bad_request` / `head :forbidden` return an **empty body** (not `{}`) — a
client that JSON-parses every error body fails differently on these.
**422 bodies are inconsistent across v2**: `{errors: ...}`, `{error: code}`, `{code: error_code}`,
`{data:{errors: model.errors.messages}}` — grep `unprocessable_entity` in the controller.

**Headers read.** `x-nutrium-device-id`, `x-nutrium-time-zone`, `x-nutrium-24h-format`,
`Accept-Language`, devise_token_auth `access-token`/`client`/`uid`; some endpoints check
`x-nutrium-api-key`.

**Pagination.** Kaminari `page`/`limit` (v2 default 100, max 500), `meta: {count, page, limit}` —
**`count` is total_pages**, not total records. Keyset variant: `before_created_at` + `limit`.

**Versioning of clients.** No min-version middleware, no forced update. App version only stored
per `Device` (`POST devices`, `app_version`). Back-compat shims are marked with comments like
"kept for backwards compatibility with older mobile app versions". `app_release_notes` takes
`platform` + `current_version`.

**Push.** FCM v1, `app/services/push_notification_service/provider/firebase.rb`. Payload classes:
`app/services/push_notification_service/notification/mobile/{,ios/,android/}*.rb`. Base shape
`{data:{data: <json string>, recipient: <json string>, title, body}}`; iOS adds `apns.payload.aps`
(e.g. `loc-key`). Legacy: `app/services/cloud_messaging_service.rb` — **still the live path for
mailboxer-style notifications** such as professional "likes" on patient logs: the envelope carries
`message_type_id` + `follow_up_activity_type_id` + `trackable_id` (built via
`app/serializers/activity_serializer.rb`, whose `meta` may be `null` per activity type). Android
receives these as `data["type"] == "mailboxer_messages"`, iOS through the legacy `userInfo["data"]`
branch. Find out which of the two paths the feature's push actually uses before checking keys.

**Flags.** `enabled_features` on the patient payload.

**Specs.** `spec/controllers/api/public/v2`, `spec/serializers/api/public/v2`. No schema files.

**Bruno.** `nutrium-api/v2/**` has working requests for the patient API — good for confirming a
"plausible" finding against a sandbox (`environments/`). Don't print env files: one holds a key.

## nutrium-mobile-shared (KMP — consumer of backend, producer for apps)

Root `shared/src/commonMain/kotlin/co/healthium/nutrium/mobile/shared/` (call it `P`).

- Features: `P/features/<feature>/{data,domain}`; entry point `P/features/SFeaturesFactory.kt`.
  Public types prefixed `S`; implementation in `internal/` packages.
- **No HTTP engine.** Apps inject `SHttpClientType` via `P/core/SharedKotlinDependencies.kt`, so
  headers/auth are app-owned. Base URL / version placeholders in `P/core/http/SNutriumHttpHelper.kt`.
  `requiresAuthentication` defaults `true` (`P/core/http/internal/HttpRequestBuilder.kt`).
- Endpoints: `features/*/…/network/*API.kt`. DTOs: `internal @Serializable` in
  `…/network/{request,response}/`, snake_case via `@SerialName` — a property without
  `@SerialName` uses the Kotlin name verbatim (fine for `proteins`, wrong for `createdAt`).
- **JSON config** (`P/core/serialization/internal/NutriumSerialization.kt`):
  `Json { ignoreUnknownKeys = true }`, everything else default → `explicitNulls = true`,
  `encodeDefaults = false`, `coerceInputValues = false`.
  - Decoding: a non-null property without default that comes as `null` or is absent fails the
    **whole response** → `SHttpError.InvalidJsonResponse`.
  - Encoding: properties equal to their default are **omitted** from request bodies; nullable
    properties *without* default are sent as explicit `null`.
- Enums are not serialized directly: DTOs carry `Int`/`String`, mappers call
  `fromId`/`fromCode`/`fromCodename`. Unknown value → per mapper: dropped (`mapNotNull`),
  fallback (`UNKNOWN`, `NEUTRAL`), or error. Check the specific mapper.
- Dates: `@Contextual SUtcDateTime` / `SUtcDate`. Outgoing datetime `yyyy-MM-ddTHH:mm:ss.000Z`
  (`P/core/datetime/internal/DateTimeToWebFormat.kt`). **Incoming parsing is per platform**:
  - iOS (`shared/src/iosMain/.../SDateTimeProvider.ios.kt`): `NSDateFormatter`
    `yyyy-MM-dd'T'HH:mm:ss.SSSXXX` — **millis are required**.
  - Android (`shared/src/androidMain/.../SDateTimeProvider.android.kt`):
    `LocalDateTime.parse(s, ISO_OFFSET_DATE_TIME)` — millis optional, and the offset is
    **discarded** (a `+01:00` value is read as if it were UTC).
- Errors: `P/core/http/SHttpError.kt` (sealed); `UnprocessableEntity(SHttpApiError(code, key, field, message))`.
  Per-feature sealed errors (`features/*/domain/S*Error.kt`) match on specific `code` strings from 422s.
  `SResult<S,F>` / `SEmptyResult<F>` in `P/core/utils/SResult.kt`.
- Some public `S*Model`s (patient, professional, appointment) are **built by the apps from their own
  parsing** — that contract lives twice, once per app.
- Swift export: **SKIE 0.10.10**, no config → sealed → `onEnum(of:)`, enums → Swift enums,
  suspend → `async throws`, `Flow` → `SkieSwiftFlow`, **default arguments not exported** (Swift
  must pass every parameter), nullable primitives → `KotlinInt?` etc.
- Persistence: Room KMP, `P/features/database/internal/SharedCommonFeaturesDb.kt`; migrations in
  `DbMigrations.kt`; schemas `shared/schemas/**`. An entity change without migration + schema crashes
  upgraded installs.
- Version: CalVer in `P/core/SNutriumKmpVersion.kt`. Releases are branches `RELEASE-YYYY.MM.N`, tags `vX`.
  **Old release branches get deleted**, and a version an app pinned may exist locally neither as
  branch nor tag: look at `git tag -l 'v*'` and, if the exact pinned version matters,
  `git fetch --tags origin` before declaring it missing.
- Tests: `commonTest/.../commonmainsharedtests/features/<f>/{tests,seeds,expectations}`; JSON
  fixtures are inline strings in `seeds/` — these are the closest thing to a recorded contract;
  compare them to the real serializer output.

## nutrium-ios

- KMP pin: `ci_scripts/setup_nutrium_project.sh` → `KMP_VERSION="RELEASE-…"`. XCFramework linked
  via Tuist (`Tuist/ProjectDescriptionHelpers/Project+Templates.swift`).
- Bridge: `Apps/Nutrium/Sources/Core/KotlinMultiplatform/` (`KMPHttpClient.swift`, `KMPHelper.swift`,
  `KMPFeatureError.swift`). `KMPHelper.translateResult` → `Result<_, KMPFeatureError<T>>`, and
  `fatalError` if an `SResult` has neither success nor failure. Rule (`Documentation/FeatureArchitectureGuide.md`):
  a `KmpFacadeWrapper` + `KmpMapper` per feature, `S*` types don't leak.
- Sealed classes are mostly consumed with `is` / `as?` casts (non-exhaustive); `onEnum(of:)` is rare.
  **A new Kotlin subtype compiles fine and falls into the generic branch.**
- Legacy: Alamofire + SwiftyJSON. Client `Apps/Nutrium/Sources/Core/Nutrium/Http/NutriumHttpClient.swift`;
  endpoints `Features/**/Domain/Network/*Network.swift`, `*NetworkEndpoint.swift`; DTOs
  `Features/**/Data/RestResponse/*Response.swift` with `init?(json: JSON)` — failable init: a missing
  required key can drop a whole item or response *silently*. `DeprecatedCode/Network/*+Network.swift` → CoreData.
  Dates: `DeprecatedCode/Formatters/DateParser.swift`.
- Headers: `x-nutrium-device-id`, auth from `AFNutriumAuthenticationRequestInterceptor.swift`;
  `X-Nutrium-Api-Key` **only** on unauthenticated KMP requests and a few endpoints (`KMPHttpClient.swift`).
- Push: `Core/Nutrium/Notification/NotificationsManager.swift`; handlers implement
  `SystemRemoteNotificationHandlerType`, registered in `Core/Nutrium/AppExternalDataHandler/AppExternalDataHandler.swift`;
  legacy `DeprecatedNutriumNotificationHandler.swift`.
- Deep links: `Features/Patient/Deeplink/GenericDeeplinkHandler.swift` (switch on `url.host`) + ~12
  `*DeepLinkHandler.swift`; params in `DeepLinkParams.swift`.
- Flags: `PatientSessionModel.EnabledFeature`.

## nutrium-android

- KMP pin: `buildSrc/src/main/kotlin/ConfigData.kt` → `kmpVersion`. Dependency coordinate is always
  `co.healthium.nutrium.mobile.shared:shared:1.0` from the gitignored `mavenLocal/`.
- DI: `app/src/main/java/co/healthium/nutrium/di/modules/KMPModule.kt`; HTTP bridge
  `config/kmp/data/remote/core/KmpHttpClient.kt`. Facades used directly; wrappers like
  `WaterIntakeManagerWrapper.kt` do `requireNotNull(result.getSuccess())`.
- Legacy: Retrofit2 + OkHttp + **Gson** (`di/modules/RetrofitModule.kt`), plus Retrofit 1.9
  (`Retrofit19Module.kt`). Services `…/<feature>/(data/)network/*Service.kt`; DTOs with
  `@SerializedName`. **Gson ignores Kotlin nullability**: a missing/null field lands as `null` in a
  non-null Kotlin property and NPEs later, far from the parse. Unknown enum string → `null`.
  Gson date formats: `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'` (Retrofit2 — literal `Z`, millis required) and
  `yyyy-MM-dd'T'HH:mm:ssz` (1.9). Prefix `/v2` from `config/Constants.kt`.
- Persistence: greenDAO (`daogenerator/`) + Room.
- Headers (`util/restclient/*Interceptor.kt`): `X-Nutrium-Api-Key` on **every** request, device id,
  time zone, 24h, `Accept-Language`, auth.
- Push: `firebase/service/FirebaseCloudMessagingService.kt` → `firebase/domain/HandleRemoteMessageDataUseCase.kt`,
  switch on `data["type"]`. Generic actions map `Uri.host` to `enums/PatientScreen.kt`.
- Deep links: manifest scheme `nutrium` + app links; hosts in `PatientScreen.kt`; widget paths and
  extras in `navigation/DeepLinks.kt` / `MainActivity.kt`. Feature modules also declare
  `<deepLink>`s in their navigation XML (`feature/*/src/main/res/navigation/nav_*.xml`) — but
  `MainActivity.extractWidgetDeepLink` only routes the hosts it knows and **drops the rest to the
  dashboard**, so a nav-XML deep link is not proof it works from a notification tap.
- Flags: `PatientEnabledFeature.kt`.

## Strings

Both apps get UI strings from Tolgee (not backend, not shared). A backend error `code` that the app
shows to the user needs a matching Tolgee key on **both** apps.
